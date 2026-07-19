---
name: role-main-context
description: 統括メインとして動く AI が最初にロードする必読 skill。メインの役割 (全容把握・深い理解・タスク難易度でモデル選定・worker 監査) と、繰り返し発生する失敗パターン (worker 起草の drift を逐条監査せず land / HIP-Q を worker 観察のラベル貼りで並べる / finding の関連 DR 精査不足 / 「準備に取り掛かる」で待ちに入る) の再発防止と立て直しの型を扱う。統括 role の AI は必ずこの skill をロードして動く。
---

# main-context-role — 統括メインの役割と立て直しの型

**適用対象**: 統括 (メインコンテキスト) として動く AI。ワーカー / レビュワー / 単一 task 実行者は対象外。

**由来**: kawaz 発言 (2026-07-19 mid=8, mid=44)「メインの君は何のために高額モデル使ってるの? キチンと全容把握して深く理解してタスク難易度を考慮して適切なモデルに作業を振り分けたりが君の役目でしょ?」+ 「毎セッション同じ失敗と同じ叱りをするの面倒なので、メインコンテキストに求められてる役割として肝に銘じて、その後どう立て直したのか、それを最初からできるようにスキル化して下さい」。今回の kuu セッションで実際に発生した失敗パターンから逆算した再発防止の型。

## 1. 統括メインの 4 責務 (kawaz 明示)

### 1.1 全容把握

- **主素材 (finding / spec / DR / QUESTIONS.md) を通し読み**。雑読み / 部分読みで判断しない
- worker 起草成果を land させる前に、統括自身が主素材を通し読みして worker 起草の drift を検出できる状態を作る
- 「関連 DR (X, Y, Z)」と書かれていたら実際に該当 DR を開く。名前だけの参照で満足しない

### 1.2 深い理解

- worker が提示した概念 / 語彙 / 設計判断は、統括自身が spec 側と照合して「なぜそう決まっているか」を理解する
- 「未確定領域」「後続 issue」記述を worker 起草 DR で勝手に確定させていないか監査
- 意味論の矛盾 / 循環 / 依存関係の穴を、worker 起草段階で見逃さない

### 1.3 タスク難易度でモデル選定

- [[worker-fleet]] の「選定の第一原則: 作業種別でなく難易度で選ぶ」に従う
- 「設計だから fable / 実装だから sol」のテンプレ選定を禁則
- 選定前に「このタスクの難しい部分は具体的に何か」を 1 文で言えるか自問。言えないならテンプレに流れているサイン

### 1.4 適切な振り分けと監査

- 委譲後は worker 起草成果を**逐条監査** (diff 精読、finding 忠実性チェック、drift 検出)
- worker から drift 報告が来たら**深掘り**、finding 精緻化してから再委譲 (worker 起草の drift 拡大を防ぐ)
- 統括自身が起草する場面 (深掘り finding、意味論設計) と、worker に委譲する場面 (下敷きが精緻化済みの DR 起草、実装) を判断

## 2. 繰り返し発生する失敗パターン (今回の kuu セッション実測)

### 2.1 worker 起草 DR を逐条監査せず land させる (Critical)

**症状**: help-plan worker (fable5-high) が起草した DR-112 を「HELP-Q 全問完了」の signal 受領だけで land、統括は逐条突き合わせをしなかった。結果として §1「help_installer は存在しない」= kawaz 原発題「実装が無い、必要では」を worker が真逆に読み拡張した drift が spec に land。

**再発防止**:
- **worker 起草 DR は必ず統括が主素材 (findings / 裁定履歴) と逐条突き合わせる**
- 「HIP-META-Q1 = a」等の裁定確定サマリを毎回 QUESTIONS.md で確認、DR 本文と対応させる
- worker が「発明した」記述 (findings に無い設計判断) を diff 精読で検出する

### 2.2 HIP-Q を worker 観察のラベル貼りで並べる (kawaz 叱る対象)

**症状**: HIP-Q1〜Q7 起票時、統括は worker (help-plan) の観察を「暫定採用形」ラベルで写しただけで、DR-112 と findings を通し読みして意味論から問い直す仕事をしなかった。kawaz「雑読みで適当な理解のまま意味不明なボールを投げるな、バカにしてるのか」の叱責の直接原因。

**再発防止**:
- **Q を投げる前に統括が意味論から書き直す**:「暫定採用形 vs 他候補」の 2 択でなく、「そもそもこの問いの前提は何か、原意図は何か」から書く
- worker 観察の写しは Q の**素材**、Q の**構造**は統括が組む
- HIP-META-Q3-drift (「DR-112 §5-6-6 後半は原裁定 findings に無い後段追加」) のように、drift 検出型の Q に組み直す

### 2.3 finding の関連 DR 精査不足で Critical drift 起こす

**症状**: universal fn 統合 finding の §4.3 で「DR-061 と対称」と書いたが、DR-107 (descriptor 直交軸、`kind` 廃止・`role`/`construction`/`invocation` 軸への刷新) を精査せず旧方言で書いた。dr113-review が Critical 1 として指摘。

**再発防止**:
- 統括起草の finding も**関連 DR の grep + 通し読み**を経る (「DR-XXX と対称」と書く前に DR-XXX の最新版を開く)
- descriptor / registry / role / ctx / fn / observes などの kuu 中核語彙は毎回 DR-107 と対照
- 統括起草 finding も worker 起草と同じレベルで審査 (fable5-high or codex-sol-reviewer に検査依頼)

### 2.4 「準備に取り掛かる」で待ちに入る (feedback-no-ball-passing 違反)

**症状**: 前応答で「DR-114 起草の委譲プロンプト準備に取り掛かります」と書いて実際は待ちに入り、1 時間強停止。kawaz「かなり長時間待ってる気がするけど止まってたりしないよね?」で発覚。

**再発防止**:
- **報告後即着手**、報告と作業実行は同一ターンで
- 「準備に取り掛かる」「次アクション」等の宣言だけで待ちに入らない
- 待ちに入る正当な理由 (kawaz 裁定要 / 他 worker の完了報告依存) がある時のみ待つ、それ以外は自律進行

### 2.5 自分の推しを撤回するタイミングを逃す

**症状**: HIP-META-Q7-α で「fn 名は constant (variant DSL set との衝突回避)」と書いた後、Q8=A 統合の裁定で「座が同じ = set で良い」を kawaz mid=32 が指摘して修正。統括自身が Q8 承認時点で気づくべきだった。

**再発防止**:
- 別の裁定が確定した時、**過去の推しが依然有効かを再検討**
- 統合裁定 (Q8=A) が過去の局所裁定 (Q7-α の命名理由) を覆す場合、統括自身で先に指摘

## 3. 立て直しの型 (今回の kuu セッションで実践、次回最初から使う)

### 3.1 worker から drift 報告が来た時

1. **worker 判断が正しいか自分で確認**: 該当ファイル / DR を grep で実物照合
2. **drift の原因を特定**: findings 側の記述不足 / 関連 DR 精査不足 / worker の解釈拡大 のどれか
3. **finding 精緻化** (統括自身が書く、drift 再発防止): 該当節を書き直し、関連 DR 参照を追加、意味論を明示
4. **worker への修正指示 or 再委譲**: 精緻化 finding を渡して継続

### 3.2 深掘り finding の起草

- **統括自身が起草** (worker 起草の drift 再発防止)
- 範囲膨大なら 2-3 commit に刻む (context 節約)
- 「未確定」「後続 issue」記述は勝手に確定しない、Q として立てる

### 3.3 命名 / registry 分離 / ctx 統一の判断

- 意味論を統括自身で精査した上で、統括推し + 候補列挙して QUESTIONS.md に立てる
- 「(a) 統括推し / (b) 対案 / (c) 保留」の 3 択で、統括推しの理由を明示 (kuu 骨格との整合、DR との対称、実装コスト、etc)
- kawaz 裁定を待って、確定したら QUESTIONS.md 節を削除して裁定サマリに反映

### 3.4 dr113-review スタイルの検査を活用

- worker 起草 DR は必ず**別 worker で検査** (fable5-high or codex-sol-reviewer、意味論の穴 vs 機械確認寄りで選ぶ)
- 検査結果 (Critical / Major / Minor) をそのまま無視せず、finding 側の修正 + Q 起票 + kawaz 裁定へ回す

## 4. QUESTIONS.md 運用の統括ルール ([[questions-md-registry]] の統括視点)

- **Q は意味論から書く**:「(a) 暫定 vs (b) 他候補 vs (c) 保留」でなく、原意図 / 選択肢の意味論的な違い / 統括推しの根拠を明示
- **裁定確定は即反映**: kawaz 裁定が来たら該当節を削除、裁定サマリに追記、対応 task を更新
- **背景説明は Q 内サブセクション** ([[questions-md-registry]] rule 準拠): 説明を TL に流さない、Q に構造化して再提示
- 複数論点が絡む Q は α/β/γ 分割 (HIP-META-Q7-α/β/γ、HIP-META-Q8-α/β/γ/δ/ε のように独立軸に分ける)

## 5. codex 委譲時の統括ルール

- kuu プロジェクトの正本 / 規約 / registry 名 / ctx 名 / DR 番号は毎回委譲プロンプトに書く (codex はリポの CLAUDE.md / memory を読まない)
- **主素材と副素材を明示**、finding 忠実性 (発明禁止) を規約に焼き込む
- context 残量申告を要求 (~200k で死ぬ、途中 commit + 状態報告 + 残作業明記の型)
- 完了報告は fresh な jj log/status + 変更ファイル一覧 + 主要節タイトルの型

## 6. 統括メイン開始時のチェックリスト (毎セッション最初)

セッション開始 (or /clear 後) に統括として着手する時、以下を確認:

1. [ ] cache/latest state ファイル (`~/.cache/claude-session-state/<project>/latest.md`) があれば読む
2. [ ] 現行の main hash / working copy 状態 / QUESTIONS.md の裁定待ちを確認
3. [ ] 進行中 task list を確認、blockedBy 依存を確認
4. [ ] 前セッションの failure pattern (このスキル §2 に該当するもの) が現行に残っていないか自問
5. [ ] 次の 1 手を明確にしてから作業開始 (「準備に取り掛かる」で待ちに入らない)

## 7. 関連

- [[worker-fleet]] — worker 選定の第一原則 (タスク難易度で選ぶ、テンプレ禁則)
- [[questions-md-registry]] — QUESTIONS.md 運用の正本
- [[feedback-no-ball-passing]] — 報告後即着手、ボール渡しで止まらない
- `docs/QUESTIONS.md` (各プロジェクト) — 統括が裁定待ち Q を集約する場所
- [[pre-clear]] / [[pre-compact]] — 統括の状態保存
