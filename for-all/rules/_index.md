# for-all ルールのフェーズ別 index

同じルールが複数フェーズに出るのは正常 (多重所属)。判断の中身は各本体を見る。

## 設計

着手前 — 判断基準 (意思決定の入力):

- [[design-priority]] — 案を選ぶとき、コストを理由に質を曲げないため
- [[design-thinking]] — 構造・フィールド・型を足すか迷ったとき

判断後 — 自己点検 (出力の検証):

- [[default-convergence-guard]] — 書いた実装が手癖のデフォルトでないか
- [[self-written-rule-blind-spots]] — 決めた規約・check の対極が漏れていないか

その他:

- [[synthesis-temptation-guard]] — 複数案を比較して「ハイブリッド」を書きたくなったとき
- [[design-impl-bidirectional-check]] — 設計文書と実装の整合を取るとき
- [[interface-wording]] — API・CLI・エラー・UI の文言を決めるとき
- [[cli-design-preferences]] — CLI のサブコマンド・オプション・補完を設計するとき

## 実装

- [[sloppy-ai-patterns]] — sleep / polling 等で症状に蓋をしかけたとき
- [[retreat-is-last-resort]] — 機能削除・仕様の限界として諦めたくなったとき
- [[empirical-verification]] — 挙動を根拠にするとき (推測でなく実機で)
- [[spec-careful-reading]] — POSIX / RFC / API doc を判断根拠にするとき
- [[document-design-rationale]] — ベストプラクティスから外れる実装を書くとき
- [[no-historical-noise]] — 変更経緯をコード・docs に書きたくなったとき
- [[tooling-tips]] — 別ディレクトリでコマンドを実行するとき
- [[secret-hygiene]] — TOKEN / KEY / .env 等を扱うとき

## コミット・プッシュ

- [[sanitize-work-identifiers]] — 業務固有名詞が成果物に混ざっていないか
- [[sanitize-local-paths]] — `/Users/kawaz` 等の絶対パスが残っていないか
- [[secret-hygiene]] — 機微情報が diff・log に乗っていないか
- [[no-historical-noise]] — 跡地コメント・過去仕様言及が残っていないか
- [[public-repo-contribution]] — 公共リポへ PR / publish するとき

## CI・リリース

- [[notification-tips]] — `say` 通知・1Password エラーに遭ったとき
- [[empirical-verification]] — 失敗を「たぶんこう」で片付けそうなとき
- [[public-repo-contribution]] — 公共パッケージリポへ publish するとき

## レビュー

- [[feedback-evaluation]] — ユーザの意見・提案を取り入れる前の賛否表明
- [[discussion-style]] — 議論レーンでの応答 (畳まない / 走らない)
- [[report-and-decomposition-form]] — 状況・原因・複数案を報告する形
- [[no-excessive-apology]] — 指摘・「なんで?」を受けたとき
- [[design-impl-bidirectional-check]] — 「設計済み = 実装済み」と推定しないため
- [[self-written-rule-blind-spots]] — check list の片面性を疑うため

## 運用・インフラ

- [[claude-config-dir-isolation]] — `~/.claude` 汚染対策・別環境のリポを触るとき
- [[tooling-tips]] — direnv・ベンチマーク等の実行環境まわり
- [[secret-hygiene]] — credential の受け渡し経路を決めるとき
- [[notification-tips]] — 音声通知・不在時のふるまい

## メタ (ルール・docs 運用そのもの)

- [[work-principles]] — 全フェーズ横断の作業原則 (指示遵守 / TODO / 委譲)
- [[rule-writing-guidelines]] — rule / skill を書く・改廃するとき
- [[research-documentation]] — 調査・検証結果を記録するとき
- [[no-historical-noise]] — docs に history narrative を書きたくなったとき
- [[self-written-rule-blind-spots]] — ルールを起草した直後
- [[kawaz-identity]] — 対外文書で kawaz を表記するとき
