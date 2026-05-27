---
name: docs-structure
description: kawaz/* 各リポジトリの `docs/` 構造標準化ルール。新規 doc ファイル作成 (README / DESIGN / STRUCTURE / ROADMAP / MANUAL)、`docs/` 配下サブディレクトリへの起票 (decisions/DR / findings / journal / runbooks / issue / research / knowledge / design)、DR 起票 + INDEX.md 更新、`YYYY-MM-DD-<slug>.md` 命名、ja/en 翻訳ペア運用 (README / DESIGN / MANUAL)、相互リンクヘッダ、Taskfile.pkl の canonical 参照、`docs/issue/` 解決時の削除フロー、既存リポの migration 等、kawaz リポの docs 配下を触る作業時に参照。新規ファイル作成時は同梱の `templates/` 配下テンプレを起点にする。
---

# kawaz docs/ 構造標準化

kawaz/* の各リポジトリで `docs/` 構成を揃えるためのルール。テンプレファイルは
同 skill 内 `templates/` 配下に embed されている (= 新規ファイル作成時に起点として利用)。

## 命名規則

- **リポジトリ直下にあるドキュメントは `README{,-ja}.md` のみ** (Unix 慣例。`LICENSE` も慣例的に直下)
- **`docs/` 直下のドキュメントは大文字 + `.md`**: `DESIGN.md` `STRUCTURE.md` `ROADMAP.md` `MANUAL.md`
  - 大文字でサブディレクトリ（小文字）と視覚区別できる
- **`docs/` 配下のサブディレクトリは小文字**: `decisions/` `findings/` `journal/` `research/` `knowledge/` `runbooks/` `issue/` `design/`
- **サブディレクトリ内のファイル名は原則 `YYYY-MM-DD-<slug>.md`**:
  - 全カテゴリで日付プレフィックス必須
  - 理由: 数が増えた時に気付きやすい、タイムスタンプは jj/git rebase であてにならない、slug に内容情報があるので日付追加で情報が減ることはない
  - 例外: `decisions/DR-NNNN-title.md`（4 桁ゼロパディング）、`design/<topic>-<sub>.md`（付随詳細はハイフン付き複合名で日付なし）

## ディレクトリ構造

```
README{,-ja}.md         ユーザ向けの最初の窓口（リポジトリ直下、英訳必須）
LICENSE                 MIT License (kawaz リポジトリの規約)
docs/
  DESIGN{,-ja}.md       現実装の説明（ドメイン + アーキテクチャ。英訳必須）
  STRUCTURE.md          リポジトリの物理構造
  ROADMAP.md            将来検討項目
  MANUAL{,-ja}.md       エンドユーザ向けマニュアル（任意、英訳必須）
  decisions/            設計判断の記録（DR）。設計判断が複数あれば作成
    DR-NNNN-title.md    DR 本体（4 桁ゼロパディング）
    INDEX.md            DR 一覧（必須）
  research/<f>          中期テーマの深掘り（長文）。長文調査が出てきたら
  findings/<f>          単発調査の確定事実
  journal/<f>           日々の生記録（ハマり所→解決策のペア、コマンド・設定値）。non-stop 作業が多いプロジェクトで特に有用
  knowledge/<f>         時系列依存しない長期ナレッジ（OS 挙動などストックしたい知見）
  runbooks/<f>          運用・復旧手順（運用フェーズに入ったら）
  issue/<f>             自リポ TODO + 他プロジェクトから受けた依頼/要望（依頼受付窓口）
  design/<topic>.md     設計の付随詳細（ハイフン付き複合名、日付なし、単一 DESIGN.md で収まらないとき）

# <f> = YYYY-MM-DD-<slug>.md
```

`guide` という単語は **避ける**。「開発者向け」か「ユーザ向け」かが読み取れない。エンドユーザ向けは `MANUAL.md`、開発者向けは `docs/` 直下のフラットなファイルで扱う。

## テンプレファイル一覧

新規ファイル作成時は `templates/` 配下のテンプレを起点にする (= placeholder を実値に置換)。
全 project type 共通 (docs/ 構造自体は言語非依存。言語固有要素は Taskfile.pkl 等の build 設定側で吸収)。

| 用途 | テンプレ |
|---|---|
| README ja (リポ直下) | `templates/README-ja.template.md` |
| README en (リポ直下) | `templates/README.template.md` |
| DESIGN ja | `templates/DESIGN-ja.template.md` |
| DESIGN en | `templates/DESIGN.template.md` |
| STRUCTURE | `templates/STRUCTURE.template.md` |
| ROADMAP | `templates/ROADMAP.template.md` |
| MANUAL ja | `templates/MANUAL-ja.template.md` |
| MANUAL en | `templates/MANUAL.template.md` |
| DR 本体 | `templates/decisions/DR-NNNN-template.md` |
| DR INDEX | `templates/decisions/INDEX.template.md` |
| issue | `templates/issue/YYYY-MM-DD-template.md` |
| journal | `templates/journal/YYYY-MM-DD-template.md` |
| findings | `templates/findings/YYYY-MM-DD-template.md` |
| runbooks | `templates/runbooks/YYYY-MM-DD-template.md` |
| research | `templates/research/YYYY-MM-DD-template.md` |
| knowledge | `templates/knowledge/YYYY-MM-DD-template.md` |
| design 付随詳細 | `templates/design/topic-template.md` |

テンプレ内の placeholder (= `{PROJECT_NAME}`, `{タイトル}`, `YYYY-MM-DD`, `NNNN` 等) は
実値に置換してから配置する。

## 補足: 各カテゴリの運用

`decisions/`:
- INDEX.md は `## Active` / `## Archived` / `## Moved to research/` などの区分で構造化（実例: kuu.mbt）
- 古い DR で「参照すると現役の文脈を汚す」ものは `decisions/archive/` に退避（番号は維持、ファイル名そのまま移動）
- DR が議論ログ・調査寄りに育って判断記録の体を成さなくなったら `research/YYYY-MM-DD-<slug>.md` に降格。INDEX.md の `Moved to research/` 区分で追跡

`issue/`:
- 用途は (a) 自リポの TODO + (b) **他プロジェクトから受けた依頼/要望**（自リポを「依頼受付窓口」として運用）+ (c) **ゆるいメモ置き場 / セッション跨ぎ議論記録** の 3 方向
- 認識: **GitHub flow のような厳密な issue 回しではない、一段ゆるい運用**。具体的には以下のような使い方が想定される:
  - 比較的大きな改修アイデアで時間をかけたいもの（今すぐ手をつけないが頭の中に残しておくと邪魔なメモ）
  - 忙しい時に後回しにしたいタスク
  - 別リポジトリへの非同期メッセージ（= 上記 (b)）
  - 議論経過をセッションを跨いで保存したい時のメモ（= 同じ issue ファイルに議論を追記して育てる用途も OK）
- 起票の「重さ」に幅を持たせて良い:
  - **small issue** (= 数行のメモ、1 セッションで解決可) も OK、過剰に構造化しなくて良い
  - **large issue** (= 設計検討込み長文、複数セッションで議論を追記しながら成熟させる) も OK
  - GH issue のような「Status / Priority / Labels / Assignee」厳密管理は不要、ヘッダは Status と Date 程度で十分
- **他プロジェクトへ依頼する場合は相手プロジェクトの `docs/issue/`** に書く（自リポに書くと相手が見つけられない）。発端は別ローカルプロジェクト間での依頼受付として設計したもの
- 想定する「相手プロジェクト」は kawaz 自身が管理するリポに限定される。本ルールはその前提で設計されている
- 相手リポが `docs/issue/` 慣習を持っていない場合は、依頼自体は新ルール（`docs/issue/YYYY-MM-DD-<slug>.md`）で起票し、同時に「docs-structure 準拠への移行依頼」を別 issue として相手リポに作成する（kawaz の自リポ群で揃える方針のため）
- 解決した issue は **削除**（jj/git 履歴で追える、`done/` 移動はしない）
- 削除前に内容に応じて `decisions/` `runbooks/` `journal/` に記録を残す（`docs-knowledge-flow.md` 参照）

`journal/` と `findings/` の境界:
- journal: 日々の生記録、ハマり所と解決策のペア、コマンド・設定値、後日読み返して状況復元できる粒度。non-stop 直後の確認に膨大なログより向く
- findings: 単発調査の確定事実中心、検証の詳細を残す形

## 言語ポリシー

OSS（公開リポジトリ）では以下の **必須対象**で日本語原本 + 英語翻訳のペア運用:

- `README.md` (英訳) + `README-ja.md` (原本)
- `docs/DESIGN.md` (英訳) + `docs/DESIGN-ja.md` (原本)
- `docs/MANUAL.md` (英訳) + `docs/MANUAL-ja.md` (原本) [作る場合]

その他（`docs/` 配下のサブディレクトリすべて: DR / research / findings / journal / knowledge / runbooks / issue / design）は **日本語のみ**。kawaz 自身が読みやすい優先。

### 開発フロー（英語版の更新タイミング）

英語版の翻訳はローカル作業中はやらない（コンテキストの無駄）。**push 時のガードで漏れを防ぐ**:

1. ローカル作業中は `*-ja.md` のみ編集
2. `pkf run push` 実行時に `docs:check-translation-commit-lag` が「翻訳先 (en) が正本 (ja) より古い」を検出 → エラー
3. その時点で英語版を翻訳更新 → commit → push 再試行

### 相互リンクのテンプレ

タイトル直下に `>` blockquote で配置（末尾だと存在に気付きにくいため）。リンク先は **同じディレクトリ内の対応する相手ファイル**（README ↔ README-ja、DESIGN ↔ DESIGN-ja、MANUAL ↔ MANUAL-ja）。

具体的なリンク行は各テンプレ (`templates/README{,-ja}.template.md` 等) の冒頭に
既に埋め込んでいるので、テンプレをコピーして使う限り意識不要。手書きで新規ファイルを
作る場合のフォーマット:

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

### 実装 (pkf-tasks 経由、v2.2.0+)

translation pair の検証は `kawaz/pkf-tasks` の `docs:check-translation-{commit-lag,links}` を deps に組み込む。仕様:

- **正本 = `*-ja.md`** (kawaz 慣習)、翻訳先 = 同 basename の `*.md` (en)、proxy が 1:1 で発見
- 検証内容:
  - `docs:check-translation-commit-lag`: commit timestamp 比較 (翻訳先 < 正本 = lag、失敗)
  - `docs:check-translation-links`: 相互リンクの冒頭 5 行存在チェック (ja ↔ en 規約)
  - `docs:check-translations` (umbrella): 上記 2 つを deps で並列実行
- timestamp は **jj/git log** で取得 (stat mtime は jj workspace 切替で揺れるため避ける)
- `kawaz.vcs.ensureClean` を deps で挟む (未コミット状態で timestamp 比較しても意味がない)

詳細仕様 / API / CLI argument 渡しは [kawaz/pkf-tasks](https://github.com/kawaz/pkf-tasks) の `docs/` group README を参照。

## Taskfile.pkl（task runner 設定）

各リポの `Taskfile.pkl` の canonical は **kawaz/bump-semver の `Taskfile.pkl`**。各リポはその実ファイルを参照してそのまま踏襲し、言語依存 task（`lint:go` / `lint:rust` 等）と version files（`VERSION` / `Cargo.toml` 等）だけカスタムする。構造変更は bump-semver 側を先に直し、他リポはそれに追従する。**ルールにテンプレを複製しない** — 実ファイル（bump-semver の `Taskfile.pkl`）が常に正本。

骨格は pkfire を `amends`、kawaz/pkf-tasks を `import` し、以下の task group を組み合わせる:

- `kawaz.vcs.*` — jj/git auto-dispatch（commit / push / ensureClean / fetch）
- `kawaz.docs.*` — 翻訳ペア検証（`checkTranslations`）
- `kawaz.semver.*` — version bump gate（`checkBumped`）、version 整合（`versions`）
- `kawaz.migrate.*` — `pkf-tasks@` / `pkfire@` の追従漏れ検知

詳細仕様・API・最新の骨格は **kawaz/bump-semver の `Taskfile.pkl`** と **kawaz/pkf-tasks の README** を参照。

### バージョン bump task

- task 名 `bump-version`、引数 `level`（`patch` / `minor` / `major` の enum、default `patch`）
- 実装は `bump-semver` CLI を 1 行で呼び `--write --no-hint` で version file を書き換え、返った新 version を `jj commit -m "Release v..."` に流す
- bump 対象ファイルは各リポで指定（`bump-semver` が basename で形式判定。`VERSION` / `Cargo.toml` / `*.json` を複数一括可、version 不一致は CLI がエラー停止）
- 言語固有の追従処理（例: Rust の `cargo check` で Cargo.lock 再生成）は `bump-semver --write` の直後・`jj commit` の前に挟み、同一 change で確定
- ツール本体は `kawaz/tap/bump-semver`（`kawaz/dotfiles` の `homebrew.brews` に含める）

### push 時の version bump 漏れ検出

product code に変更があるのに version が `main@origin` から進んでいなければ push を止める gate。`kawaz.semver.checkBumped` を `compareRef` / `triggerPaths` / `versionFiles` で parameterize し `push` の deps に入れる。`triggerPaths` の diff が無い push（docs 修正のみ等）は自動 skip されるので `push-without-bump` のような別 task は不要。具体的なパラメタ例は bump-semver の `Taskfile.pkl` 参照。

## 配布物の付随ドキュメント

ランタイムが symlink で参照するドキュメント（例: cmux-msg がデータディレクトリ各階層に貼る README）は `docs/design/` 配下にソースを置き、ランタイムが `.docs/v<version>/` にコピー → `.docs/latest` symlink → 各階層 `README.md` symlink で参照する。

`/usr/share/doc/` のような OS 配布物スタイルは古い（探さない、見に行かない）ので避ける。一方、データディレクトリ自身が cd/ls 動線で自己言及するのは別物で、これは推奨。

## 既存リポのマイグレーション

新ルール確定後の既存リポは **触ったついで** で揃える。一気にマイグレーションする必要はない。

ありがちな移行作業:
- 直下のファイルを大文字化（`design.md` → `DESIGN.md` 等）
- リポジトリ直下にあった `DESIGN.md` `STRUCTURE.md` `ROADMAP.md` `MANUAL.md` を `docs/` 配下に移動（`README.md` だけ直下に残す）
- DR を `dr-NNN-...md` (3 桁・小文字) → `DR-NNNN-title.md` (4 桁・大文字) に
- 旧位置 (`docs/dr-...md`、`docs/archives/dr-...md` 等) から `docs/decisions/` 配下へ移動
- `INDEX.md` 新設
- サブディレクトリ内のファイル名を `YYYY-MM-DD-<slug>.md` に揃える
- `docs/layout/` のような単発ディレクトリは `docs/design/` 配下にハイフン付きファイルで吸収

## 参考実装

- **kawaz/bump-semver**: `Taskfile.pkl` の **canonical**。構造変更はまずここから直し、他リポは追従する（justfile は廃止済、Taskfile.pkl 単独運用）
- kawaz/claude-cmux-msg: bump-semver テンプレを TypeScript + claude-plugin にカスタムした例 (multi-file version bump、`validate` / `check-bundle` 追加)。`docs/decisions/`、`docs/design/data-layout-*.md`、`docs/STRUCTURE.md`、`docs/ROADMAP.md`、`docs/journal/`、`README-ja.md` + `README.md`
- kawaz/authsock-warden: `docs/decisions/INDEX.md`、`docs/research/`、DR の書き方
- kawaz/kuu.mbt: 50+ DR の運用、`decisions/archive/` への退避、`research/` への降格、INDEX.md の Active / Archived / Moved to research 3 区分
- kawaz/zunsystem の業務リポジトリ: `docs/journal/` 運用、`docs/todo/`、`docs/references/`
- kawaz/idea-storage: `docs/issue/` 運用検討
