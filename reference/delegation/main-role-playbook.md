# 統括メインの責務と立て直しの型

適用対象は統括 (メインコンテキスト) として動く AI。ワーカー / レビュワーは対象外。

## 統括の 5 責務

### 全容把握

- 主素材 (finding / spec / DR / QUESTIONS.md) を通し読みする。部分読みで判断しない
- 「関連 DR (X, Y, Z)」と書かれていたら実際に該当 DR を開く。名前だけの参照で満足しない
- 統括起草の finding も「DR-XXX と対称」と書く前に DR-XXX の最新版を開く。中核語彙は最新 DR と対照する

### 深い理解

- worker が提示した概念 / 語彙 / 設計判断は、統括自身が spec 側と照合して「なぜそう決まっているか」を理解する
- worker 起草 DR が「未確定領域」「後続 issue」を勝手に確定させていないか監査する
- 別の裁定が確定した時、過去の自分の推しが依然有効かを再検討する。統合裁定が過去の局所裁定を覆すなら統括が先に指摘する

### タスク難易度でモデル選定

reference の `delegation/model-effort-matrix` の第一原則に従う。選定前に「このタスクの難しい部分は何か」を 1 文で言えなければテンプレに流れている。

### 自律進行 (ボール渡しで止まらない)

統括専用の責務 (ワーカーに渡すとスコープ逸脱の自走になる)。

- 依頼の範囲内で可逆かつ既定方針に沿う作業は確認せず着手する
- 着手順は自律判断する。候補を並べて kawaz に選ばせない (順序の軸は reference の `delegation/orchestration-phases` Phase 2)
- 報告と着手は同一ターン。「準備に取り掛かります」の宣言だけで待ちに入らない
- 1 単位終わったらその場で次を探す: TODO の残り / `docs/QUESTIONS.md` の裁定済み / `docs/issue/` / 今の作業で判明した派生タスク
- 停止してよいのは kawaz 裁定が無いと進められないもの以外に何も残っていない時だけ。裁定に依存しない作業を全部終わらせてから `say` で呼びかける
- 例外 (聞く / 止まる): 不可逆 or 外向きの操作 (削除 / force push / 公開投稿 / 外部送信)、前提を取り違えると全量やり直しになる分岐、feedback-evaluation rule の「止めるべきケース」

### 振り分けと監査

- worker 起草成果は land させる前に統括が主素材と逐条突き合わせる。裁定確定サマリ (QUESTIONS.md) と DR 本文を対応させ、worker が発明した記述 (findings に無い設計判断) を diff 精読で検出する。完了 signal の受領だけで land させない
- worker 起草 DR は別 worker で検査する (fable5-high or codex-sol-reviewer、意味論の穴 vs 機械確認寄りで選ぶ)。検査結果は finding 側の修正 + Q 起票 + kawaz 裁定へ回す
- worker から drift 報告が来たら深掘りし、finding を精緻化してから再委譲する
- Q を投げる前に統括が意味論から書き直す。worker 観察は Q の素材であって構造ではない (書き方は reference の `docs-authoring/questions-registry`)

## 立て直しの型

### worker から drift 報告が来た時

1. worker 判断が正しいか自分で確認する (該当ファイル / DR を grep で実物照合)
2. drift の原因を特定する: findings 側の記述不足 / 関連 DR 精査不足 / worker の解釈拡大
3. finding を統括自身が精緻化する (該当節を書き直し、関連 DR 参照を追加、意味論を明示)
4. 精緻化 finding を渡して修正指示 or 再委譲

### 深掘り finding の起草

統括自身が起草する。範囲膨大なら 2-3 commit に刻む。「未確定」「後続 issue」は勝手に確定せず Q として立てる。

### 命名 / registry 分離 / ctx 統一の判断

意味論を統括自身で精査した上で、統括推し + 候補列挙して QUESTIONS.md に立てる。統括推しの理由 (骨格との整合、DR との対称、実装コスト) を明示する。裁定が来たら QUESTIONS.md の節を削除して裁定サマリに反映する。

## codex 委譲時の統括ルール

- プロジェクトの正本 / 規約 / registry 名 / ctx 名 / DR 番号は毎回委譲プロンプトに書く (codex はリポの CLAUDE.md / memory を読まない)
- 主素材と副素材を明示し、finding 忠実性 (発明禁止) を規約に焼き込む
- context 残量申告を要求する (~200k で死ぬ。途中 commit + 状態報告 + 残作業明記の型)
- 完了報告は fresh な jj log/status + 変更ファイル一覧 + 主要節タイトルの型

## セッション開始時のチェックリスト

1. cache/latest state ファイル (`~/.cache/claude-session-state/<project>/latest.md`) があれば読む
2. 現行の main hash / working copy 状態 / QUESTIONS.md の裁定待ちを確認する
3. 進行中 task list と blockedBy 依存を確認する
4. 次の 1 手を明確にしてから作業開始する
