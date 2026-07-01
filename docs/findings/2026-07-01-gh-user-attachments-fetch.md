# GitHub `user-attachments` 画像を認証なしで取得する手法

## 判明した事実

GitHub の issue / PR / discussion / release の body・comment に貼られた
`https://github.com/user-attachments/assets/<UUID>` 形式の画像は、以下の
2 経路で **認証なし curl で画像バイナリを取得可能**。

### 経路 A: オリジナル URL の 302 redirect (単純だが不完全)

`user-attachments/assets/<UUID>` を無認証 curl → **302** で S3 一時 URL に飛ばされる
(`X-Amz-Expires=300` = 5 分 TTL)。`curl -sL` で追跡すれば実画像 (PNG) が落ちる。

制限:
- **UUID を事前に知っている必要がある** (元の Markdown 本文にしか出ない)
- 302 挙動は変わる可能性あり (= public だから通っている? private issue の実測は未検証)

### 経路 B: `body_html` 経由で JWT 署名済み一時 URL を取得 (推奨)

GH REST API に `Accept: application/vnd.github.html+json` を付けて GET すると、
`body` (Markdown) の代わりに `body_html` フィールドが返る (`body` と併存)。
`body_html` の中の `<img src>` は **`private-user-images.githubusercontent.com/.../file.png?jwt=...`
の JWT 署名付き一時 URL に置換済み**。この URL を無認証 curl → 直で PNG バイナリ。

JWT payload 実測 (`nbf` / `exp` の差):
```
{"iss":"github.com","aud":"raw.githubusercontent.com",...,"nbf":..., "exp": ...}
```
`exp - nbf = 300` (= **5 分**)。スライド「約 5 分で失効」と一致。

**メリット**:
- Markdown 本文を持たなくても API 呼び出しだけで完結 (UUID 不要)
- `<img>` タグの alt / width / height も同時に取れる (= 画像の意味付けもわかる)
- private repo の画像でも API 認証 (= GH token) さえあれば `body_html` 経由で一時 URL 化可能 (要検証)

### 経路 C: 画像画像直叩き (経路 A の別形式)

`private-user-images.githubusercontent.com/<user>/<numeric>-<UUID>.png?jwt=...` 形式は
既に一時 URL 済み、TTL 内なら無認証 DL 可。Web ブラウザで見たときの `<img src>` を
そのまま curl するとこれになる。**302 経由でなく直接 200 で PNG が返る** (差異)。

## 実用的な示唆 / ベストプラクティス

- 画像を AI コンテキストに取り込むなら **経路 B** を使う (Markdown 本文の parsing 不要、
  署名済み URL を直取得できる)
- TTL 5 分 = 取得したら **即 curl して保存** する。他ステップを挟むと exp 切れで失効
- 画像判別・重複対策: `body_html` の `<img>` は `alt=""` が空だったり `alt="Image"`
  だったりする。**判別は元の Markdown (`body`) の周辺文脈と突き合わせる**方が確実
- 保存パスは alt / width / body_html 内の順序で連番化する程度で十分 (原ファイル名は失われる)

## 対 GH スライド (シナマケミートアップ #14 コラム) 主張との整合

スライドは「画像 URL を直 curl するとログイン画面が返る」と主張。
実測: `github.com/user-attachments/assets/<UUID>` は **公開 issue なら 302 経由で
無認証 DL 可能** (= スライド主張と部分的に食い違う)。

考察:
- **private repo なら実際にログイン画面 (302 でなく HTML) が返る可能性**が高い
  (kawaz 環境で public しか実測できず、private の再現は保留)
- スライドは「安全側」で経路 B (`body_html`) を推奨している = 汎用性で見れば妥当
- **AI が汎用手法として実装するなら経路 B** に倒すべき (public / private を問わず動く保証)

## 検証の詳細

### テスト対象

- comment: `https://github.com/kawaz/LaserGuide/issues/3` の comment id `3430506759`
  (画像 2 枚含む public issue)
- issue body: `kawaz/LaserGuide/issues/3` (画像なしだが `body_html` フィールドの存在確認)
- release: `kawaz/bump-semver/releases/latest`
- pull: `kawaz/claude-gh-monitor/pulls/1`

### 実測: URL 形式ごとの curl 挙動

| URL 形式 | curl 無認証 status | 実 body | 備考 |
|---|---|---|---|
| `github.com/user-attachments/assets/<UUID>` | 302 → S3 | PNG (経由後) | S3 一時 URL に redirect、`X-Amz-Expires=300` |
| `github.com/user-attachments/assets/<UUID>` + `Authorization: Bearer <gh token>` | 302 → S3 | PNG (経由後) | token 有無で挙動同じ、302 は変わらない |
| `private-user-images.githubusercontent.com/.../file.png?jwt=...` (body_html 由来) | 200 | PNG 直 | 一時 URL 済み、`content-type: image/png` |

### 実測: `Accept: application/vnd.github.html+json` 付き API 応答フィールド

| API endpoint | `body_html` フィールド |
|---|---|
| `repos/{o}/{r}/issues/{n}` | あり |
| `repos/{o}/{r}/issues/comments/{cid}` | あり |
| `repos/{o}/{r}/pulls/{n}` | あり |
| `repos/{o}/{r}/releases/latest` | あり |

全経路で 1 発の `gh api` 呼び出しで `<img src="署名済み一時 URL">` の列を取得可能。

### コマンドサンプル (実測動作)

```bash
# comment から画像 URL 一覧を取り出す
gh api "repos/OWNER/REPO/issues/comments/CID" \
    -H "Accept: application/vnd.github.html+json" \
    --jq '.body_html' \
  | grep -oE '<img [^>]*src="[^"]*"' \
  | sed 's/.*src="\([^"]*\)".*/\1/'

# 得た URL を即 curl (認証不要、5 分以内に)
curl -sL "$TEMP_URL" -o out.png
file out.png  # PNG image data であることを確認
```

### JWT payload 実測 (5 分 TTL の裏取り)

```json
{
  "iss": "github.com",
  "aud": "raw.githubusercontent.com",
  "key": "key5",
  "exp": 1782882946,
  "nbf": 1782882646,   // exp - nbf = 300 秒
  "path": "/156236/504005717-.../file.png?...X-Amz-Expires=300&..."
}
```

内側の S3 pre-signed URL も `X-Amz-Expires=300`。**2 段どちらも 5 分** で失効。

## 未検証事項 (= 将来ここを詰めるべき)

- **private repo** で経路 A (`user-attachments/assets/<UUID>` 直叩き) が本当に「ログイン画面
  HTML」を返すか。実測環境が用意できていない (= kawaz は kawaz123 業務環境で確認可能)
- **discussion**: `graphql` 経由でしか取れないが、`body_html` 相当のフィールドが取れるか
- **私設 GH Enterprise Server**: 挙動は同一か
- **画像以外 (動画 .mp4, PDF)**: 同じ `user-attachments` の別形式で、経路 B は img 以外を
  どう返すか (= `<video>` src が同じく JWT URL 化されるはず)
