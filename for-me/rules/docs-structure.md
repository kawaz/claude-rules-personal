# docs/ 構造の標準化ルール

kawaz/* の各リポジトリで `docs/` 構成を揃えるためのルール。

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

## 補足: 各カテゴリの運用

`decisions/`:
- INDEX.md は `## Active` / `## Archived` / `## Moved to research/` などの区分で構造化（実例: kuu.mbt）
- 古い DR で「参照すると現役の文脈を汚す」ものは `decisions/archive/` に退避（番号は維持、ファイル名そのまま移動）
- DR が議論ログ・調査寄りに育って判断記録の体を成さなくなったら `research/YYYY-MM-DD-<slug>.md` に降格。INDEX.md の `Moved to research/` 区分で追跡

`issue/`:
- 用途は (a) 自リポの TODO + (b) **他プロジェクトから受けた依頼/要望**（自リポを「依頼受付窓口」として運用）の両方
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

英語版（`{NAME}.md` の側、`{NAME}` は `README` / `DESIGN` / `MANUAL`）:
```markdown
# Title

> English | [日本語](./{NAME}-ja.md)
```

日本語版（`{NAME}-ja.md` の側）:
```markdown
# Title

> [English](./{NAME}.md) | 日本語
```

具体例 (DESIGN ペア):
- `docs/DESIGN.md` の冒頭: `> English | [日本語](./DESIGN-ja.md)`
- `docs/DESIGN-ja.md` の冒頭: `> [English](./DESIGN.md) | 日本語`

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

### canonical Taskfile.pkl テンプレ

canonical は **kawaz/bump-semver の `Taskfile.pkl`**。各リポは構造をそのまま踏襲し、言語依存 task (lint:go / lint:rust 等) と version files (`VERSION` / `Cargo.toml` 等) だけカスタムする。構造変更は bump-semver 側を先に直してから追従する。

骨格 (pkfire 0.10.0+ / pkf-tasks 3.0.0+):

```pkl
amends "package://pkg.pkl-lang.org/github.com/mizchi/pkfire/pkfire@0.10.0#/Taskfile.pkl"

import "package://pkg.pkl-lang.org/github.com/kawaz/pkf-tasks/pkf-tasks@3.0.2#/all.pkl" as kawaz

// 言語固有 task (lint:go の例、Rust/TS 等で同等のものを定義) — internal にして pkf list から隠す
local lintGo: Task = new {
  name = "lint:go"
  visibility = "internal"
  inputs { "src/**/*.go"; "go.mod"; "go.sum" }
  cmd = "gofmt -w .\ngo vet ./..."
}
local lint: Task = new { name = "lint"; deps { lintGo /* + lintRust 等 */ }; cache = false }  // cmd 省略 = deps-only umbrella (pkfire 0.8+)
local test: Task = new { name = "test"; deps { lint }; cmd = "go test ./..." }
local build: Task = new { name = "build"; deps { lint }; cmd = "go build ..."; outputs { "bin/<TOOL>" } }
local ci: Task = new { name = "ci"; deps { lint; test; build }; cache = false }

// version bump gate (kawaz.semver.checkBumped を parameterize)
local checkVersionBumped: Task = (kawaz.semver.checkBumped) {
  compareRef = "main@origin"           // v3.0+ で compareRefCmd → compareRef rename (plain string ref)
  triggerPaths = List("src/")
  versionFiles = List("VERSION")       // ← リポごとに上書き
  taskName = "semver:check-version-bumped"
}.check

// (任意) cmd:<command> input source を使った bin --version の整合 gate (bump-semver v0.16.0+ / pkf-tasks v3.0+)
local versions = (kawaz.semver.versions) {
  versionFiles = List("VERSION")
  cmdSources = List("cmd:./bin/<TOOL> --version")   // ldflags 埋め込み project では推奨
}
local versionDisplay: Task = versions.version           // pkf run version で source 一覧表示
local checkVersionsAligned: Task = versions.checkAligned // gate (push deps に入れる場合は push 側で追加)

// release flow
local bumpVersion: Task = new {
  name = "bump-version"
  deps { kawaz.vcs.ensureClean }
  params { new Param { name = "level"; type = "enum"; choices { "patch"; "minor"; "major" }; default = "patch" } }
  cmd = #"new_version=$(bump-semver "$LEVEL" VERSION --write --no-hint) && jj commit -m "Release v${new_version}""#
}

// push (pkf-tasks の vcs:push を amend、deps を拡張)
local push: Task = (kawaz.vcs.push) {
  name = "push"
  deps { ci; kawaz.docs.checkTranslations; checkVersionBumped; kawaz.migrate.checkPkfTasks; kawaz.migrate.checkPkfire }
}

// default = run + 引数 forward (pkfire 0.7.0+ の `pkf run -- args` で default に流れる)
local default: Task = new {
  name = "default"; deps { build }; acceptsArgs = true; cache = false
  quiet = true   // pkfire 0.8+ で stdout に "[pkf] ..." prefix を出さない
  cmd = #"./bin/<TOOL> "$@""#
}
local list: Task = new { name = "list"; cmd = "pkf list --unsorted"; cache = false; quiet = true }

tasks {
  default; list; test; push; bumpVersion; ci; build; lint; lintGo
  ...kawaz.vcs.tasks; ...kawaz.docs.tasks     // v3.0+: allTasks → tasks rename (pkfire schema 合わせ)
  checkVersionBumped; versionDisplay; checkVersionsAligned
  kawaz.semver.compare; ...kawaz.migrate.tasks
}
```

要点:
- `kawaz.vcs.{commit,push,ensureClean,fetch,fetchTags}` で jj/git auto-dispatch (pkfire 0.7.0+ で `visibility = "internal"` の building block 化)
- `kawaz.docs.checkTranslations` で翻訳ペア検証 (commit-lag + links、umbrella 経由)
- `kawaz.migrate.{checkPkfTasks,checkPkfire}` で `pkf-tasks@` / `pkfire@` の追従漏れ自動検知
- `kawaz.semver.checkBumped` を `compareRef` / `triggerPaths` / `versionFiles` で parameterize (v3.0+ rename、shell exec ではなく plain string ref)
- `kawaz.semver.versions` で `versionFiles` + `cmdSources: List("cmd:./bin/<TOOL> --version")` を渡し、version files と bin --version 出力の整合 gate を `pkf run version` / `semver:check-versions-aligned` 経由で得る (bump-semver v0.16.0+ の `cmd:` input source 必須)
- 並び順 (`tasks { ... }`) は declaration order で `pkf list --unsorted` に反映 (利用頻度順に手書きで整列)
- internal task (`visibility = "internal"`) は `pkf list` から hide、`--all` で reveal
- group spread は `...kawaz.<group>.tasks` (v3.0+、pkfire 0.10.0 の Taskfile.pkl schema field `tasks: Listing<Task>` と統一)
- pkfire 0.10.0+ の `workflowTests` で「Go source 変更が push pipeline 全 task を affected 集合に乗せるか」等を Pkl 上で spec として宣言し `pkf affected --check` で実行プランと比較できる (実例: kawaz/bump-semver の Taskfile.pkl)

参考実装: **kawaz/bump-semver** (Go の canonical)、kawaz/claude-cmux-msg (TypeScript + claude-plugin)。構造変更は canonical を先に直してから他リポへ追従する。

## バージョン bump task

canonical は **kawaz/bump-semver の `Taskfile.pkl`**。各リポはこれを踏襲する:

- **task 名**: `bump-version` (英文コメント `bump version file(s) for Release` と動詞+名詞で整合。CLI 名 `bump-semver` との衝突は実害なし、選択理由は英文整合性)
- **引数名**: `level="patch"` (`level=major|minor|patch`、`level=patch` の方が semantic に読める)
- **実装**: `bump-semver` CLI 呼び出しは 1 行、`--write --no-hint` で書き換え、stdout に返る新 version をそのまま `jj commit -m "Release v..."` に流す
- **ツール本体**: `kawaz/tap/bump-semver` (Go 製、basename 自動判定で `Cargo.toml` / `*.json` / `VERSION` をサポート)

共通テンプレ:

```pkl
local bumpVersion: Task = new {
  name = "bump-version"
  description = "bump version file(s) for Release"
  cache = false
  deps { kawaz.vcs.ensureClean }
  params {
    new Param { name = "level"; type = "enum"; choices { "patch"; "minor"; "major" }; default = "patch" }
  }
  cmd = #"new_version=$(bump-semver "$LEVEL" <FILE...> --write --no-hint) && jj commit -m "Release v${new_version}""#
}
```

`<FILE...>` 部分だけ各リポで上書きする。複数ファイル一括 bump も `bump-semver` が basename で形式判定するので並べるだけで OK (version 不一致は CLI 側でエラー停止)。

実例 (kawaz/bump-semver 自身、VERSION ファイル 1 つ):
```pkl
cmd = #"new_version=$(bump-semver "$LEVEL" VERSION --write --no-hint) && jj commit -m "Release v${new_version}""#
```

実例 (kawaz/claude-cmux-msg、Claude Plugin の 3 ファイル一括):
```pkl
cmd = #"new_version=$(bump-semver "$LEVEL" .claude-plugin/plugin.json .claude-plugin/marketplace.json package.json --write --no-hint) && jj commit -m "Release v${new_version}""#
```

言語固有の追従処理 (例: Rust なら `cargo check --quiet` で Cargo.lock を再生成) が必要なら、`bump-semver --write` の **直後・`jj commit` の前** に挟む。それらも全部含めて 1 つの change として確定する。

### `semver:check-version-bumped` (push 時の bump 漏れ検出)

product code に変更があるのに version が main@origin から進んでいなければエラー停止する gate。`push` の deps に入れる。pkf-tasks の `kawaz.semver.checkBumped` module を parameterize して使う:

```pkl
local checkVersionBumped: Task = (kawaz.semver.checkBumped) {
  compareRef = "main@origin"         // v3.0+ で compareRefCmd → compareRef rename (plain ref string)
  triggerPaths = List("src/")        // ← リポごとに上書き (docs/ や README は除外)
  versionFiles = List("VERSION")     // ← リポごとに上書き (Cargo.toml / package.json 等も可、複数指定可)
  taskName = "semver:check-version-bumped"
}.check
```

動的 ref (= 最新 tag と比較したい等) は `compareRef = "vcs:latest-tag()"` のように bump-semver の `vcs:` schema 関数形式を直接書ける (= 内部で `bump-semver get` 経由で解決)。

このゲートがあれば docs 修正のみの push は自動 skip される (= triggerPaths の diff なしならエラーにならない)。`push-without-bump` のような別 task は不要。

ローカル PATH に `bump-semver` を入れる必要があるため、`kawaz/dotfiles/darwin/default.nix` の `homebrew.brews` に `"kawaz/tap/bump-semver"` を含める。

旧パターンからの移行 (justfile → Taskfile.pkl):

- justfile の `set unstable` + `is-jj` / `is-git` shell 変数 → pkf-tasks の `kawaz.vcs.*` (auto-dispatch 内蔵)
- justfile の `ensure-clean` recipe → `kawaz.vcs.ensureClean` task
- justfile の `check-translations` recipe (`_check-translation` / `_file-ts` helper 込) → `kawaz.docs.checkTranslations` (umbrella) + sub task
- justfile の `check-version-bumped` recipe (`[script]` 内 jj diff / git diff + bump-semver compare) → `kawaz.semver.checkBumped` module を parameterize して `.check` で取り出す
- justfile の `bump-version bump="patch"` recipe → Taskfile.pkl の `local bumpVersion: Task` (引数名は `level` に変更、Param で typed enum)
- justfile の `default: ` recipe (`@just --list --unsorted` wrapper) → Taskfile.pkl の `default` task (`acceptsArgs = true` + `./bin/<TOOL> "$@"`、`pkf run -- args` で引数 forward)
- justfile の `list:` recipe → `local list: Task = new { ... cmd = "pkf list --unsorted" }`
- justfile の `run *ARGS: build` recipe → `default` task に統合 (= 上記)

参考実装: **kawaz/bump-semver** (canonical, 自己ドッグフーディング、Go)、kawaz/claude-cmux-msg (multi-file + claude-plugin, TypeScript)。

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

- **kawaz/bump-semver**: Taskfile.pkl の **canonical** (pkfire 0.7.0+ / pkf-tasks 2.2.0+)。`amends` / `import` URI、`lintGo` / `lint` / `test` / `build` / `ci` / `checkVersionBumped` / `bumpVersion` / `push` / `default` (+ acceptsArgs) / `list` (+ `pkf list --unsorted`) の構造。`visibility = "internal"` の使い分け。構造変更はまずここから直す。**justfile は v2.2.0 で廃止済** (Taskfile.pkl 単独運用)
- kawaz/claude-cmux-msg: bump-semver テンプレを TypeScript + claude-plugin にカスタムした例 (multi-file version bump、`validate` / `check-bundle` 追加)。`docs/decisions/`、`docs/design/data-layout-*.md`、`docs/STRUCTURE.md`、`docs/ROADMAP.md`、`docs/journal/`、`README-ja.md` + `README.md`
- kawaz/authsock-warden: `docs/decisions/INDEX.md`、`docs/research/`、DR の書き方
- kawaz/kuu.mbt: 50+ DR の運用、`decisions/archive/` への退避、`research/` への降格、INDEX.md の Active / Archived / Moved to research 3 区分
- kawaz/zunsystem の業務リポジトリ: `docs/journal/` 運用、`docs/todo/`、`docs/references/`
- kawaz/idea-storage: `docs/issue/` 運用検討
