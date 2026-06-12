# notarize / 署名のトラブルシュート

CI の macOS ジョブ (`Notarize ...` / `Sign ...` ステップ) が失敗した時の診断。

## notarize 403 "agreement missing or has expired" → PLA 再同意

最頻出。`xcrun notarytool store-credentials` が `Validating your credentials...` 直後に:

```
Error: HTTP status code: 403. A required agreement is missing or has expired.
```

### 即断する判断根拠 (揃えば 99% これ)

1. **コード・CI スクリプト・Secrets を直前に変えていない**のに突然失敗
2. notarize ステップだけ失敗、ビルド・テストは成功
3. エラーに `agreement` の語が含まれる
4. 過去に同じ workflow でリリース成功実績がある

→ **Apple Developer Program License Agreement (PLA) の再同意が必要**。コード側は触らない。
Apple は規約改定のたびに再同意を要求し、**年に 1〜数回**発生する。`noreply@email.apple.com` から
通知が来る (迷惑メールに入りやすい)。

### 紛らわしい別系統エラー (切り分け表)

| エラー断片 | 真の原因 | 対処 |
|---|---|---|
| `A required agreement is missing or has expired` | **PLA 再同意 (本ケース)** | 下記の復旧手順 |
| `Invalid credentials` / `authentication failed` | App-Specific Password の失効・タイポ | `setup-certificates.md` 手順 1 で再発行・再投入 |
| `The team you specified is not active` | Team / Membership 状態 | Membership 課金状況を確認 |
| `Your account does not have permission` | Account Holder 以外で操作 | ロール確認 (Account Holder のみ可) |
| `invalid Apple ID or password` | Apple ID 自体の問題 | Apple ID パスワード再確認 |

### 復旧手順

1. <https://developer.apple.com/account> にサインイン
2. トップに **黄/赤の警告バナー**が出ているか確認 (出ていなければ別系統を疑う)
3. 「Agreements」セクションで未同意の規約に **Agree** (同意ボタンは **Account Holder ロール**のみに出る)
4. 失敗 run を再実行 (同意は通常 1 分以内に notarytool が認識):

```bash
run_id=$(gh run list --repo kawaz/<product> --workflow=release.yml --status=failure --limit 1 \
  --json databaseId -q '.[0].databaseId')
gh run rerun "$run_id" --failed --repo kawaz/<product>
```

> release trigger は `paths: [Cargo.toml]` 等の version file。**コミットを足さず**
> `gh run rerun --failed` で再発火させる (version を不必要に bump しない)。

## その他の既知エラー

| 症状 | 原因 | 対処 |
|---|---|---|
| codesign `errSecInternalComponent` | p12 に秘密鍵が含まれていない | `setup-certificates.md` 手順 2 で「証明書と秘密鍵の両方」を選び直して再エクスポート |
| `The signature does not include a secure timestamp` (notarize 側) | codesign に `--timestamp` 欠落 | 署名コマンドに `--timestamp` を追加 |
| notarize 後も Gatekeeper 警告 (`spctl` reject) | Hardened Runtime 未適用 | codesign に `--options runtime` を追加 |
| Homebrew Cask インストール後 .app が壊れる | Formula の tarball strip / 単一トップレベル | Cask 一本 + tar に bare binary 併置 (`tcc-app-bundle.md`) |
| `brew upgrade` で `formula requires at least a URL` | Formula + Cask 同名共存 | Formula を `rm -f` し Cask のみに (`tcc-app-bundle.md`) |

## 関連

- `setup-certificates.md` — secrets 再発行手順
- `ci-release-pipeline.md` — 署名/notarize ステップの正しい形
