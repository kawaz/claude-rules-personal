---
name: docs-structure
description: kawaz/* 各リポジトリの `docs/` 構造標準化ルール。新規 doc ファイル作成 (README / DESIGN / STRUCTURE / ROADMAP / MANUAL)、`docs/` 配下サブディレクトリへの起票 (decisions/DR / findings / journal / runbooks / issue / research / knowledge / design)、DR 起票 + INDEX.md 更新、`YYYY-MM-DD-<slug>.md` 命名、ja/en 翻訳ペア運用 (README / DESIGN / MANUAL)、相互リンクヘッダ、justfile の canonical 参照 (kawaz/bump-semver)、`docs/issue/` 解決時の削除フロー、既存リポの migration 等、kawaz リポの docs 配下を触る作業時に参照。新規ファイル作成時は同梱の `templates/` 配下テンプレを起点にする。
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
全 project type 共通 (docs/ 構造自体は言語非依存。言語固有要素は justfile 等の build 設定側で吸収)。

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
2. `just push` 実行時に `check-outdated-translations` (justfile recipe) が「翻訳先 (en) が正本 (ja) より古い」を検出 → エラー
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

### 実装

translation pair の検証は `bump-semver vcs outdated` を justfile recipe (例: `check-outdated-translations`) として組み込み、`push` recipe の deps に置く。

- **正本 = `*-ja.md`** (kawaz 慣習)、翻訳先 = 同 basename の `*.md` (en)、glob + proxy 規則で 1:1 発見
- 検証内容: 正本 commit > 翻訳先 commit を検出 (= 翻訳先が古い = lag、失敗)
- timestamp は **jj/git log** で取得 (stat mtime は jj workspace 切替で揺れるため避ける)
- `ensure-clean` を deps に挟む (未コミット状態で timestamp 比較しても意味がない)
- 相互リンク冒頭 5 行の存在チェックを併用したいリポでは別 recipe を立てる (実例: kawaz/claude-cmux-msg の `_check-translation-headers`)

詳細は **kawaz/bump-semver の `justfile`** (`check-outdated-translations` recipe) と `bump-semver vcs outdated --help` を参照。

## task runner (justfile)

各リポのタスクランナーは **`justfile`** を canonical とする。kawaz/bump-semver の `justfile` が基準実装。
新規リポでは kawaz のアクティブなリポジトリの justfile を参考に書く。
言語やカテゴリが近いリポ以外も含む最低5個を読んで共通パターンの把握と進出の良パターンを取り入れる検討をする。

```bash
ls -lt ~/.local/share/repos/github.com/kawaz/*/main/justfile | head
```

bump-semver / cmux-msg / session-analysis 等の justfile を見ると、概ね次の recipe が並ぶ (詳細は実体):

- `ci` — lint + test
- `check-outdated-translations` — 翻訳 commit-lag 検出 (`bump-semver vcs outdated`)
- `check-version-bumped` — product code 変更時に VERSION 進行を要求 (paths でフィルタ)
- `bump-version` — `bump-semver --write` で version file 更新 + `jj commit`
- `ensure-clean` — working tree clean 検証
- `push` — 上記 gate を deps に並べて `bump-semver vcs push` を叩く

**push 順序の注意 (mutating lint との関係)**: `ci` が `gofmt -w` 等で tree を mutate するリポでは `ensure-clean` を `ci` の **後** に置く (bump-semver は `check-outdated-translations` の transitive 依存で `ensure-clean` が `ci` 後に走る形)。`prettier --check` / `cargo fmt --check` / `oxfmt --check` 等 non-mutating lint のみのリポは `push` の先頭で `ensure-clean` を回しても問題ない。

過渡的に Taskfile.pkl (pkfire / pkf-tasks 経由) を残しているリポもあるが、justfile が canonical 方針。

### just 変数は使わない

just の変数 (`name := value`) は文字列のみ扱え、shell 内 embed で quote 問題を起こす。値の受け渡しは **positional argument** 経由にする (`set positional-arguments` で `$1` / `"$@"` が使える)。

- list 値 (= `bump-trigger-paths` 等) は recipe の dependency 引数渡しで表現:
  ```just
  check-version-bumped: (_check-version-bumped "src/" "go.mod" "go.sum")
  _check-version-bumped *target_paths:
      if ! bump-semver vcs diff -q main@origin -- "$@" ...; then ...
  ```
- shell 内で動的に値を取りたい時は just 変数経由ではなく shell ネイティブの `$(...)` を直接書く:
  ```just
  push:
      @echo "[hint] ... --sha $(bump-semver vcs get commit-id --rev main) ..."
  ```

### バージョン bump recipe

- recipe 名 `bump-version`、引数 `level`（`patch` / `minor` / `major`、default `patch`）
- 実装は `bump-semver` CLI を 1 行で呼び `--write --no-hint` で version file を書き換え、返った新 version を `jj commit -m "Release v..."` に流す
- bump 対象ファイルは各リポで指定（`bump-semver` が basename で形式判定。`VERSION` / `Cargo.toml` / `*.json` を複数一括可、不一致は CLI がエラー停止）
- 言語固有の追従処理（例: Rust の `cargo check` で Cargo.lock 再生成）は `bump-semver --write` の直後・`jj commit` の前に挟み、同一 change で確定
- ツール本体は `kawaz/tap/bump-semver`

### push 時の version bump 漏れ検出

product code に変更があるのに version が `main@origin` から進んでいなければ push を止める gate。`check-version-bumped` recipe を `push` の deps に入れる。trigger paths (= 検出対象) は recipe 内の shell logic で書く (docs / justfile 等の変更は除外)。trigger paths の diff が無い push は自動 skip されるので `push-without-bump` のような別 recipe は不要 (= src 変更したら必ず release という invariant をバイパスさせない)。具体的な実装は bump-semver の `justfile` 参照。

### リリース artifact の有無

配布 artifact (tag + GH Release で配るバイナリ / library 等) を作るリポは `.github/workflows/release.yml` (or 相当) を持ち、push を契機に tag + Release を自動作成する (詳細は `release-flow-awareness.md`)。

artifact を作らないリポ (release workflow を持たないリポ) では `push = リリース完了` とみなして良く、push 後に release / tag の生成を待たない。他用途の workflow (lint CI / security scan 等) があれば、そちらは通常通り watch する。

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

- **kawaz/bump-semver**: `justfile` の **canonical**。task runner / 翻訳 check (`check-outdated-translations`) / version bump gate (`check-version-bumped`) / push gate の基準実装。構造変更はまずここから直し、他リポは追従する（Taskfile.pkl は段階的に縮小、justfile が canonical 方針）
- kawaz/claude-cmux-msg: bump-semver の justfile を TypeScript + claude-plugin にカスタムした例 (multi-file version bump、`validate` / `check-bundle` / `_check-translation-headers` 相互リンク冒頭 5 行存在チェック)。`docs/decisions/`、`docs/design/data-layout-*.md`、`docs/STRUCTURE.md`、`docs/ROADMAP.md`、`docs/journal/`、`README-ja.md` + `README.md`
- kawaz/authsock-warden: `docs/decisions/INDEX.md`、`docs/research/`、DR の書き方
- kawaz/kuu.mbt: 50+ DR の運用、`decisions/archive/` への退避、`research/` への降格、INDEX.md の Active / Archived / Moved to research 3 区分
- kawaz/zunsystem の業務リポジトリ: `docs/journal/` 運用、`docs/todo/`、`docs/references/`
- kawaz/idea-storage: `docs/issue/` 運用検討
