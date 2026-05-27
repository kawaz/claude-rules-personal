# 外部 skill の手動セットアップ手順

`setup.sh` は overlay リポ内の自作 skill (`for-*/skills/<slug>/`) を
`$CLAUDE_CONFIG_DIR/skills/<repo>-<slug>` に symlink 配置する。

一方、**ベンダー製ツールが同梱する skill** は setup.sh の対象外とする
(理由: `docs/issue/2026-05-14-setup-sh-skills-support.md` の方針 4 —
外部 skill を setup.sh にハードコードするとデータ駆動が崩れるため)。

ここでは外部 skill を `$CLAUDE_CONFIG_DIR/skills/` に手動配置する手順を記録する。
各手順は **使いたい CLAUDE_CONFIG_DIR ごとに 1 回ずつ** 実行する。

## playwright-cli

`@playwright/cli` パッケージは `skills/playwright-cli/` を同梱している
(`playwright-cli install --skills` が撒くのと同一物)。
コピーすると陳腐化するため **symlink** で配置する:

```bash
mkdir -p "$CLAUDE_CONFIG_DIR/skills"

# @playwright/cli パッケージのディレクトリを導出 (パスのハードコードを避ける)
pkg_dir=$(dirname "$(readlink -f "$(command -v playwright-cli)")")

# $CLAUDE_CONFIG_DIR/skills/playwright-cli に symlink
ln -sfn "$pkg_dir/skills/playwright-cli" "$CLAUDE_CONFIG_DIR/skills/playwright-cli"
```

ポイント:

- **symlink なので `@playwright/cli` をパッケージ更新すれば skill も自動追従** する
- `@playwright/cli` をアンインストールすると symlink は dangling になるが、
  setup.sh の dangling 掃除 (`prune_dangling`) が次回実行時に `$CLAUDE_CONFIG_DIR/skills/`
  直下から除去する
- skill 名は `playwright-cli` (prefix なし)。自作 skill の `<repo>-<slug>` 命名とは
  別系統 = ベンダー skill であることが名前から分かる
- `readlink -f` が動かない環境では `greadlink -f` (coreutils) を使う

## 補足: 外部 skill が増えてきたら

外部 skill が複数になったら、setup.sh をデータ駆動 (`external-skills.json` 等) で
拡張することを検討する。現状は数が少ないため本 runbook の手動手順で足りる。
詳細は `docs/issue/2026-05-14-setup-sh-skills-support.md` の方針 4 を参照。
