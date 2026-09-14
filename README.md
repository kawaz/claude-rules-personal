# claude-rules-personal

kawaz の Claude Code 用ルール / スキルの **central リポジトリ**。
`claude-rules-*` overlay 群を束ね、`just setup` で各 `CLAUDE_CONFIG_DIR` に配備する。

## リポジトリ群の構成

`claude-rules-*` は 1 つの central + 複数の overlay で構成される。

| リポ | 役割 | 専用環境 (CLAUDE_CONFIG_DIR) |
|------|------|------|
| **kawaz/claude-rules-personal** (これ) | central。全 overlay を束ね、配備 recipe (`justfile` + `scripts/`) / `repos_mapping.json` を持つ | `~/.claude-personal` |
| kawaz123/claude-rules-emrd | emrd 業務面の overlay (private) | `~/.claude-emrd` |
| kawaz/claude-rules-zunsystem | zunsystem 識別子 overlay (private) | (専用環境なし) |
| kawaz/claude-rules-syun | syun 識別子 overlay (private) | (専用環境なし) |

- 配備 recipe と `repos_mapping.json` は **この personal リポにのみ置く** (2 重管理しない)
- どの overlay のルール/スキルを変更しても、反映は **personal で `just setup` を実行**する
- 整理方法・設計判断などの詳細ドキュメントは **personal の `docs/` に集約**する

## レイアウト

各リポ共通:

- `for-all/rules/` — 全環境向けルール (全 `~/.claude*/rules/` に注入)
- `for-all/plugins.json` — 全環境に入れる Claude Code plugin の宣言 (`just plugins-setup` が install)
- `for-me/rules/` — その面の専用環境にのみ注入
- `for-me/plugins.json` — その面の専用環境にのみ install する plugin の宣言。
  plugin の skill / agent description は全セッションの context に載るので、
  面固有の plugin はこちらに置く (for-all に置くと他の面にも語彙が漏れる)
- `for-others/rules/` — 他環境から参照される情報 (固有名詞リスト等のサニタイズ規定)

skill と agent は **リポ自体を Claude Code plugin として配布**する
(`.claude-plugin/plugin.json` + リポ直下の `skills/<slug>/` `agents/` `hooks/`)。
各リポの `for-all/plugins.json` に自リポの plugin を宣言し、`just plugins-setup` が install
することで配備される。Skill tool からは `<plugin名>:<slug>` (例:
`rules-personal:eli5`) で呼ぶ。skill はユーザが `/名前` で起動する実行系だけを置き、
読むだけの手順書は `reference/` に置く (判定は `for-all/rules/rule-writing-guidelines.md`)。
AI に自動起動させたくないユーザ専用の skill は frontmatter に `disable-model-invocation: true` を付け (AI の一覧から消える)、
本文は reference の該当ファイルを読ませる 1〜2 行に留める。

読むだけの参照知識はこのリポの直下に平置きする (索引と本文の 2 段構成、本文は必要時にだけ Read):

- `reference/` — 公開してよい体系知識。索引は `reference/_index.md`
- `memory/` — rule にするほど一般化していない横断メモ。索引は `memory/_index.md`

個人情報系 (本人の表記・アカウント名・連絡先) は public 候補のこのリポではなく private リポ `kawaz/privacy-personal` に同じ構造で置き、その索引だけを `reference/_index.md` の「private 層」節に写す (業務面でしか効かないものは各 overlay の `for-me/`)。
書き先の判定は `for-all/rules/knowledge-guide.md`。

`for-me` の "me" は「個人 vs 他者」ではなく、kawaz が持つ複数の面
(個人開発 / emrd 業務 / ...) のうちの **その overlay の面**を指す。

personal リポ固有:

- `scripts/rules.sh` / `scripts/plugins.sh` — 配備スクリプト (subject ごと。`justfile` の recipe から呼ぶ)
- `repos_mapping.json` — 全 overlay リポと各 `home` (CLAUDE_CONFIG_DIR) の定義
- `docs/` — 設計判断・課題 (`issue/`)、運用手順 (`runbooks/`) 等

## セットアップ

配備は `just` の recipe で行う。subject (rules / plugins) ごとに `<subject>-{setup,check,update}` があり、`setup` / `check` / `update` がそれらを束ねる。`home` 引数を省略すると `repos_mapping.json` に宣言された全面が対象:

```bash
just setup                      # 全面: rules の symlink + plugin の install
just check                      # 全面: 配備状態の検査 (変更しない)
just update                     # 全面: plugin の update
just rules-setup ~/.claude-emrd # 1 面だけ
```

- `rules-setup`: `for-*/rules/` を `$HOME_DIR/rules/` 配下にディレクトリ symlink し、dangling link を掃除 (`rules-check` は期待する link が揃って実体を指しているかを検査)
- `plugins-setup`: `for-all/plugins.json` (全 repo) と自面の `for-me/plugins.json` に宣言された plugin を `marketplace add` + `install`。bare 面 (`~/.claude-bare`) は `repos_mapping.json` の `pluginOnlyHomes` に列挙した ccmsg だけを入れる
- `plugins-check`: rules 面は宣言の不足だけ、bare 面は ccmsg 以外が入っていないことも検査。宣言外に手で入れた plugin と enable / disable 状態は触らない

## ドキュメント

- `docs/issue/` — TODO・課題
- `docs/runbooks/` — 運用・セットアップ手順

## サニタイズ

業務固有名詞は public 候補の personal には置かず、各 overlay リポ (private) で管理。
共通サニタイズの仕組みは `for-all/rules/sanitize-work-identifiers.md` を参照。
