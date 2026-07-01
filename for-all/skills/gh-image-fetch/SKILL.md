---
name: gh-image-fetch
description: GitHub の issue / PR / discussion / release / README **に貼られた画像を認証なし curl で取得する** (= 逆方向: [[gh-image-attach]] は投稿側)。`gh api` に `Accept: application/vnd.github.html+json` を付けて `body_html` を取得すると、`user-attachments/assets/<UUID>` は **5 分 TTL の JWT 署名付き一時 URL** に置換済みで返る → `curl -sL` で PNG バイナリ直取り可。README の外部 URL 画像は **`camo.githubusercontent.com` proxy** に化けて 1 年キャッシュで無認証取得可。**AI が GH 上の画像を context に取り込む / 保存する用途** (issue のスクショを Read するために一旦 DL、release notes の図を doc に埋め直す 等) 想定。`gh` CLI 認証済み前提、TTL が短い (= 5 分) ため取得したら即保存が必須。
---

# gh-image-fetch

GH 上の画像を、リソース種別に応じた **公式 API 経路** で URL 化 → 認証なし curl で
バイナリ取得するスキル。相手は 3 種:

| 種別 | 元 URL 例 | 取り出し先 | TTL |
|---|---|---|---|
| **user-attachments** (issue/PR/comment/release 本文の drop 画像) | `github.com/user-attachments/assets/<UUID>` | `body_html` の `<img src>` = `private-user-images.githubusercontent.com/.../file.png?jwt=...` | **5 分** |
| **README 内の外部 URL 画像** (shields.io / assets.vercel.com 等) | `<img src="https://外部...">` | readme API `Accept: application/vnd.github.html` の `<img src>` = `camo.githubusercontent.com/<hash>/<hex-encoded-url>` | 1 年キャッシュ |
| **README 内の相対パス画像** (`./docs/foo.png`) | `./docs/foo.png` | 相対のまま返る (readme API は解決してくれない)。**`raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>`** を手組みして取る | 恒久 (raw 経由) |

## 使う場面

- **issue / PR / release のスクショや図を Claude の Read で読む**ため一旦 DL
- 他のドキュメントに GH 上の画像を **再埋め込みしたい** (= HTML の JWT URL は 5 分で切れるので、DL して自 CDN / repo に置き直す)
- 業務コード / 個人 doc の meta として GH 側の画像を機械的に取り込む

前提:
- `gh` CLI が対象リポにアクセスできる (public なら unauthenticated / private なら token)
- **TTL 5 分** = API 呼び出しから curl まで **1 セッション内で完結** させる

## 手順 (public / private 共通)

### 経路 B: `body_html` 経由で JWT URL を取得 → 即 curl (推奨)

**すべての種別 (issue / issue-comment / PR / release) で成立**。`body_html` フィールド
は `Accept: application/vnd.github.html+json` を付けたときだけ返る。

```bash
# 1. body_html を取得
gh api "repos/OWNER/REPO/issues/comments/CID" \
    -H "Accept: application/vnd.github.html+json" \
    --jq '.body_html' \
  | grep -oE '<img [^>]*src="[^"]*"' \
  | sed 's/.*src="\([^"]*\)".*/\1/'

# 2. 得た URL を即 curl (認証不要、5 分以内に)
curl -sL "$TEMP_URL" -o out.png
file out.png  # PNG image data であることを確認
```

**endpoint 一覧** (すべて `-H "Accept: application/vnd.github.html+json"` + `--jq '.body_html'` で共通):

| 対象 | endpoint |
|---|---|
| issue 本体 | `repos/{owner}/{repo}/issues/{number}` |
| issue / PR comment | `repos/{owner}/{repo}/issues/comments/{comment_id}` |
| PR review comment (行番号付き) | `repos/{owner}/{repo}/pulls/comments/{comment_id}` |
| PR 本体 | `repos/{owner}/{repo}/pulls/{number}` |
| release | `repos/{owner}/{repo}/releases/{release_id}` (or `.../latest`) |
| discussion | GraphQL のみ (下記スコープ外) |

### 経路 R: README (経路 B と別、readme API)

README は専用 endpoint (`repos/{owner}/{repo}/readme`)。`Accept: application/vnd.github.html`
を付けると HTML 化された README がそのまま返る (= `body_html` フィールドではなく body そのもの)。

```bash
# README の <img src> 一覧
gh api "repos/OWNER/REPO/readme" \
    -H "Accept: application/vnd.github.html" \
  | grep -oE '<img [^>]*src="[^"]*"' \
  | sed 's/.*src="\([^"]*\)".*/\1/'
```

出てくる URL の種別:

1. **`camo.githubusercontent.com/<hash>/<hex-encoded-url>`** — 外部 URL 画像の proxy 化。
   認証なし curl で直取り、`max-age=31536000` (= 1 年)。**`data-canonical-src`** に元 URL が残っているので、
   `grep -oE '<img [^>]*data-canonical-src="[^"]*"'` で元 URL も同時に取れる
2. **`github.com/OWNER/REPO/actions/workflows/.../badge.svg`** — GH 自身の endpoint、proxy 不要でそのまま
3. **相対パス** (`./docs/foo.png` など) — README API では解決してくれない。
   `raw.githubusercontent.com/OWNER/REPO/{branch}/docs/foo.png` を手組みで取る (下記 経路 X)

### 経路 X: リポ内相対パス画像 → raw.githubusercontent.com

任意 `.md` 内の相対パス画像や、READMEの相対パス画像。以下のいずれかで取れる:

```bash
# デフォルトブランチ経由
gh api "repos/OWNER/REPO" --jq '.default_branch'  # → "main"
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/main/docs/foo.png" -o foo.png

# private repo なら raw も要認証
curl -sL -H "Authorization: Bearer $(gh auth token)" \
     "https://raw.githubusercontent.com/OWNER/REPO/main/docs/foo.png" -o foo.png

# または contents API (base64 で返る)
gh api "repos/OWNER/REPO/contents/docs/foo.png" --jq '.content' | base64 -d > foo.png
```

## private repo での挙動 (未検証、経路 B を推奨)

**public での実測は完了**。private repo は未検証だが以下の予測:

- **経路 B**: `gh api` は認証を勝手に付ける → `body_html` は返る。JWT URL は
  `?jwt=...` に private repo 判定を含めているはず、TTL 内なら **無認証 curl 可** (要検証)
- **経路 R (README)**: camo 化された外部 URL は認証なし取得できる**はず** (camo は
  proxy であって private repo 判定を持たない)。ただし README 自体を `gh api` するのに
  token 必要
- **経路 X (raw)**: private repo は **raw も認証必須**。`Authorization: Bearer <gh token>`
  を付けるか `gh api contents` で base64 decode

private の実挙動は kawaz 業務環境等で確認して findings に追記する。

## AI 実行時の注意 (= セッション内完結)

- API 呼び出しから curl まで **1 セッション内で完結**させる (TTL 5 分)
- 大量画像を扱う場合は **一時 URL のリストを控えず、1 枚ずつ即 DL**
- 期限切れは HTTP 200 の代わりに **403 XML** が返る (S3 pre-signed URL の失効挙動)。
  失効を観測したら `body_html` の再取得からやり直す (URL が変わる)
- `body` (Markdown) と `body_html` (HTML) は同時に取れる (`--jq '.body,.body_html'`)
  → 画像の意味付け (前後文脈) が必要なら両方取ると効率的

## AI 実行時のよくある勘違い

- **`Accept: application/vnd.github.html+json` を付けても `body` は消えない** (両方返る)
- **`user-attachments/assets/<UUID>` を無認証 curl しても** 302 で S3 一時 URL に飛ばされて DL 成功する
  (= public repo なら)。ただし **302 の Location URL も 5 分 TTL** (= `X-Amz-Expires=300`)、
  スライドが言う「ログイン画面が返る」は private repo での挙動と推察
- **camo URL** は `<hex-encoded-url>` を hex decode すれば元 URL に戻る:
  `printf $(echo <hex> | sed 's/../\\x&/g')` (bash) / `bytes.fromhex()` (python)

## スコープ外

- **discussion** (GraphQL 専用)、**wiki** (別サブドメイン `github.com/OWNER/REPO/wiki`、
  Web scraping 要)、**gist** (別ドメイン)、**動画 / PDF** (= `<video>` / `<embed>` の
  src 置換は要調査)
- **README の相対パス を自動的に raw に展開する CLI** (= 手組みで済むため作らない)
- **camo URL の元 URL を hex decode するツール** (= sed / python で 1 行で済む)

## 関連スキル / ルール

- **反対方向**: [[gh-image-attach]] (画像を GH に投稿するスキル、playwright 経由)
- **横串**: [[claude-config-dir-isolation]] 越境作業時は対象環境の `gh` 認証を使う
- **業務 private 検証時**: 業務 overlay の `gh` 認証境界 (= [[account-isolation]] emeradaco)
- **findings**: `docs/findings/2026-07-01-gh-user-attachments-fetch.md` (本スキルの根拠、
  実測データ含む)

## 一次資料

- [GitHub REST API: Media types](https://docs.github.com/en/rest/overview/media-types) —
  `application/vnd.github.html+json` の公式定義
- [GitHub Docs: Camo image proxy](https://github.com/atmos/camo) — camo の仕組み
- スライド出典: シナマケミートアップ #14 「僕の考えた最強の AI 駆動開発フロー」
  コラム「Issue の画像を gh だけで取り出す」(2026-06 頃)
