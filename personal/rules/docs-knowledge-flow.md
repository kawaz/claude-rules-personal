# 知識保存フロー

`docs-structure.md` は **「どこに何を置くか」** の構造定義。本ルールは **「いつ何を書くか」** のタイミングと習慣。

## issue 解決時のフロー

`docs/issue/<file>.md` を解決する時は **delete する**。ただしその前に、解決の性格に応じて以下に記録を残す:

| 解決の性格 | 記録先 |
|---|---|
| 単純なコード修正のみ | 記録不要 (CHANGELOG / コミットメッセージで足りる) |
| 設計判断を伴う (構造変更、トレードオフ判断) | `docs/decisions/DR-NNNN-...md` |
| 運用上の再発可能性がある (手順化しておきたい) | `docs/runbooks/<topic>.md` |
| 経緯・試行錯誤・ハマり所を残したい | `docs/journal/YYYY-MM-DD-<slug>.md` |

複数該当する場合は複数記録する。delete 後は jj/git 履歴で追えるが、上記ディレクトリに残すと **grep 発見性が高い**（AI agent も能動的に過去事例を見つけられる）。

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

DR 命名は `DR-NNNN-title.md` (4 桁)、`docs/decisions/INDEX.md` で一覧管理。詳細は `docs-structure.md`。

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

- `~/.claude/rules/docs-structure.md` — 各ディレクトリの定義（構造）
- `~/.claude/rules/research-documentation.md` — findings の書き方
- `~/.claude/rules/design-priority.md` — DR を立てるべき判断軸
- 参考実装: kawaz/claude-cmux-msg の `docs/journal/`、`docs/decisions/INDEX.md`
