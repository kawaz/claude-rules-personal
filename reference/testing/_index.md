# テストの参照知識

2 つの入口がある。**テストを設計する / 追加する / レビューする**なら網羅観点とコメント様式を、**落ちているテストに手を入れる**なら対処手順と説明責任を読む。テスト改変で green を作らない禁則そのものは `for-all/rules/test-integrity.md` が正本。

## 設計する

- [test-coverage-checklist](test-coverage-checklist.md) — RED 段階の網羅観点 (境界 / エッジ / デシジョンテーブル / 同値分割 / 状態遷移 / 並行性 / 回帰)、観点 × 実行場所の表、書かない・削る判断、やりがちな失敗。
  発火語: テスト設計, TDD, RED, 境界値, 同値分割, デシジョンテーブル, 状態遷移テスト, カバレッジ, テストを削る
- [test-as-spec-comments](test-as-spec-comments.md) — テストを真の仕様書にするコメント様式、DR 参照の書き方、self-contained にする portability の根拠。
  発火語: テストコメント, 動く仕様書, DR をテストに書く, テストだけで再現, 言語移植

## 失敗に対処する

- [flaky-accountability](flaky-accountability.md) — 偽 green の具体形、失敗時に踏む順序、flaky 認定で埋める 5 項目と NG/OK 例、timeout 延長を正当化する条件、`#[ignore]` の書式。
  発火語: テストが落ちる, flaky, たまに失敗する, 環境依存, timing 問題, timeout を伸ばす, ignore 化, 偽 green
