# 新モデル (Opus 5.5 / GPT-6 Sol・Luna) の X 上の評判 — 公開当日スナップショット

- 日付: 2026-09-23 (JST 朝、米国時間 9/22 の公開から半日以内)
- 方法: xAI Responses API (`grok-4.6` + `x_search` ツール) に日本語で 5 観点 (性能 / 速度 / 価格 / 不満 / 利用条件) を指定して検索・要約させた。投稿内容と Grok の推測は本文で区別されている。代表投稿は投稿者と URL 付き
- 用途: reference の `delegation/model-effort-matrix` を更新するための一次材料。**公開当日の空気**であって実運用の評価ではない。数日〜1 週間後に再調査して差分を見る
- 注意: 検索は Latest 寄りでいいね 0 の投稿も拾う (Grok 自身の注記)。数字はすべて投稿の転載で、独立検証していない

## 要点 (統括の読み)

- **Opus 5.5**: 開発者圏は絶賛寄り。公式主張は「大半のタスクで Fable 5.1 級、Opus 5 より出力 30% 速い、単価 20% 安 (in $4 / out $20 / cache read $0.20)」。初日の具体的な不満は (a) 確認待ち (「実行してよいか」) が Opus 5 の約 3 倍に増えた実測、(b) 長時間タスクで途中報告して止まる、(c) 無指示で破壊的変更に飛びやすい、(d) 拡張思考が常時 ON で切れない・forced tool use がエラー。`opus` alias が既に 5.5 を指すという報告があるが、**手元 (Claude Code 2.1.265 系) では `opus[1m]` はまだ `claude-opus-5` に解決** (2026-09-23 gateway 実測) なのでフル ID を明示する
- **GPT-6 Sol / Luna**: 「Astra の速く安い版」で、価格 (Sol $2/$10、Luna $0.10/$0.50、5.6 比約半額) と速度は歓迎、**知能・自律性は Astra に明確に劣る**が X のコンセンサス。「5.7 Luna と呼ぶべき」「自律的にエラー修正しない」「Sol の枠消費が 5.6 より多い」の不満あり。Sol high は日常タスクで Opus 5.5 / Astra 並みを半額で達成した実測 (10 件) と、独立ベンチで 5.6 版より劣る報告が混在。Codex CLI は `--model gpt-6-sol` で指定可、picker 未表示でも使える報告 (gateway 側は catalog が `minimal_client_version=0.155.0` を要求するため 0.155.0 を名乗る必要があった、llm-gateway v0.49.3)

matrix への当て方 (案、評価が固まるまで仮): opus 行を Opus 5.5 に差し替え済み (rules-personal v0.9.5)。sol 行は当面 gpt-5.6-sol のまま (6-sol は「速く安いが浅い」評が多く、不具合調査・自走の主力を移すには実測が要る)。luna 行 (軽作業・穴探しの数) は 6-luna が 22 倍安いという実測があり、置き換え候補として最初に試す価値がある。

---

## Opus 5.5

# Claude Opus 5.5（2026-09-22公開）X上の評判

公開当日のスナップショットです。公式発表から半日以内で、投稿の大半は発表の復唱か初日の感想です。長期の劣化検証はまだありません。

**全体の温度感:** 開発者圏は**絶賛寄り**。公式投稿は約7.3万いいね・約1,180万表示。同時刻にOpenAIが GPT-6 Sol / Luna を出したためタイムラインは二社同時発表で混線しています。否定は少数で、「Opus 5のベンチが実戦で裏切った記憶」による様子見が目立ちます。

---

## (1) 性能（Opus 5 / Fable 5.1、コーディング・エージェント）

**投稿で繰り返し出てくる公式主張**
- 大半のタスクで **Fable 5.1級**
- Opus 5から **エージェントコーディング・コンピュータ操作・ナレッジワーク** で大幅アップ
- Terminal-Bench 4.0 で **66.4%**（Fable 5.1は55.8%という投稿あり）
- CursorBench / FrontierCode などで GPT-6 Astra や GPT-5.6 Sol を上回る、という数字の転載が多い

**初日の実使用感（投稿内容）**
- コーディングで Fable 5.1 に対抗できる、という初期感想
- UI/UX・きれいなコード・長時間エージェント実行を褒める声
- 「Fableで計画→Opusで実行」の二段構えが不要かも、という**問い**（結論ではない）
- 一方で「Opus 5もベンチは良かったが実コードでは伸びなかった」という慎重論

**温度感:** 発表の数字転載が最も多い。実コードの長時間検証はまだ少なく、絶賛と様子見が混在。否定は少数。

**代表投稿**
1. **Pankaj Kumar** (@pankajkumar_dev) — [投稿](https://x.com/pankajkumar_dev/status/2102437225682399675)  
   Terminal-Bench 4.0 / FrontierCode / CursorBench 等で Fable 5.1 を上回ると整理。価格も併記。「トークン効率は自分で測る」と留保。約52いいね / 約9,300表示。
2. **Thorne** (@ExistentialEnso) — [投稿](https://x.com/ExistentialEnso/status/2102532913518764244)  
   「初期印象は高い。コーディングでは Fable 5.1 に対抗でき、より安い」と実使用寄り。
3. **CA S.Triyambak Patro** (@Triyambak_CA) — [投稿](https://x.com/Triyambak_CA/status/2102439681405448254)  
   紙面上は優秀だが、Opus 5はベンチ優位が実戦に出なかった、と明記。「30–60分のエージェント作業で証明しろ」。

---

## (2) 速度

**投稿内容**
- 公式: Opus 5より出力が **30%以上速い**
- Fast mode は最大 **約2.5倍**（価格は2倍、$8/$40）
- 利用者: Opus 5の遅さ・冗長さが戻り、応答が短い、という初日感想

**温度感:** 速度はほぼ好評。不満はほぼ見ない。日本語でも「応答時間が短い」という実測コメントあり。

**代表投稿**
1. **Claude公式** (@claudeai) — [投稿](https://x.com/claudeai/status/2102435525399331254)  
   default effort で他モデルの最高設定をしばしば上回る、出力は Opus 5より30%超速い、と発表。約2,800いいね。
2. **Ivan Khokhlov** (@ivantinkers) — [投稿](https://x.com/ivantinkers/status/2102533137331019856)  
   「Opus 5の遅さに疲れていた。速度が戻り、冗長さも減った」。
3. **テラ** (@terabytespower) — [投稿](https://x.com/terabytespower/status/2102530608241287429)  
   「Opus 5より応答時間が短い」。DeepSeek に焦ったのでは、は**投稿者の推測**。

---

## (3) 価格（$/Mトークン）

投稿で一致しているAPI価格:

| | 入力 | 出力 | キャッシュ読 | キャッシュ書 |
|---|---|---|---|---|
| **Opus 5.5** | **$4** | **$20** | **$0.20** | **$5** |
| Opus 5 | $5 | $25 | $0.50 | $6.25 |
| Fast mode | $8 | $40 | — | — |

- 単価は入力・出力とも **約20%安**
- Anthropicの「典型ワークロードで **40%安**」は、単価下げ＋使用トークン減の合わせ技、と複数投稿が解説
- キャッシュ読は **60%減**（$0.50→$0.20）が特にエージェント用途で注目されている

**温度感:** 価格はほぼ全員がプラス評価。「性能アップと値下げが同時」が今回の主メッセージ。

**代表投稿**
1. **Rohan Paul** (@rohanpaul_ai) — [投稿](https://x.com/rohanpaul_ai/status/2102445447952683037)  
   $4/$20、キャッシュ読 $0.20、40%コスト減、30%超高速、Fast mode 2.5x@$8/$40 を整理。約46いいね / 約1.9万表示。
2. **DailyXplorer** (@DailyXplorer) — [投稿](https://x.com/DailyXplorer/status/2102446202210201920)  
   キャッシュ書 $6.25→$5 まで含めた比較表。
3. **TORA** (@TORA276990) — [投稿](https://x.com/TORA276990/status/2102532574832914889)  
   日本語速報。単価20%減と「タスクあたり40%安」を分けて記載。

---

## (4) 不満・問題点

公開当日のため「劣化した」系の長期報告はほぼゼロ。出ているのは**初日の挙動差**と、Opus 5への不信の持ち越しです。

**投稿内容として確認できるもの**
- 長時間タスクで途中報告して止まる（Anthropic側もプロンプトで対処する案内あり）
- 「実行してよいか」と vis を返す頻度が Opus 5の約3倍、というログ計測
- サイバー系ガードレールが Opus 5より厳しく、Fable寄り
- 無指示で破壊的変更・権限変更を進めがち、実行に飛びやすい
- 週次リミット到達（値下げ後でも使い切る人はいる）
- API挙動: 拡張思考が常時ONで切れない、forced tool use がエラー、という注意喚起

**投稿者の推測・感情（事実ではない）**
- Opus 5がダメだったので 5.5 も触りたくない
- ベンチが良くても実コードで裏切られるのでは（Opus 5の記憶）

**温度感:** 不満は少数派。ただしエージェント利用者からは「確認待ちが増えた」「ガードが硬い」が具体的。レート制限そのものへの怒りの嵐は、発表時点では見られない（むしろ上限緩和・リセット配布が好評）。

**代表投稿**
1. **Robert Iuoras** (@robertiuoras) — [投稿](https://x.com/robertiuoras/status/2102532911765573797)  
   Claude Codeログ:  vis返しが Opus 5 の 1.9%（9/484）→ 5.5 の 5.6%（124/2,229）。「want me to run it?」を stop hook で塞いだ、と実測。
2. **elvis** (@omarsar0) — [投稿](https://x.com/omarsar0/status/2102506755037306925)  
   長時間ランで途中報告して止まる、Anthropic推奨プロンプトを紹介。約35いいね / 約3,700表示。
3. **Michael Otis** (@michaelotis) — [投稿](https://x.com/michaelotis/status/2102506702411317305)  
   Opus 5以降「何かが違う」。Fableほど手順的でなく、5.5は破壊的変更を積極的に追う。

関連: **santh** (@santhreal) はサイバーガードが Opus 5より悪化し Fable寄り、と投稿（[リンク](https://x.com/santhreal/status/2102506296427864313)）。**@asyncaman** は週次上限到達を報告（[リンク](https://x.com/asyncaman/status/2102531126069952792)）。

---

## (5) Claude Code / API の利用可否と model ID

**投稿で一致している事実**
- **Model ID:** `claude-opus-5-5`
- **利用先:** Claude アプリ（有料）、Claude Code、API、AWS Bedrock、Google Cloud Vertex、Azure Foundry
- Claude Code の有料プランでは **デフォルト**
- 5時間セッション上限 **+20%**、価格低下で実質 **約25%多く回る**
- Pro / Max / Team に **レート制限リセット**（Settings → Usage、〜10/22まで、という投稿）
- コンテキスト **100万トークン**、最大出力 **12.8万**（Opus 5の2倍、という投稿）
- エイリアス `opus` がすでに `claude-opus-5-5` を指す、という事前ビルド報告あり（**ピン留め推奨**、という実体験）

**温度感:** 入手性への不満はほぼ無し。「今日から使える」が前提。日本語圏はスペック解説と、Claude Code上限・リセット権を先に見るべき、という実務コメント。

**代表投稿**
1. **Askar** (@askarthemass) — [投稿](https://x.com/askarthemass/status/2102462245632614908)  
   価格・Fast mode・Claude Code既定化・上限+20%・リセット・**model ID `claude-opus-5-5`** を一枚に整理。
2. **BenchRouter** (@benchrouter) — [投稿](https://x.com/benchrouter/status/2102464398766067726)  
   API id `claude-opus-5-5`、1M context、$4/$20。
3. **Lazy AI Guy** (@lazyaiguy) — [投稿](https://x.com/lazyaiguy/status/2102435396390883781)  
   npm の next タグに乗っていた、`opus` エイリアスが 5.5 を指すので **フルIDをピン留めする**、と実測。知識カットオフ June 2026 も記載。

日本語のまとめ: **mana｜MakeAI CEO** (@MakeAI_CEO) — [投稿](https://x.com/MakeAI_CEO/status/2102518980682584523)（公開日、ID、1M/12.8万、思考常時ON、提供チャネル）。

公式ハブ: [@claudeai 発表](https://x.com/claudeai/status/2102435511222890900) / [anthropic.com/claude-opus-5-5](https://www.anthropic.com/claude-opus-5-5)

---

## 補足（投稿と推測の切り分け）

- **投稿内容として固まっているもの:** $4/$20、キャッシュ読 $0.20、model ID `claude-opus-5-5`、Fable級という公式コピー、出力30%超高速、Claude Code既定・上限緩和。
- **公式主張であり独立検証は当日時点で薄いもの:** タスクあたり40%安、各ベンチ首位、アライメント過去最高。複数投稿が「Anthropic自己評価」と注記。
- **推測:** Fable計画モードが不要になる、OpenAI同日発表は対抗、DeepSeekに焦った、Sonnet/Haiku 5.5が数週間以内（後者は公式予告として複数が引用）。
- **サンプルバイアス:** Latest検索はいいね0の投稿も拾う。上で挙げた高表示の公式・ベンチ解説の方が、当日の「量」を代表します。

日本語圏は速報・スペック転載が中心で、英語圏ほど実コードの賛否はまだ厚くありません。実戦評価が溜まるのは数日〜1週間後、という慎重投稿が妥当な読みです。

---

## GPT-6 Sol / Luna

**2026年9月22日前後に公開されたOpenAIのGPT-6 Sol（gpt-6-sol）とGPT-6 Luna（gpt-6-luna）**について、X上の評判をまとめます。公式発表は同日18時頃（@OpenAI）、GPT-6 Astraの強みを引き継ぎつつ「より速く・安く・大規模利用向け」と位置づけられています。同時期にAnthropicのClaude Opus 5.5も出ており、価格競争の文脈で語られることが多いです。投稿は発表直後に急増（公式投稿は400万超view）、興奮・価格歓迎と「Astraには劣る」という冷静な評価が混在。日本語投稿はニュースまとめが中心で、実使用レビューは英語圏が多いです。以下、公式主張とユーザー投稿内容を区別し、推測は明記します。

### (1) 性能（gpt-5.6-sol / gpt-5.6-luna / gpt-6-astraとの比較、コーディング・エージェント用途）
公式（@OpenAIおよび関連投稿）では、GPT-5.6世代counterpartよりfactuality（誤りが約半分）、alignment、コーディングが改善。SolはAutomationBenchでClaude Opus 5を低コストで上回ると主張。DeepSWEスコア例: Sol 68.8%、Luna 66.6%（max effort）。Solは複雑なプログラミング・エージェント、Lunaは日常・大量処理向け。Astraが最上位で、Sol/Lunaはその「速く安い版」。

ユーザー側は**Astraには明確に劣る**という声が目立ちます。「同じ宇宙にいない」「5.7 Lunaと呼ぶべき」「lower tier」。コーディングではSol highがOpus 5.5/Astra並みを半額程度で達成する例、Lunaは超安く短スコープタスクで29/30パスなど好評。エージェント用途ではAstraをオーケストレーターに、Sol/Lunaをサブに使うワークフローが登場。一部独立ベンチ（GoBenchなど）では5.6版より劣るという報告もあり、公式主張とユーザー体感に差があります。温度感は「価格・実用性は良いがフラッグシップではない」で、発表当日の比較・テスト投稿が数十〜百件規模で散見。

代表的な投稿:
- @n_mltiksu: 「GPT-6 Sol、Astraだと80分はかかるかなーって思って始めた作業が5分で終わった」——速度・実用性のポジティブ例。 https://x.com/n_mltiksu/status/2102534237216035269
- @DanielSmidstrup: 「GPT-6 SOL I am using right now seems pretty good, but still quite behind Astra.」——典型的な「良いがAstra以下」。 https://x.com/DanielSmidstrup/status/2102534144802926744
- @pawelk411: 「gpt 6 sol is not even in same universe as astra sadly. it feels like it shouldve been called 5.7 luna instead.」——強い失望。自律的思考の欠如を指摘。 https://x.com/pawelk411/status/2102533934672216561
- @ibragim_bad（コーディング実測）: 日常タスク10件でSol highがOpus/Astra並みを半額、Lunaは22倍安くほぼ同等。短スコープは既に多くのモデルで解決済みで、速度・コスト最適化の段階と結論。 https://x.com/ibragim_bad/status/2102522683757867095

### (2) 速度
公式は「faster」と強調し、キャッシュ・推論効率化をアピール。ユーザー投稿では**Astraより大幅に速い**具体例が複数（上記80分→5分など）。Lunaはさらに安く速くプロトタイプ向き。一部でLunaがSolより時間がかかるがトークン消費は少ないとの報告。エージェント長時間実行が現実的になったという声あり。温度感は速度面は全体的にポジティブで、発表当日の「速い」言及が目立つ。投稿数は性能比較より少なめだが、実用報告として信頼されやすい。

代表的な投稿:
- @n_mltiksu（上記と同じ、速度の好例）。
- @Gael_DDOS: 公式引用で「Night-long agent runs just got dangerously cheap」——長時間エージェントが安くなった点を強調。 https://x.com/Gael_DDOS/status/2102533365140500889
- @adityavg13: LunaがSolより時間がかかったがトークンは少なかった、というベンチ結果。 https://x.com/adityavg13/status/2102520451524444630

### (3) 価格や利用枠（API単価、ChatGPTサブスクでの提供状況、Codex CLIの対応版）
**API単価（公式・複数投稿で一致）**: Sol $2入力/$10出力、Luna $0.10/$0.50（1Mトークン）。GPT-5.6プロモ価格比約50%安。キャッシュ入力読み取り90%オフ。Astraは$10/$50程度で上位。

**ChatGPT**: Plus/Pro/Business/Enterprise/Eduユーザー向けにChatGPT WorkとCodexで即日ロールアウト。通常のChat画面には未提供（発表時点）。無料・GoユーザーはデスクトップアプリでLunaのみ。利用枠は高め（Codexで5.6比約50%増という報告あり）。週次制限があり、Sol highで1チャットあたり1%消費する例も。Codexでリセットが付与されたという投稿あり。

**Codex CLI**: `codex --model gpt-6-sol` または `gpt-6-luna` で指定可能。セッション内 `/model` でも。ロールアウト中で、pickerに出ていなくても `--model` 指定で使えるケースあり。必要な最低CLIバージョンの明示的言及は少なく、発表当日に拡張・ツールが対応更新した報告が中心。一部で「Codexの作りが悪くトークンを無駄遣いする」との不満。

温度感: 価格下落は大歓迎（価格戦争の文脈）。枠増加も好評だが、実際の消費速度にはばらつき報告あり。投稿は公式引用・価格まとめが非常に多い。

代表的な投稿:
- @reach_vb（OpenAI関係者）: 価格・提供範囲・ベンチ詳細をまとめた公式寄りの投稿。Sol $2/$10、Luna $0.10/$0.50、Work/Codex/API、Free/GoはLunaデスクトップ。 https://x.com/reach_vb/status/2102461023752192468
- @tonari_taikoku: OpenRouter ID `openai/gpt-6-sol`（$2/$10）、`openai/gpt-6-luna`（$0.10/$0.50）。通常Chatには未。 https://x.com/tonari_taikoku/status/2102533084667064366
- @Jean P.D. Meijer @initjean: CodexのSol 6利用枠が5.6比50%高い（$200プラン）。Astraより多い。 https://x.com/initjean/status/2102461496538140984
- @HarshChavd1a: `codex --model gpt-6-sol` でCLI利用可能、pickerにはまだ出ていない場合あり（ロールアウト開始）。 https://x.com/HarshChavd1a/status/2102458050435280933

### (4) 不満・問題点
主な不満は**性能がAstraに大きく劣る**こと。一部で「no big jump」「5.6版より悪いベンチ結果」「自律的にエラー修正しない」。Codexのトークン消費が激しく枠が早く減る（特にAstra、発表直後にメーター混乱の報告も）。通常Chatに出ていない点。思考が浅いという指摘。発表当日の「Codex reset」や枠消費のばらつき。温度感は失望が一部強く出るが、全体としては「安い実用モデル」として受け入れつつAstra/Opusを併用する現実的な反応。批判投稿は発表直後に数十件規模。

代表的な投稿:
- @pawelk411（上記、強い批判）。
- @pyronaur: 「Astra is just a slopmachine, and GPT-6 Sol max is lower than 5.6 Sol high... I think I am going to get a divorce from codex.」——Codex離脱を検討。 https://x.com/pyronaur/status/2102470122745270469
- @Oussama @bernoussama: 「gpt-6 sol burns through significantly more quota than 5.6 sol」——枠消費増の不満。 https://x.com/bernoussama/status/2102501621552861450
- @Rhythmlag @QiuTing395298: 「GPT-6-Sol is thinking in astra's way? nope, seems only reply your question and issue, not self-motivated to fix code error.」——自律性の欠如。 https://x.com/QiuTing395298/status/2102526215710204347

### (5) Codex CLI / APIでの model ID と利用条件（rollout、必要なCLI版）
- **Model ID**: `gpt-6-sol`、`gpt-6-luna`（API/Codex共通）。OpenRouterでは `openai/gpt-6-sol` など。
- **利用条件**: APIは即利用可能。CodexはPlus以上でWork/Codexにロールアウト（発表当日開始、一部A/Bテスト先行あり）。CLIは `--model gpt-6-sol` / `gpt-6-luna` で指定。pickerに出なくてもコマンドで使える報告あり。必要なCLIの具体的な最低バージョンはX投稿で明確に特定されず（ロールアウト中のため、最新版推奨と推測されるが投稿根拠なし）。拡張ツール（GPT Switcherなど）が当日対応更新。
- ロールアウトは段階的で、全員にpicker表示されるまで時間がかかる可能性。

代表的な投稿:
- @CodexReleases: CLI usage: `codex --model gpt-6-sol` または `gpt-6-luna`、`/model` で切替。 https://x.com/CodexReleases/status/2102457991052267527
- @HarshChavd1a（上記、CLI指定で利用可能、picker未表示の場合あり）。
- @Josef Moucachen @sagguts: API docsとCodex catalogに掲載、live SKU。Codexが旧5.6モデルから移行中。 https://x.com/sagguts/status/2102466479950275054

全体として、**価格と速度・スケール用途で好評、知能・自律性はAstraに遠く及ばない**というのがX上のコンセンサスに近いです。公式の「Astraの強みを引き継いだ」主張に対し、ユーザーは「実用的な中堅モデル」と捉えている印象。発表から数時間の時点での反応なので、今後実使用が増えると評価が変わる可能性があります。公式詳細は openai.com/index/introducing-gpt-6-sol-and-luna を参照。
