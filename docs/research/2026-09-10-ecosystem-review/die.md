# エコシステムレビュー指摘 — die

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9): 875 行の単一ファイル (Zig) に unit test 67 本、e2e は bash 799 行で 133 の expect、CI は 3 OS matrix で Windows CRT の CRLF→LF 変換と Cygwin pty の TTY 判定まで実機で通している。DR 9 本で「option を撤廃した設計」「`-n` は cat 同等 / default はカーソルが崩れないだけ」「exit code を制御したい場面は別経路で書ける」と、機能を足さない理由が全部書いてある。4 言語 (Go / MoonBit / Rust / Zig) を並行実装してレビューした上で Zig を選び、他は archive bookmark に残す過程が findings 7 本にある。「小さい・断定的・予測可能」の見本で、完成品として扱ってよい。指摘は 3 つとも小さい。

### D-1 ★1 `buildArgOutput` と `joinArgs` / `appendLfStr` の重複を解消する

- 指摘: `buildArgOutput` (固定長 `Buf`、alloc 無し、本番経路) と `joinArgs` + `appendLfStr` (allocator 使用、テスト専用) が同じ trim / sep / LF 補完ロジックを 2 度書いている。unit test 67 本のうち join 系 17 本と appendLf 系 10 本は後者を検証しており、本番経路の `buildArgOutput` は e2e からしか覆われていない。`.all` の in-place trim (`buf.ptr[k] = buf.ptr[start + k]`) は後者に無い本番固有のコードで、ここが unit test の外
- 修正案: `joinArgs` / `appendLfStr` を削除し、unit test を `buildArgOutput` に直接当てる。`Buf` は固定長なのでテストからそのまま使える (allocator 不要)。テスト側で `rest_args` の型 (`[]const [:0]const u8`) を作るのが少し面倒だが、`comptime` 文字列リテラルは sentinel 付きなので `&[_][:0]const u8{ "a", "b" }` で足りる。これで本番経路の in-place trim が unit test に入り、重複も消える。issue は起票せずそのまま直してよい規模

### D-2 ★1 README の「exit code は常に 1」を DR-0009 に合わせる

- 指摘: README-ja の動作節が「exit code は **常に 1** (option / env で変更不可)」と言い切るが、DR-0009 で `--help` / `--version` (明示の meta query) は exit 0 に refine されている。DESIGN-ja は正しく書き分けている。README だけ v0.3.0 以前のまま
- 修正案: 「exit code は die 本来の動作では常に 1 (変更不可)。`--help` / `--version` だけ exit 0」の 1 行に。README.md (英) も同じ

### D-3 ★1 findings 7 本のうち言語比較系を research/ へ

- 指摘: `docs/findings/2026-06-27-{language-comparison,review-go,review-mbt,review-rust,review-zig,optimisation-synthesis,final-recommendation}.md` は DR-0007 で決着した比較の一次資料で、findings (検証記録) というより research (判断の材料)。`docs-layout` の区分では research 向き。`tty-detection-cross-os.md` だけが findings として残る
- 修正案: 7 本を `docs/research/` へ移し、DR-0007 のリンクを追随。急がない (INDEX からたどれているので実害なし)
