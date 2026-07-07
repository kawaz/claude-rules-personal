# rules の禁則/手順書分割と常時ロード diet (claude.ai セッション由来)

X の /fable skill POST 由来のギャップ分析 (orchestrate skill 導入) に続き、
ルール群全体 (55 md) を横断監査した結果の一括改修。適用は overlay zip の
マージで行い、close 判定・issue 遷移は kawaz がローカルでレビュー後に行う。

## 横断診断

個別ファイルの重さの根因は「**禁則 (毎ターン効く行動制約) と手順書 (特定
作業時のみ必要な知識) の同居**」。この2分類を [[rule-writing-guidelines]] に
正本化し、同居ファイルを機械的に分割した。常時ロード実測:
**128,095 → 114,689 bytes** (今回分のみ。既 issue の tdd 降格等を除く)。

## 変更一覧

| 対象 | 処置 |
|---|---|
| rule-writing-guidelines | 全面改訂: 2分類原則 / リンク規約 / lint 正本 (push-workflow から移設) / 「該当なし」明示の文書種別優先順位 |
| claude-config-dir-isolation | 禁則に圧縮 (5.3K→1.5K)。越境手順は既存 cross-env-ssh-signing skill へ参照。overlay 一覧表は repos_mapping.json 正本化で削除 |
| push-workflow | 禁則に圧縮 (6.5K→1.9K)。watch 運用 → 新 push-watch skill。lint 節 → rule-writing-guidelines |
| git-workflow | 丸ごと git-worktree-workflow skill へ移動 (jj-workflow が skill である非対称の解消)。元 rule 削除 |
| release-flow-awareness | 禁則に圧縮 (2.8K→1.0K)。標準ループ / 読む観点 / 書き換え提案 → 新 release-flow skill |
| sloppy-ai-patterns | 二層化: 常時側は症状+自警 (6.7K→2.5K)、代替表・例外 → 同名 skill。今後のパターン追加は常時 ~10行/件で済む構造に |
| bash-tool-tips + benchmark-tools + ask-user-question | tooling-tips に統合 (3→1) |
| say-command-katakana + 1password-error-notification | notification-tips に統合 (2→1)。kawaz-identity / gh-image-attach の参照更新済み |
| design-thinking | 「思考設定」節に正本マーク追記 (claude.ai userPreferences と同文の二重管理を検出、drift 時は rule 側が正) |
| empirical-verification | 対極節 (ROI gate) 追加 — 1 サンプルで足りる条件 / 検証省略時の「未検証」明記。mizchi formal-methods-playbook の取り込み候補の着地 |
| design-priority | 対極節 (スコープアンカー) 追加 — 「全体を直す」と orchestrate Phase 0 アンカーの調停。質は曲げない / 範囲は絞れる |
| no-historical-noise / tdd-and-test-design | 「除外リスト禁止」vs「該当なし明示」の文書種別切り分けを相互参照で明文化 |
| orchestrate skill + A/B 検証 issue | 前回 zip 分を同梱 (INDEX 行追加込み) |

## ハマり所 / 検出事項

- **justfile 冒頭コメントが実態と乖離**: 「lint / test / build / version は
  持たない」と書いてあるが `lint-rules` は実在する (L49)。コメント側の
  修正候補 (今回は justfile 未変更)
- 統合で slug が変わる参照は 3 箇所 (kawaz-identity / gh-image-attach /
  jj-workflow)。lint-rules は for-all→for-me 越境しか見ないため、
  **slug 改名時の dead link は lint の死角** — lint 拡張の検討余地
- lint 相当 (越境 / 自己参照 / .draft- / 5KB) はコンテナ内で再現実行し
  fatal 0 を確認。**実機の `just lint-rules` / setup.sh symlink 再配置は
  未検証** (claude.ai コンテナに just / rg / 実環境なし)

## 残 5KB 超 (意図的に残置)

synthesis-temptation-guard (5.2K) / tdd-and-test-design (13K, 既 issue で
降格候補) / test-failure-no-tampering (7.3K) / docs-knowledge-flow (6.2K)。
メタ認知・品質系は毎ターンの判断に効くため層として残す判断 (削るのは量で
あって層ではない)。
