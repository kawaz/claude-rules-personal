---
name: homebrew-tap-deploy-key
description: kawaz/<project> から kawaz/homebrew-tap への自動 push を有効にする deploy key セットアップ時に読む。release.yml が `secrets.HOMEBREW_TAP_DEPLOY_KEY` を参照するが未設定な時、Action ログの `Permission to kawaz/homebrew-tap.git denied` エラー対処時、初回リリース前準備で使う。
---

# Homebrew Tap Deploy Key

kawaz/<project> から kawaz/homebrew-tap への自動 push を有効にするための
deploy key 運用手順。

## 適用ケース

- 新規 kawaz リポの `release.yml` が `secrets.HOMEBREW_TAP_DEPLOY_KEY` を
  参照しているが secret 未設定
- Action 失敗ログに `Permission to kawaz/homebrew-tap.git denied to github-actions[bot]` が出ている
- 初回リリース前の事前準備として deploy key 不在を検知した

## 運用方針

- **FROM リポごとに独立した使い捨て deploy key を生成** (1 鍵 = 1 FROM リポ)
  - 漏洩時の影響範囲を最小化、tap 側で `<project> release` タイトルで一覧化されローテ単位が明確
  - 共通鍵使い回しは GitHub の「同一公開鍵は別リポの deploy key として再登録不可」制約で技術的に不成立
- 鍵は `~/.ssh` 等に残さず、生成 → 登録 → 破棄を 1 セッション内で完結 (mktemp + trap)
- タイトルは `<project> release` で統一 (既存 kawaz/homebrew-tap の他プロジェクトと揃える)

## 実行前の承認

作業前に **kawaz に 1 回だけ Yes/No を本文の箇条書きで確認**する (自由回答歓迎)。
承認後は手順を中断せず実行。確認文例: 「kawaz/<project> 用の HOMEBREW_TAP_DEPLOY_KEY
セットアップ (鍵生成 → secret 登録 → tap の deploy key 登録 → 失敗 run の rerun) を
進めて良いですか？」

## 手順

```bash
PROJECT=<project-name>  # 例: bump-semver
TMPKEY=$(mktemp -d)
trap 'rm -rf "$TMPKEY"' EXIT

# 1. ed25519 鍵ペアを一時ディレクトリに生成
ssh-keygen -t ed25519 -N '' \
  -C "kawaz/$PROJECT -> kawaz/homebrew-tap deploy key" \
  -f "$TMPKEY/key"

# 2. 秘密鍵を FROM リポの secret に登録
gh secret set HOMEBREW_TAP_DEPLOY_KEY \
  --repo "kawaz/$PROJECT" \
  < "$TMPKEY/key"

# 3. 公開鍵を kawaz/homebrew-tap の deploy key に write 権限付きで登録
gh repo deploy-key add "$TMPKEY/key.pub" \
  --repo kawaz/homebrew-tap \
  --title "$PROJECT release" \
  --allow-write
# trap で TMPKEY 自動削除
```

## 完了後の検証

直近の失敗 release.yml を rerun:

```bash
failed_run=$(gh run list --repo "kawaz/$PROJECT" \
  --workflow=release.yml --status=failure --limit 1 \
  --json databaseId -q '.[0].databaseId')
gh run rerun "$failed_run" --repo "kawaz/$PROJECT" --failed
gh run watch "$failed_run" --repo "kawaz/$PROJECT"
```

Formula 反映確認:

```bash
brew install kawaz/tap/$PROJECT && $PROJECT --version
```

## dotfiles 側の brew formula list 登録 (= darwin-rebuild 由来の uninstall 対策)

kawaz の macOS 環境は **nix-darwin** で brew formula を declarative 管理している。
`dotfiles/darwin/default.nix` の `brews = [...]` リストに登録されてない formula は
**`darwin-rebuild switch` のたびに自動 uninstall される**。

= 新 kawaz リポを brew で配布開始した時、**dotfiles に登録しないと自分の環境からも消える**。

### 手順 (= 配布開始した kawaz リポを自環境に永続 install したい時に必須)

1. `~/.dotfiles/darwin/default.nix` を開く
2. `brews = [` 内の **適切なグループ** (= "kawaz utilities" / "System tools" 等、既存の並びに合わせる) に
   `"kawaz/tap/<project>"` を 1 行追加
3. dotfiles をいつもの手順で commit + push + `darwin-rebuild switch` 適用
4. apply 後 `brew list | grep <project>` で永続化を確認

### 既存例

`dotfiles/darwin/default.nix` 内の `brews = [...]` には既に
`kawaz/tap/authsock-filter / authsock-warden / bump-semver / hyoui / jj-worktree / stable-which`
が登録されている。新規追加もこれらの並びに合わせる。

### 追加忘れの徴候

- `brew install kawaz/tap/<project>` を手で打って入れた後、しばらくして `command not found: <project>` になる
  = `darwin-rebuild switch` が走って uninstall された
- `just on-success-release` の `brew upgrade` が `Error: kawaz/tap/<project> not installed` で失敗
  = 同上

これらが起きたら dotfiles 登録忘れを疑う。

## ローテーション / 廃止

基本不要。鍵漏洩懸念または FROM リポ廃止時のみ:

```bash
# tap 側: title 一覧から id を引く
gh repo deploy-key list --repo kawaz/homebrew-tap
gh repo deploy-key delete <id> --repo kawaz/homebrew-tap

# FROM リポ側
gh secret delete HOMEBREW_TAP_DEPLOY_KEY --repo "kawaz/$PROJECT"
```
