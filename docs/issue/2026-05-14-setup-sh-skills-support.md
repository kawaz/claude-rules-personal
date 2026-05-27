# setup.sh で skills/ も配置できるように拡張する

## 背景

`setup.sh` は現状 `for-all/rules/`, `for-me/rules/`, `for-others/rules/` のみを
`$TARGET/rules/` 配下にディレクトリ symlink で配置する。

各オーバーレイで skill を `for-*/skills/<slug>/SKILL.md` に置きたいケースが出てきたが、
setup.sh はこれを認識しないため手動配置が必要。

## 調査結果 (2026-05-21)

Claude Code の探索仕様を確認:

- **skills は直置きのみ、サブディレクトリ再帰は非対応** (`$CONFIG_DIR/skills/<name>/SKILL.md`)
- plugin 内 skills も同様に flat
- → rules のような中間ディレクトリ symlink (`skills/for-all-from-<name>/`) は **検出されない**
- commands (`$CONFIG_DIR/commands/*.md`) は現役で動作し、skill 一覧にも統合表示される

## 確定した対応方針

### 1. skills はフラット prefix symlink で配置

中間ディレクトリが使えないため、skill ディレクトリを個別に symlink し、
名前に出自リポ prefix を付ける:

```
<repo>/for-all/skills/<slug>    → $TARGET/skills/<repo>-<slug>   (全環境)
<repo>/for-me/skills/<slug>     → $TARGET/skills/<repo>-<slug>   (self のみ)
<repo>/for-others/skills/<slug> → $TARGET/skills/<repo>-<slug>   (non-self)
```

- prefix = 出自リポ名 (`personal` 等)。rules の `for-all-from-<name>` と同じ統制
- `for-all` / `for-me` / `for-others` の区別は skill 名に含めない
- 前提: 1 オーバーレイリポ内では `for-*/skills/` 横断で skill slug を一意にする
- 補完性: prefix で出自を絞れる

### 2. commands は skills に一本化

commands と skills は「実行可能 frontmatter 付き Markdown」として本質的に同じ。
今後は skills に一本化する。既存 `commands/*.md` の skills 移行は別 issue
(`docs/issue/2026-05-21-commands-to-skills-migration.md`)。

### 3. ln -sfn 上書き + dangling 掃除

- setup フェーズ: 各 skill を `ln -sfn` で配置 (同名上書き = 移動に追従)
- 後処理フェーズ: `$TARGET/skills/` 直下の **リンク切れ symlink を削除** (移動・削除された skill の残骸掃除)
- 同じ dangling 掃除を `$TARGET/rules/` 側にも入れて一貫させる

### 4. 外部 skill (ベンダー製) は setup.sh に入れない

playwright-cli 等のベンダー製ツールが同梱する skill は、Claude plugin として
配布されていない場合がある。これを setup.sh にハードコードするとデータ駆動が崩れる。
外部 skill は数が少なく個別対応で足りるため、**手動セットアップ手順を runbook に記載**する
(`docs/runbooks/2026-05-21-external-skill-setup.md`)。

## 優先度

着手 (2026-05-21)。

## 関連

- 初出: ある業務オーバーレイで `for-me/skills/<slug>/` を手動配置した 2026-05-14
- `docs/runbooks/2026-05-21-external-skill-setup.md` (外部 skill 手動配置手順)
- `docs/issue/2026-05-21-commands-to-skills-migration.md` (既存 commands の移行)
