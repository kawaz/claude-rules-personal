# 知識保存フロー

`docs-structure` skill は **「どこに何を置くか」** の構造定義 + テンプレ embed。本ルールは **「いつ何を書くか」** のタイミングと習慣。

issue 運用は **[claude-local-issue plugin](https://github.com/kawaz/claude-local-issue)** が正本 (= write / read / update / list / migrate の 5 sub-command で frontmatter / INDEX / archive を一括管理)。本ルールは plugin が前提とする運用上の判断軸 (= 何を / どこへ昇華するか) を定める。plugin が扱う status / frontmatter / archive の仕組みは plugin 側 `SKILL.md` / `docs/DESIGN.md` を参照。

## issue 解決時のフロー

`docs/issue/<file>.md` の解決は **local-issue plugin の `update <slug> close` で行う** (= archive へ移動 + close_reason 記録、`status: resolved` 遷移)。close 前に、解決の性格に応じて以下に記録を残す:

| 解決の性格 | 記録先 |
|---|---|
| 単純なコード修正のみ | 記録不要 (CHANGELOG / コミットメッセージで足りる) |
| 設計判断を伴う (構造変更、トレードオフ判断) | `docs/decisions/DR-NNNN-...md` |
| 運用上の再発可能性がある (手順化しておきたい) | `docs/runbooks/<topic>.md` |
| 経緯・試行錯誤・ハマり所を残したい | `docs/journal/YYYY-MM-DD-<slug>.md` |

複数該当する場合は複数記録する。close 後の issue は `docs/issue/archive/` に物理移動し、frontmatter の全 timestamp + close_reason が DB として残る。`list` sub-command は archive を既定で除外するので、メインコンテキストからは「消えた」ように振る舞う一方、`grep -r docs/issue/archive/` で過去事例は探せる。

## issue 運用 (plugin が前提とする仕組み)

### `wip` 状態は `## TODO` を内包

仕掛中 issue file 内に進捗 checkbox:

```markdown
## TODO
- [x] 仕様確定
- [ ] 実装
- [ ] test
```

単一 issue 内で完結。`update <slug> status=wip` で `status: wip` + `wip_entered` が記録される。

### `docs/issue/INDEX.md` (= plugin が必須化)

plugin の write / update が自動更新する全体俯瞰インデックス。手で書かず、plugin の sub-command 経由で同期する。

### status 値 (= plugin の schema)

| status | 意味 |
|---|---|
| `idea` | アイデア、まだ actionable でない |
| `open` | 未着手 |
| `wip` | 仕掛中、本文に `## TODO` あり |
| `blocked` | 待ち (= frontmatter `blocked_by` に対象を記載) |
| `pending-sublimation` | 実装済、DR/journal/code に昇華して archive 待ち |
| `discarded` | 前提が消えた / 方針変更で着手しない (= 不採用、archive へ) |
| `resolved` | 解決済 (= archive へ) |

status を schema で固定する理由: 自由記述だと AI ごとに違う語彙を使い、grep / triage が壊れる。状態遷移はユーザ意図なので `update` sub-command 引数で明示的に渡す。

完了時の運用: sublimation → `update close` で `discarded` または `resolved` 遷移 + archive 自動移動 + INDEX 自動更新。「DR/journal に昇華 → file 削除」は不要 (plugin が archive 側に動かす)。

## 並列作業時の journal 習慣

Claude (AI agent) が non-stop モードや複数タスクを並列で進める場合、ユーザがチャットの生ログを追うのは時系列で混ざりすぎて辛い。**作業内容ごとに slug 単位で journal を書く** ことで状況復元しやすくする。

作業の節目で `docs/journal/YYYY-MM-DD-<slug>.md` に以下を記録:

- **ハマり所 → 解決策のペア**: 「X で詰まった、Y で解決」を明示
- **設定値・コマンド・変更点**: 後でコピペで再現できる粒度
- **議論の要点**: 結論だけでなく、なぜその結論になったかの経緯

`<slug>` は作業内容を表す短い名前（例: `nitpick-strengthening`、`broadcast-id-introduction`、`docs-structure-finalization`）。

**並列作業時は slug ごとに別ファイル**。複数の関心事が同じ日付に走っていても、ユーザが「あの作業の話」を slug で引ける。チャットログだと並列作業が時系列で交錯するが、slug 別ファイルなら関心事ごとに整理されて読める。

## DR (Decision Record) を立てるタイミング

「設計判断」が含まれる変更は、その判断を DR で残す:

- 複数の選択肢から 1 つを選んだ（なぜ他を選ばなかったかも含める）
- 後方互換やコスト判断を上回る「設計上の優位性」で方針を決めた（`design-priority.md` ルールに該当する判断）
- 過去の決定を覆す（`Superseded by DR-NNNN`）

軽微なリファクタや単純な bug fix は DR 不要（コミットメッセージで足りる）。

DR を立てる変更では、関連する設計書（`docs/DESIGN.md` 等）も同じ change 内で最新化する。不採用にした技術・選択肢は「なぜ使わないか」（API のスコープ差など）も DR に明記し、既存類似プロダクトを調査した場合はその結果も `research/` または `findings/` に残す（`research-documentation.md` 参照）。

DR 命名は `DR-NNNN-title.md` (4 桁)、`docs/decisions/INDEX.md` で一覧管理。詳細は `docs-structure` skill。

## runbook を立てるタイミング

「運用フェーズで再発しうる問題と対処手順」を runbook に残す。例:

- セットアップ時のハマり所と回避手順
- 障害時の切り分けと復旧コマンド
- 定期メンテナンス手順

journal で「同じ問題が複数回出てきた」と気づいたら runbook 化を検討する。journal は時系列の「物語」、runbook は手順の「整理済みレシピ」。

## findings を立てるタイミング

「単発の調査をしてその確定事実だけ残したい」場合に `docs/findings/YYYY-MM-DD-title.md`。journal が「経緯」中心、findings が「確定事実」中心、と棲み分け。

`research-documentation.md` ルールで findings の書き方が定義されているのでそちらに従う。

## 関連

- `docs-structure` skill — 各ディレクトリの定義（構造）+ テンプレ embed
- **kawaz/claude-local-issue** — issue 運用の正本 plugin (sub-command: write / read / update / list / migrate)。frontmatter / INDEX / archive の機械的詳細は plugin の `SKILL.md` / `docs/DESIGN.md`
- [[research-documentation]] — findings の書き方
- [[design-priority]] — DR を立てるべき判断軸
- 参考実装: kawaz/claude-cmux-msg の `docs/journal/`、`docs/decisions/INDEX.md`
