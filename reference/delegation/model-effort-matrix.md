# worker 選定 — model × effort マトリクスと委譲規約

サブエージェント (worker) 委譲時のモデル選択と、委譲プロンプトに必ず入れる運用規約。入力量の見積りは reference の `delegation/context-budget`。

## 自 tier 判定と分担原則

自 tier は system prompt のモデル名で判定する (`claude-fable-*` = 最上位、`claude-opus-*` / `claude-sonnet-*` = 中位)。判定不能時は中位 tier 扱い。

- 最上位 tier メイン時: 実作業はサブエージェントへ。メイン直は `work-principles` rule の「メインが直接行ってよい作業」に限る
- 中位 tier メイン時: 委譲のほうがコストが大きい場面 (1 ファイル定型修正 / 数行変更 / 起動説明が作業量を上回る) はメイン直で OK

迷ったら委譲する。

## 禁則

- 品質判定 (レビュー・監査) を自分より劣る tier に委譲しない。見逃す側に判定させることになる
- Agent tool の `model` パラメータで agent 定義を上書きしない。別名 enum は `[1m]` 付き ID を渡せず window が狭まる。model・effort の制御点は agent 定義 frontmatter だけ
- `model` 未指定の agent を起動しない。メインのモデルを継承して最上位 tier で実作業が走る

## 選定の第一原則: 作業種別でなく難易度で選ぶ

「設計だから fable / 実装だから sol」の固定マッピングを禁止。同じ「指示書作成」でも裁定済み方針の手順化なら opus 級、未裁定の意味論設計なら最上位 tier。同じ「検査」でも差分照合・網羅走査なら opus-high / sonnet-high、意味論の穴探しだけ最上位 tier。選定前に「このタスクの難しい部分は何か」を 1 文で言えなければ中身を見ていない。

## agent 名と prefix 規約

agent 名は `<model><effort>-worker[-用途]` (例: `sonnet-worker-medium`)。表中は `sonnet-medium` と略記する。Agent tool の `subagent_type` には `rules-personal:` を付ける (例: `rules-personal:sonnet-worker-medium`)。

agent 定義は `agents/` 配下 (臨時作成のものは description に「常用しない」と明記)。`nitpick-reviewer` は model/effort が `fable-high` と同じだが独自の指示文 (12 の絶対ルール・15 のペルソナ) を持つので別物。独自の指示文を持つ agent は使用実績だけで削らない。

## 課題の性質 × 選択

| 課題の性質 | 選択 |
|---|---|
| 機械的・定型 (整形・一括リネーム・転写・記録・journal) | sonnet-low |
| 方針確定済みの単一課題実装 (受け入れ条件が明文化できる) | sonnet-medium |
| 定型調査・棚卸し (読み取り専用、小粒度に分割済み) | sonnet-medium / Explore |
| プランが確定済みの本実装・自走実行 (指示書が書けている) | codex-sol |
| 不具合調査・デバッグ・原因の再現追跡 | codex-sol |
| 長時間エージェント自走・terminal/GUI 操作・Web リサーチ | codex-sol |
| 複雑課題が複数直列 / ルール遵守が critical / 手戻り高コスト | opus-medium / codex-sol (sonnet 不可) |
| 設計自由度が残る実装・探索的調査・指示が曖昧になりうる作業 | opus-medium |
| 検証設計・原因分析・機械確認系レビュー・worker 成果の検査 | opus-high |
| 複雑な PR 作成・実務文書・長文脈整合が要る統合作業 | opus 系 |
| 本気レビュー・設計監査 (意味論の穴探し) | fable-high / 別系統の二次意見は codex-sol-reviewer |
| 穴探しを安く数で当てる (多系統レビューの 1 系統) | codex-luna-reviewer-xhigh |
| 粗探し特化のレビュー | nitpick-reviewer |
| 指揮・タスク分解・統合 (メイン) | fable (通常 medium / 大型タスクは high) |

## 判定の分岐

- 第一分岐は「何をやればいいか分かっているか」。分かっていない (要件・設計から考える) なら claude 系、分かっている (指示書がある) なら codex も対等以上
- 第二分岐は「複雑課題が直列に複数あるか」。あるなら sonnet を外す (effort を上げても解消しない)
- 難問・検証必須タスクを codex/opus に出す時は effort high 以上 (medium は検証を省いて誤答する)
- codex を「不安定」を理由に避けるのは、実測の裏付けが無い限りバイアス
- 同じ agent で effort だけ一時的に変える手段は無い。必要なら新規 agent 定義を作る

## モデル特性差

- sonnet: effort を上げれば opus 級の問題も解けるが、解法が素朴で大量トークン消費によりコストが逆転しうる。複雑な課題が複数直列に絡むとルール・指示を無視して手抜きでゴールに向かう。指示の質に品質がそのまま比例する
- opus: 高精度推論・複雑な設計判断・エラーコストが高い判断向き。曖昧・矛盾した指示を自力で妥当に解消できる
- fable: opus より広く複雑な判断と視野を持ち、指揮は fable-medium が opus-high/xhigh より遥かに良い。遅い。コードを直接書かせるより、要件壁打ち・プラン・codex への指示書き・成果のブレ検査に回す方が強い
- codex (sol): 不具合調査・長時間自走・terminal/GUI 操作・Web リサーチ・コスト効率。claude 系は複雑な PR 作成・実務文書・長文脈整合・検証の厚さ (指示なしでも独立実装クロスチェックを自発的に行う)
- 「claude 系が指示書 → codex が実装 → claude 系がブレ検査」の 3 段編成は難所を含む大型作業の現実解であって常用テンプレではない。1 worker 直行で足りるなら分けない
- gpt 系の使い分け: 軽作業は luna、高度は sol か astra。luna は xhigh にすると穴探しなどで上位 tier と並ぶ成果を出すことが多い (深く考えるのと同程度に試行量が効く)。astra は sol の 2 倍コスト、未実測
- effort の効き方: sol / opus は medium だと検証を省いて誤答しうる。fable は medium でも検証が厚い
- 公開ベンチ数値は自己測定・ゲーミング指摘ありなので、数値でなく役割構図で選ぶ

## agent 定義の固定方針

- claude 系はモデル ID の後ろに必ず `[1m]` を付ける (例 `opus[1m]`)。haiku は非対応なので付けない。理由: 200k 超過に課金ペナルティは無く、途中で「Prompt is too long」死する損失の方が大きい
- effort は全 agent 定義で明示する。未指定はメインの effort を継承して不定になる

## 委譲プロンプトに必ず入れる規約

- 完了報告は直前に fresh なテスト/検証を実行し、その実出力をそのまま貼る。変更ファイル一覧も `jj status` / `git status` の実出力から作る
- 指示と仕様 (または実物) が矛盾すると気づいたら、黙って進めず矛盾を報告してから進む
- 新型追加・API 変更は事前相談
- コミット可否・書き込み範囲・検証コマンドを明示する

## 監査側 (自分) の禁則

- 報告と実物の乖離を見つけたら、まずメッセージ交錯で説明できないか確認してから worker の帰責を判断する
- worker が idle 表示でも未処理の受信指示が残っていれば潜在 writer。同一 workspace でコミットする前に最終指示への ack を取る
