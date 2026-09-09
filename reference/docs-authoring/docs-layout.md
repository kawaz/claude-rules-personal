# kawaz docs/ 構造標準

kawaz/* の各リポジトリで `docs/` 構成を揃えるためのルール。テンプレファイルは `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/docs-authoring/templates/` 配下にある (= 新規ファイル作成時に起点として利用)。

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

新規ファイル作成時は `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/docs-authoring/templates/` 配下のテンプレを起点にする (= placeholder を実値に置換)。全 project type 共通 (docs/ 構造自体は言語非依存。言語固有要素は justfile 等の build 設定側で吸収)。

以下の表のパスは `reference/docs-authoring/templates/` からの相対。

| 用途 | テンプレ |
|---|---|
| README ja (リポ直下) | `README-ja.template.md` |
| README en (リポ直下) | `README.template.md` |
| DESIGN ja | `DESIGN-ja.template.md` |
| DESIGN en | `DESIGN.template.md` |
| STRUCTURE | `STRUCTURE.template.md` |
| ROADMAP | `ROADMAP.template.md` |
| MANUAL ja | `MANUAL-ja.template.md` |
| MANUAL en | `MANUAL.template.md` |
| DR 本体 | `decisions/DR-NNNN-template.md` |
| DR INDEX | `decisions/INDEX.template.md` |
| issue | `issue/YYYY-MM-DD-template.md` |
| journal | `journal/YYYY-MM-DD-template.md` |
| findings | `findings/YYYY-MM-DD-template.md` |
| runbooks (汎用) | `runbooks/YYYY-MM-DD-template.md` |
| runbooks (worktree 合流・push) | `runbooks/worktree-workflow.template.md` |
| research | `research/YYYY-MM-DD-template.md` |
| knowledge | `knowledge/YYYY-MM-DD-template.md` |
| design 付随詳細 | `design/topic-template.md` |
| QUESTIONS (裁定・確認待ち) | `QUESTIONS.template.md` (運用は reference の `docs-authoring/questions-registry`) |

テンプレ内の placeholder (= `{PROJECT_NAME}`, `{タイトル}`, `YYYY-MM-DD`, `NNNN` 等) は実値に置換してから配置する。`worktree-workflow.template.md` のように中身が確定済みのテンプレは placeholder 置換がほぼ不要で、そのまま配置先の命名規則に合わせて置く。

## 補足: 各カテゴリの運用

`decisions/`:

- INDEX.md は `## Active` / `## Archived` / `## Moved to research/` などの区分で構造化（実例: kuu.mbt）
- 古い DR で「参照すると現役の文脈を汚す」ものは `decisions/archive/` に退避（番号は維持、ファイル名そのまま移動）
- DR が議論ログ・調査寄りに育って判断記録の体を成さなくなったら `research/YYYY-MM-DD-<slug>.md` に降格。INDEX.md の `Moved to research/` 区分で追跡

`issue/`:

- 運用の正本は **[claude-local-issue plugin](https://github.com/kawaz/claude-local-issue)** (sub-command: `write` / `read` / `update` / `list` / `migrate`)。本節は plugin が前提とする運用方針 (= 何を / どこに置くか) のみ扱う。frontmatter / status 遷移 / archive の機械的詳細は plugin の `SKILL.md` / `docs/DESIGN.md`
- 用途は (a) 自リポの TODO + (b) **他プロジェクトから受けた依頼/要望** (自リポを「依頼受付窓口」として運用) + (c) **ゆるいメモ置き場 / セッション跨ぎ議論記録** の 3 方向
- 認識: **GitHub flow のような厳密な issue 回しではない、一段ゆるい運用**。具体的には以下のような使い方が想定される:
  - 比較的大きな改修アイデアで時間をかけたいもの (今すぐ手をつけないが頭の中に残しておくと邪魔なメモ)
  - 忙しい時に後回しにしたいタスク
  - 別リポジトリへの非同期メッセージ (= 上記 (b))
  - 議論経過をセッションを跨いで保存したい時のメモ (= 同じ issue ファイルに議論を追記して育てる用途も OK)
- 起票の「重さ」に幅を持たせて良い:
  - **small issue** (= 数行のメモ、1 セッションで解決可) も OK、過剰に構造化しなくて良い
  - **large issue** (= 設計検討込み長文、複数セッションで議論を追記しながら成熟させる) も OK
  - frontmatter の管理は plugin の sub-command (= `write` / `update`) が担うので手書きしない
- **他プロジェクトへ依頼する場合は相手プロジェクトの `docs/issue/`** に書く (自リポに書くと相手が見つけられない)。発端は別ローカルプロジェクト間での依頼受付として設計したもの
- 想定する「相手プロジェクト」は kawaz 自身が管理するリポに限定される。本ルールはその前提で設計されている
- 相手リポが `docs/issue/` 慣習を持っていない場合は、依頼自体は新ルール (`docs/issue/YYYY-MM-DD-<slug>.md`) で起票し、同時に「docs/ 構造標準への移行依頼」を別 issue として相手リポに作成する (kawaz の自リポ群で揃える方針のため)
- 解決した issue は plugin の **`update <slug> close`** で archive へ移動 (= `docs/issue/archive/<file>.md`、`status: resolved` 遷移、`close_reason` 記録)。frontmatter の全 timestamp が DB として残るので、過去経緯は `grep -r docs/issue/archive/` で参照可
- archive 移動の前に、内容に応じて `decisions/` `runbooks/` `journal/` に記録を残す (reference の `docs-authoring/knowledge-timing` 参照)

`journal/` と `findings/` の境界:

- journal: 日々の生記録、ハマり所と解決策のペア、コマンド・設定値、後日読み返して状況復元できる粒度。non-stop 直後の確認に膨大なログより向く
- findings: 単発調査の確定事実中心、検証の詳細を残す形

## 配布物の付随ドキュメント

ランタイムが symlink で参照するドキュメント（データディレクトリ各階層に貼る README 等）は `docs/design/` 配下にソースを置き、ランタイムが `.docs/v<version>/` にコピー → `.docs/latest` symlink → 各階層 `README.md` symlink で参照する。

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

- **kawaz/bump-semver**: `justfile` の **canonical**。task runner / 翻訳 check (`check-outdated-translations`) / version bump gate (`check-version-bumped`) / push gate の基準実装。構造変更はまずここから直し、他リポは追従する
- kawaz/authsock-warden: `docs/decisions/INDEX.md`、`docs/research/`、DR の書き方
- kawaz/kuu.mbt: 50+ DR の運用、`decisions/archive/` への退避、`research/` への降格、INDEX.md の Active / Archived / Moved to research 3 区分
- kawaz/zunsystem の業務リポジトリ: `docs/journal/` 運用、`docs/todo/`、`docs/references/`
- kawaz/idea-storage: `docs/issue/` 運用検討
