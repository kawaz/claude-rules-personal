# webui はモダン CSS / JS を積極採用する (Baseline 基準)

kawaz の webui (ccmsg-webui 等) では、最新の JS / CSS 仕様の活用を常に検討する。新しめの機能を避けて昔からあるハックで代替しない。Safari 27 (2026-09) 以降、Baseline に入った機能が多い。

- 採否の根拠は Baseline (web-platform-dx の Newly / Widely available)。DR / DESIGN に「使う機能 / Baseline の状態」を書く
- 対象例: 相対色構文 `oklch(from …)`、`color-mix()`、`@property`、`light-dark()`、`@container`、`:has()`、`@scope`、`@layer`、`field-sizing`、`popover`、`dialog`、View Transitions、`scroll-driven animations`
- **ブラウザが持っている振る舞いを JS で自前制御しない** (kawaz 2026-09-19「基本自分で制御する系はゴミ」)。スクロールの追従・貼り付き・引っかかり・伸縮・位置固定は `scroll-snap` / `overflow-anchor` / `position: sticky` / `resize` / anchor positioning 等の CSS に任せ、JS が動かすのは人が明示した操作 (「末尾へ」等) だけ。自前制御は WebKit と Chromium で挙動が割れて制御不能になる (実例: iOS で `scrollIntoView` が祖先の区画まで動かしタブ行が画面外に流れた)
- 対象 browser は **最新の Chrome と Safari** の 2 つだけ (kawaz が使うのはそれだけ)。Firefox や古い版の保証はしない。Baseline を見る時も「Chrome と Safari の最新で使えるか」が判定で、Widely まで待たない
