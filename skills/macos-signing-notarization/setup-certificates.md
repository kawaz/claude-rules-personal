# 証明書取得と GitHub Secrets 投入

macOS の codesign / notarization に使う **6 種の GitHub Secrets** を投入する手順。

**AI がほぼ全部できる。** kawaz に回すのは、そのプロダクト用の App-Specific Password を
**新規発行する**ときだけ (発行後は 1Password 経由で AI が受け取る)。

## 取得元

| Secret | 取得元 |
|---|---|
| `APPLE_SIGNING_IDENTITY` | ローカル keychain の identity 名 |
| `APPLE_TEAM_ID` | identity 名の末尾 `(TEAMID)`、または証明書の `UID` / `OU` |
| `APPLE_CERTIFICATE_BASE64` | 一時 keychain 経由で p12 化 (Keychain のダイアログを kawaz が 1 回承認) |
| `APPLE_CERTIFICATE_PASSWORD` | ランダム生成してそのまま投入 |
| `APPLE_ID` | **1Password の「Apple Signing and Notarization」** |
| `APPLE_APP_SPECIFIC_PASSWORD` | 同上 (プロダクト別に発行。無ければ kawaz へ依頼) |

Homebrew tap へ配信するなら `HOMEBREW_TAP_DEPLOY_KEY` も要る。これも AI が全部できる
(`homebrew-tap-deploy-key` skill。承認を 1 回取ってから実行)。

### `APPLE_ID` の探し方 (間違えやすい)

- **iCloud のアカウントで代用しない。** `defaults read MobileMeAccounts` から取れるのは
  iCloud のもので、Developer Program に使っているアカウントとは**別**のことがある (実踏で誤投入)
- **証明書からは取れない。** Developer ID Application の subject は
  `UID=<TeamID>, CN=Developer ID Application: <組織名> (<TeamID>), OU=<TeamID>, O=<組織名>, C=US` で、
  メールアドレスは入っていない (`subjectAltName` にも無い。実測済み)。証明書が示すのは
  「配布元の組織」であって「notarize に使うアカウント」ではないため
- **正解は 1Password の「Apple Signing and Notarization」**。個人 Apple ID とは限らない

## AI が先に済ませる

`$REPO` を対象リポにすればそのまま実行できる。**値は一切表示しない**
(長さと件数だけ出して切り出しの成否を見る)。

### 1. 署名 identity と Team ID (ダイアログなし)

```bash
set -euo pipefail
REPO=kawaz/<product>

IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" \
  | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[0-9A-F]+[[:space:]]+"(.*)"$/\1/')
TEAM_ID=$(printf '%s' "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')
[ -n "$IDENTITY" ] && [ "$IDENTITY" != "$TEAM_ID" ] || { echo "identity の切り出しに失敗"; exit 1; }

printf '%s' "$IDENTITY" | gh secret set APPLE_SIGNING_IDENTITY --repo "$REPO"
printf '%s' "$TEAM_ID"  | gh secret set APPLE_TEAM_ID --repo "$REPO"
```

`security find-identity -v -p codesigning | grep -c "Developer ID Application"` が 0 なら
証明書自体が無い → 「Apple Developer Program 登録」へ。

### 2. 証明書 (Keychain のダイアログが 1 回出る)

```bash
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

#### `security export -t identities` の罠 (実踏 2026-06-12)

login keychain の **全 identity を一括で p12 に含める** (特定 identity だけ選ぶオプションが無い)。
Apple Development 等の無関係な秘密鍵を CI secret へ上げてしまうので、上のように
**一時 keychain へ取り込んでから不要な identity を削除**する。

削除は SHA-1 hash 指定 (`-Z`)。`-c "Apple Development"` (名前指定) は中間証明書等に
複数マッチして `ambiguous, matches more than one certificate` で失敗する。

> 余分な identity が混入した p12 でも codesign は `$APPLE_SIGNING_IDENTITY` 名指しで署名するため
> **動作はする**。問題は不要な秘密鍵の過剰共有。作り直して secret を上書きすれば次のリリースから反映。

### 3. Apple ID と App-Specific Password (1Password から)

```bash
op item get "Apple Signing and Notarization" --fields label=<APPLE_ID のフィールド> --reveal \
  | gh secret set APPLE_ID --repo "$REPO"
op item get "Apple Signing and Notarization" --fields label=<product 用のフィールド> --reveal \
  | gh secret set APPLE_APP_SPECIFIC_PASSWORD --repo "$REPO"
```

- `op whoami` が `account is not signed in` なら、まず kawaz にサインインを頼む
- **そのプロダクト用の App-Specific Password がまだ無ければ** 下記の依頼文を出す
- op が使えない状況で kawaz が手元にいるなら、クリップボード経由でも受け取れる。
  **形式検査だけして値は表示しない**:

```bash
V=$(pbpaste)
printf '%s' "$V" | grep -qE '^[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}$' \
  && printf '%s' "$V" | gh secret set APPLE_APP_SPECIFIC_PASSWORD --repo "$REPO" \
  || echo "App-Specific Password の形式ではありません"
```

### 4. 確認

```bash
gh secret list --repo "$REPO"    # 6 種が並ぶ
```

## kawaz へ出す依頼文 (このまま提示する)

App-Specific Password が未発行のときだけ必要。**ログイン先・名前・保存先・受け渡し方まで書く。**

```markdown
`APPLE_APP_SPECIFIC_PASSWORD` の発行をお願いします。他の Secrets は投入済みです。

- <https://appleid.apple.com> に <署名用の Apple ID> でログイン
  (1Password の「Apple Signing and Notarization」にあるアカウント)
- 「サインインとセキュリティ」→「App 用パスワード」に移動
- 「<product> Notarization」という名前で新規作成
- 1Password の「Apple Signing and Notarization」に保存
- op 経由で渡してもらえれば私が投入します。op が未サインインなら、
  コピーしてもらえれば pbpaste で受け取ります (値は表示しません)

投入後、失敗している run を再開します: `gh run rerun <id> --failed --repo kawaz/<product>`
```

## secrets はプロダクト別 (方針)

別プロダクトの secrets を使い回さない。漏洩時の rotate 単位と影響範囲がプロダクトに閉じる。

**rotate 単位の主対象は `APPLE_APP_SPECIFIC_PASSWORD`**。`APPLE_ID` / `APPLE_TEAM_ID` /
`APPLE_SIGNING_IDENTITY` は Team 共通値なので結果的に既存プロダクトと同じになるが、AI が
ローカルと 1Password から取り直すので値の受け渡しは発生しない。証明書 (p12) も既存の
Developer ID Application を流用するが、**p12 は毎回エクスポートし直す**。

## 証明書の種類

notarization には **Developer ID Application** が必須 ($99/年の Apple Developer Program)。
Apple Development (無料) では Gatekeeper の警告が残る。

### Apple Developer Program 登録 (初回のみ、kawaz の手作業)

1. Apple ID を作成 (<https://appleid.apple.com>)
2. Apple Developer Program に登録 ($99/年)。法人は D-U-N-S Number が必要
3. <https://developer.apple.com/account> → Certificates, Identifiers & Profiles で
   **Developer ID Application** 証明書を作成 (または Keychain Access から CSR 経由)

## ローテーション / 廃止

- App-Specific Password rotate: appleid.apple.com で旧パスワード無効化 → 依頼文を再提示
- 証明書入れ替え: 「AI が先に済ませる」の 2 を再実行して 2 種を上書き
- プロダクト廃止: `gh secret delete <NAME> --repo "$REPO"` を 6 種分。
  App-Specific Password は appleid.apple.com 側でも無効化する

## ローカル署名 (CI を待たず手元で試す)

```bash
codesign --force --sign "$IDENTITY" --timestamp --options runtime <binary>
codesign -dv --verbose=4 <binary>
spctl -a -vvv -t install <app>     # Gatekeeper 判定 (.app のみ)
```

## 関連

- `ci-release-pipeline.md` — 投入した secrets を消費する release.yml の署名ステップ
- `troubleshooting.md` — `Invalid credentials` (App-Specific Password 失効) 等の診断
- `homebrew-tap-deploy-key` skill — `HOMEBREW_TAP_DEPLOY_KEY` の生成と登録
