# 言語ポリシーと翻訳ペア運用

OSS（公開リポジトリ）では以下の **必須対象**で日本語原本 + 英語翻訳のペア運用:

- `README.md` (英訳) + `README-ja.md` (原本)
- `docs/DESIGN.md` (英訳) + `docs/DESIGN-ja.md` (原本)
- `docs/MANUAL.md` (英訳) + `docs/MANUAL-ja.md` (原本) [作る場合]

その他（`docs/` 配下のサブディレクトリすべて: DR / research / findings / journal / knowledge / runbooks / issue / design）は **日本語のみ**。kawaz 自身が読みやすい優先。

## 開発フロー（英語版の更新タイミング）

英語版の翻訳はローカル作業中はやらない（コンテキストの無駄）。**push 時のガードで漏れを防ぐ**:

1. ローカル作業中は `*-ja.md` のみ編集
2. `just push` 実行時に `check-outdated-translations` (justfile recipe) が「翻訳先 (en) が正本 (ja) より古い」を検出 → エラー
3. その時点で英語版を翻訳更新 → commit → push 再試行

## 相互リンクのテンプレ

タイトル直下に `>` blockquote で配置（末尾だと存在に気付きにくいため）。リンク先は **同じディレクトリ内の対応する相手ファイル**（README ↔ README-ja、DESIGN ↔ DESIGN-ja、MANUAL ↔ MANUAL-ja）。

具体的なリンク行は各テンプレ (`~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/docs-authoring/templates/README{,-ja}.template.md` 等) の冒頭に既に埋め込んでいるので、テンプレをコピーして使う限り意識不要。手書きで新規ファイルを作る場合のフォーマット:

- 英語版 (`{NAME}.md`、`{NAME}` は `README` / `DESIGN` / `MANUAL`):
  ```markdown
  # Title

  > English | [日本語](./{NAME}-ja.md)
  ```
- 日本語版 (`{NAME}-ja.md`):
  ```markdown
  # Title

  > [English](./{NAME}.md) | 日本語
  ```

## 実装

translation pair の検証は `bump-semver vcs outdated` を justfile recipe (例: `check-outdated-translations`) として組み込み、`push` recipe の deps に置く。

- **正本 = `*-ja.md`** (kawaz 慣習)、翻訳先 = 同 basename の `*.md` (en)、glob + proxy 規則で 1:1 発見
- 検証内容: 正本 commit > 翻訳先 commit を検出 (= 翻訳先が古い = lag、失敗)
- timestamp は **jj/git log** で取得 (stat mtime は jj workspace 切替で揺れるため避ける)
- `ensure-clean` を deps に挟む (未コミット状態で timestamp 比較しても意味がない)
- 相互リンク冒頭 5 行の存在チェックを併用したいリポでは別 recipe を立てる (実例: kawaz/claude-cmux-msg の `_check-translation-headers`)

詳細は **kawaz/bump-semver の `justfile`** (`check-outdated-translations` recipe) と `bump-semver vcs outdated --help` を参照。
