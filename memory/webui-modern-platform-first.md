# webui はモダン CSS / JS を積極採用する (Baseline 基準)

kawaz の webui (ccmsg-webui 等) では、最新の JS / CSS 仕様の活用を常に検討する。新しめの機能を避けて昔からあるハックで代替しない。Safari 27 (2026-09) 以降、Baseline に入った機能が多い。

- 採否の根拠は Baseline (web-platform-dx の Newly / Widely available)。DR / DESIGN に「使う機能 / Baseline の状態」を書く
- 対象例: 相対色構文 `oklch(from …)`、`color-mix()`、`@property`、`light-dark()`、`@container`、`:has()`、`@scope`、`@layer`、`field-sizing`、`popover`、`dialog`、View Transitions、`scroll-driven animations`
- 対象 browser は **最新の Chrome と Safari** の 2 つだけ (kawaz が使うのはそれだけ)。Firefox や古い版の保証はしない。Baseline を見る時も「Chrome と Safari の最新で使えるか」が判定で、Widely まで待たない
