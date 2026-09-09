# 失敗テストへの対処手順と flaky 認定の説明責任

テスト改変で green を作らない禁則そのものは `for-all/rules/test-integrity.md` が正本。ここは **その禁則に触れる具体形**、**失敗時に踏む順序**、**flaky と呼ぶ / timeout を伸ばすときに埋めるべき項目** を扱う。

## 偽 green の具体形 (= 見分けるための一覧)

green にしたいがために以下をやらない。いずれもテスト改変による偽 green:

- **入力を書き換える** — 例: 単発 `echo X` → 継続出力 `while true; do echo X; done` に変えて pass させる。test の検証意図 (= 「単発出力時の挙動」) を破壊している
- **assert を緩める** — 例: `assert_eq!` → `assert!(actual.contains(...))`、`expect("...")` → `unwrap_or_default()`、期待値を実測値で上書き
- **timeout / deadline を伸ばす だけ** — 真因調査せず「長くしたら通った」で済ます (例外: 真因が「runner load 不足」と観測根拠付きで特定された場合のみ、下記「timeout 延長」参照)
- **環境変数 / cfg 分岐で暗黙 skip** — `#[cfg(not(ci))]` / `#[ignore_if = env]` 等で「見かけ上 fail しない」ようにする
- **対象 test を削除** — 「うざいから消す」は test が表現していた仕様を消すこと

## 正しい対応 (= 順序固定)

失敗 test に遭遇したら以下の順:

1. **test の意図を読み取る** — comment / docstring / git log から「何を検証しているか」を先に確定する
2. **真因を特定** — マトリクス検証 (`for-all/rules/empirical-verification.md`)、推測で結論しない
3. **真因が直せるなら直す** — 本筋の bug fix が第一。test が表現する仕様を満たす実装に直す
4. **直せない / 別 PR にする場合** — 以下を全て満たす:
   - `#[ignore = "<理由 + 追跡 ref>"]` で明示的 skip (= grep 可能)
   - test 自体は **意図を保ったまま** (= 入力 / assert を一切変えない)
   - 追跡 issue / DR を起票し、`#[ignore]` 文言にその ref を含める
   - PR 説明 / commit message に「test を ignore に倒した、根治は <ref>」を書く

入力を変えたくなったら「test の意図を変えてないか」を必ず自問する (例: 「単発出力 → 継続出力」は「**単発出力の場合の挙動**を検証する意図」を破壊している)。

**test の方が古い場合** (= 真に仕様変更が起きていて test が旧仕様を表現している) は、改変ではなく **test の意図 (docstring) を新仕様に合わせて書き換える + assert もそれに合わせて変える**。改変前後で「何を検証しているか」を明示する。

## flaky と判断するなら、最低限以下を全て埋める

「3 回反復したから flaky 認定」のような **機械的閾値ルールを使わない**。代わりに以下の観点で説明できるまで調査を続ける:

- **不安定さの軸**: 何が不安定か (= 実行時刻 / 実行順序 / runner host / network / 共有 fixture / 他 test との干渉 / 外部 API 状態 / リソース枯渇 / OS scheduler 等)。「不明」は不可
- **再現条件**: どういう条件で再現する / しないか。「ランダム」は説明不足、ランダムに見えるなら **観測不足** (= seed / 時刻 / 環境変数 / 並列度のどれかに依存)
- **真因仮説**: 上記軸のどれが原因か仮説を立てる。複数候補なら **優先順位 + 各々を否定する観測方法**
- **即直せない理由**: 設計変更を要するのか、external 依存なのか、コストが高いのか
- **追跡 issue**: 仮説と否定可能性を残し、後日決着できる形にする

これらを書ききれないなら **flaky ではない、調査未完了**。

### 例

NG: 「この test たまに落ちるので flaky として ignore」

OK: 「test/foo.rs::concurrent_writes が CI で 5% 程度失敗、ローカルでは再現しない (CI runner は 2 vCPU / ローカルは 8 vCPU)、shared global state を 4 並列で操作する fixture が原因仮説、`mutex 導入 vs fixture 分割 vs serial 化` の 3 案。issue #N で追跡、暫定 `#[ignore = "flaky under low-vcpu CI, see #N"]`」

## timeout 延長を正当化する条件

「runner load が不足してた」は **観測根拠なしに使えない**。延長したくなったら:

- 真因が「I/O 待ち時間が単に長い」と観測できたか (= profile / log で時間 breakdown を出した)
- 延長後の margin が **十分に上回る** ことを複数回計測で示せるか (= 平均 + 標準偏差を測る)
- 単に「fail したから延ばした」は flaky の言い換えで禁則
