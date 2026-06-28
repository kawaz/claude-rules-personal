# テスト失敗時の改変による隠蔽は禁則

テストが fail したとき、**テスト側を「通る形」に書き換えて green に戻す**のは
**bug 隠蔽**で禁則。真因を直すか、`#[ignore]` で **明示的に skip + 理由 + 追跡
issue** を残す。

## 禁則パターン (= 絶対にやらない)

green にしたいがために以下をやらない。いずれもテスト改変による偽 green:

- **入力を書き換える** — 例: 単発 `echo X` → 継続出力 `while true; do echo X; done`
  に変えて pass させる。test の検証意図 (= 「単発出力時の挙動」) を破壊している
- **assert を緩める** — 例: `assert_eq!` → `assert!(actual.contains(...))`、
  `expect("...")` → `unwrap_or_default()`、 期待値を実測値で上書き
- **timeout / deadline を伸ばす だけ** — 真因調査せず「長くしたら通った」で済ます
  (例外: 真因が「runner load 不足」と観測根拠付きで特定された場合のみ)
- **環境変数 / cfg 分岐で暗黙 skip** — `#[cfg(not(ci))]` / `#[ignore_if = env]`
  等で「見かけ上 fail しない」ようにする
- **対象 test を削除** — 「うざいから消す」は test が表現していた仕様を消すこと

これらは「green に見せる」ことを優先して **失敗を可視化する機会を奪う**。後続の
セッション / 他人が「green だから動いてる」と誤信して bug が放置される。

## 正しい対応 (= 順序固定)

失敗 test に遭遇したら以下の順:

1. **真因を特定** — マトリクス検証 ([[empirical-verification]])、推測で結論しない。
   「flaky」と即断しない (= 真の flaky は最低 3 回反復で再現性確認後の判定)
2. **真因が直せるなら直す** — 本筋の bug fix が第一。test が表現する仕様を満たす
   実装に直す
3. **直せない / 別 PR にする場合** — 以下を全て満たす:
   - `#[ignore = "<理由 + 追跡 ref>"]` で明示的 skip (= grep 可能)
   - test 自体は **意図を保ったまま** (= 入力 / assert を一切変えない)
   - 追跡 issue / DR を起票し、`#[ignore]` 文言にその ref を含める
   - PR 説明 / commit message に「test を ignore に倒した、根治は <ref>」を書く
4. **green は「直った証拠」、`#[ignore]` skip 増は「直してない可視化」** — 両者を
   混同しない。test 改変で達成した green は green でない

## How to apply

- 失敗 test を見たら **最初に「test の意図は何か」を読み取る** (= comment /
  docstring / git log)
- 入力を変えたくなったら「test の意図を変えてないか」を **必ず自問**:
  - 例: 「単発出力 → 継続出力」は「**単発出力の場合の挙動**を検証する意図」を
    破壊している
- timeout 延長は **真因が完全に特定された前提** で行う (= 「runner load 不足」が
  観測根拠付きで言える、複数回計測で margin の妥当性を示せる、等)
- `#[ignore]` 増は許容、test 改変は禁則
- 「test が wrong だから直す」場合 (= 真に仕様変更で test の方が古い) は、test 改変
  ではなく **test の意図 (docstring) を新仕様に合わせて書き換える + assert もそれに
  合わせて変える**。改変前後で「何を検証してるか」を明示

## Why

- テスト改変による偽 green は **bug の可視化を奪う最悪の隠蔽**。`#[ignore]` skip は
  grep で「直してない場所」が一覧できるが、test 改変は痕跡が残らず最悪
- 後続のセッション / 他人が「green だから動いてる」と誤信して bug を放置する
- kawaz スタンス: **失敗の可視化 > green に見せかけ**。「green に見える」を優先する
  動機が出た瞬間、設計判断より隠蔽欲求が勝ってる兆候

## 関連

- [[tdd-and-test-design]] — テストは「動く仕様書」。改変は仕様改変
- [[empirical-verification]] — 真因特定の方法論 (= マトリクス検証、推測禁止)
- [[retreat-is-last-resort]] — 撤退判断は最後の手段 (= test 隠蔽は最悪の撤退)
- [[no-excessive-apology]] — 失敗を観察したら停止 + 報告、慌てた recovery 禁則
