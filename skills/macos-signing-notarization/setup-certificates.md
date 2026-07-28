# 証明書取得と GitHub Secrets 投入

macOS の codesign / notarization に使う **6 種の GitHub Secrets** を投入する手順。

**6 種のうち 4 種は AI が CLI で投入できる。** kawaz の手作業が要るのは
`APPLE_ID` と `APPLE_APP_SPECIFIC_PASSWORD` の 2 つだけ。AI はまず下記
「AI が先に済ませる」を実行し、残り 2 つを「kawaz へ出す依頼文」の形で提示する。

## 実行者の分担

| Secret | 実行者 | 取得方法 |
|---|---|---|
| `APPLE_SIGNING_IDENTITY` | **AI** | ローカル keychain の identity 名 |
| `APPLE_TEAM_ID` | **AI** | identity 名の末尾 `(TEAMID)` から抽出 |
| `APPLE_CERTIFICATE_BASE64` | **AI** | 一時 keychain 経由で p12 化 (Keychain のダイアログを kawaz が 1 回承認) |
| `APPLE_CERTIFICATE_PASSWORD` | **AI** | ランダム生成してそのまま投入 |
| `APPLE_ID` | kawaz | Apple ID のメールアドレス。AI は推測しない |
| `APPLE_APP_SPECIFIC_PASSWORD` | kawaz | appleid.apple.com で**プロダクト別に新規発行** |

Homebrew tap へ配信するなら `HOMEBREW_TAP_DEPLOY_KEY` も要る。**これは AI が全部できる**
(`homebrew-tap-deploy-key` skill に手順がある。承認を 1 回取ってから実行)。

## AI が先に済ませる

`$REPO` を対象リポにすればそのまま実行できる。**値は一切表示しない**
(長さと件数だけ出して切り出しの成否を見る)。

```bash
set -euo pipefail
REPO=kawaz/<product>

# 1. 署名 identity と Team ID (ダイアログなし)
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" \
  | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[0-9A-F]+[[:space:]]+"(.*)"$/\1/')
TEAM_ID=$(printf '%s' "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')
[ -n "$IDENTITY" ] && [ "$IDENTITY" != "$TEAM_ID" ] || { echo "identity の切り出しに失敗"; exit 1; }

printf '%s' "$IDENTITY" | gh secret set APPLE_SIGNING_IDENTITY --repo "$REPO"
printf '%s' "$TEAM_ID"  | gh secret set APPLE_TEAM_ID --repo "$REPO"

# 2. 証明書 (Keychain のダイアログが 1 回出る。kawaz が承認する)
T=$(mktemp -d); KC="$T/tmp.keychain-db"
trap 'security delete-keychain "$KC" 2>/dev/null || true; rm -rf "$T"' EXIT
P1=$(openssl rand -base64 24); P2=$(openssl rand -base64 24); KCPASS=$(openssl rand -base64 24)

security export -k login.keychain-db -t identities -f pkcs12 -P "$P1" -o "$T/all.p12"
security create-keychain -p "$KCPASS" "$KC"
security import "$T/all.p12" -k "$KC" -P "$P1" -A >/dev/null

# Developer ID Application 以外を落とす (下記「罠」参照)
security find-identity -v "$KC" | grep -E '^\s+[0-9]+\)' | grep -v "Developer ID Application" \
  | awk '{print $2}' | while read -r h; do security delete-identity -Z "$h" "$KC" >/dev/null 2>&1 || true; done
echo "残った identity: $(security find-identity -v "$KC" | grep -cE '^\s+[0-9]+\)') 件"   # 1 になるはず

security export -k "$KC" -t identities -f pkcs12 -P "$P2" -o "$T/devid.p12"
base64 -i "$T/devid.p12" | gh secret set APPLE_CERTIFICATE_BASE64 --repo "$REPO"
printf '%s' "$P2"        | gh secret set APPLE_CERTIFICATE_PASSWORD --repo "$REPO"
```

実行後 `gh secret list --repo "$REPO"` で 4 種が並ぶことを確認する。

### `security export -t identities` の罠 (実踏 2026-06-12)

login keychain の **全 identity を一括で p12 に含める** (特定 identity だけ選ぶオプションが無い)。
Apple Development 等の無関係な秘密鍵を CI secret へ上げてしまうので、上のスクリプトのように
**一時 keychain へ取り込んでから不要な identity を削除**する。

削除は SHA-1 hash 指定 (`-Z`) で行う。`-c "Apple Development"` (名前指定) は中間証明書等に
複数マッチして `ambiguous, matches more than one certificate` で失敗する。

> 余分な identity が混入した p12 でも codesign は `$APPLE_SIGNING_IDENTITY` 名指しで署名するため
> **動作はする**。問題は不要な秘密鍵の過剰共有。気づいたら作り直して secret を上書きすれば
> 次のリリースから反映される (ローテーションの要否は漏洩疑いの有無で判断)。

## kawaz へ出す依頼文 (このまま提示する)

上を済ませたら残りはこれだけになる。**手順ごと箇条書きで出す** — kawaz が別途調べなくて済む形にする。

```markdown
残り 2 つの Secret の投入をお願いします。他の 4 つ (+ tap の deploy key) は投入済みです。

1. **`APPLE_APP_SPECIFIC_PASSWORD`** — appleid.apple.com で新規発行してください
   (方針: プロダクト別に発行して rotate 単位を分ける)
   - サインイン → 「サインインとセキュリティ」→「App 用パスワード」→「App 用パスワードを生成」
   - ラベル: `<product> notarytool`
   - 表示された `xxxx-xxxx-xxxx-xxxx` を控える (閉じると再表示不可)
   - `gh secret set APPLE_APP_SPECIFIC_PASSWORD --repo kawaz/<product>` に貼る

2. **`APPLE_ID`** — Apple ID のメールアドレス
   - `gh secret set APPLE_ID --repo kawaz/<product>`

投入後、失敗している run を再開してください:
`gh run rerun <id> --failed --repo kawaz/<product>`
```

## 証明書の種類 (前提)

| 種類 | 費用 | Gatekeeper | 用途 |
|---|---|---|---|
| Apple Development | 無料 | 警告が出る | 個人・テスト用 |
| **Developer ID Application** | $99/年 (Apple Developer Program) | 警告なし | **配布用 (これを使う)** |

notarization には **Developer ID Application** が必須。Apple Development では warning が残る。

`security find-identity -v -p codesigning | grep -c "Developer ID Application"` が 0 なら
証明書自体が無い。その場合は下記の初回セットアップから。

### Apple Developer Program 登録 (初回のみ、kawaz の手作業)

1. Apple ID を作成 (<https://appleid.apple.com>。Apple デバイス不要)
2. Apple Developer Program に登録 ($99/年)。法人は D-U-N-S Number が必要
3. <https://developer.apple.com/account> → Certificates, Identifiers & Profiles で
   **Developer ID Application** 証明書を作成 (またはローカルの Keychain Access から CSR 経由で発行)

## secrets はプロダクト別 (方針)

別プロダクトの secrets を使い回さず、新プロダクト用に発行する。漏洩時の rotate 単位と
影響範囲がプロダクトに閉じる。

**rotate 単位の主対象は `APPLE_APP_SPECIFIC_PASSWORD`**。`APPLE_ID` / `APPLE_TEAM_ID` /
`APPLE_SIGNING_IDENTITY` は Team 共通値なので結果的に既存プロダクトと同じ値になるが、
AI がローカルから取り直すので値の受け渡しは発生しない。証明書 (p12) も既存の
Developer ID Application を流用するが、**p12 は毎回エクスポートし直す**。

## ローテーション / 廃止

- App-Specific Password rotate: appleid.apple.com で旧パスワード無効化 → 依頼文の 1 を再実行
- 証明書入れ替え: 「AI が先に済ませる」の 2 を再実行して 2 種を上書き
- プロダクト廃止: `gh secret delete <NAME> --repo "$REPO"` を 6 種分。
  App-Specific Password は appleid.apple.com 側でも無効化する

## ローカル署名 (CI を待たず手元で試す)

```bash
codesign --force --sign "Developer ID Application: 名前 (TEAMID)" --timestamp --options runtime <binary>
codesign -dv --verbose=4 <binary-or-app>
spctl -a -vvv -t install <app>     # Gatekeeper 判定
```

## 関連

- `ci-release-pipeline.md` — 投入した secrets を消費する release.yml の署名ステップ
- `troubleshooting.md` — `Invalid credentials` (App-Specific Password 失効) 等の診断
- `homebrew-tap-deploy-key` skill — `HOMEBREW_TAP_DEPLOY_KEY` の生成と登録 (AI が全部できる)
