---
title: "Gemini 4 Carbon にルール系と privacy のリポを直させた 4 つの版を読み比べて、採る物を決める"
status: open
category: task
created: 2026-11-25
origin: "kawaz の指示 (sockat のセッションで実施)"
---

# Gemini 4 Carbon にルール系と privacy のリポを直させた 4 つの版を読み比べて、採る物を決める

## 概要

- kawaz の指示 (2026-11-25): 日本語と言葉の扱いが丁寧な Gemini (Carbon) に、ルール系のリポ全部と privacy のリポ全部の、言葉・文章・構成を直させてみる。指摘の列挙だけでなく、実際の修正までさせる
- 指示の細かさを変えた 4 つの版を並行で流し、違いを比べる
- 元のリポは触っていない。作業用の clone の中だけを直させた (push 先は外してある)

## 対象と置き場

- 対象: `claude-rules-personal`・`claude-rules-source-guard`・`claude-rules-syun`・`claude-rules-zunsystem`、`privacy-personal`・`privacy-syun`・`privacy-zunsystem` (どれも 2026-11-25 07:45 頃の main)
- 置き場: `kawaz/sockat` のリポの `artifacts` の workspace の `rules-review-20261125/` (版管理はしていない)。版ごとのディレクトリの `work/` が clone、`out/` が報告と記録。依頼の文面は `prompts/`、流し方は `run.sh` と `run-step.sh`
- 道具: `agy -p --model gemini-4-carbon-high --add-dir <out> --mode accept-edits`。各回の後に、runner が clone ごとにコミットした (Carbon には git を使わせていない)
- privacy のリポと業務面のルールのリポの中身を、Google のモデルに送っている

## 4 つの版と結果

| 版 | 渡した指示 | 結果 | 変えたファイル |
|---|---|---|---|
| `p1-staged` | 4 回に分ける (全体のレビュー → 文章の洗い出し → 構成の計画 → 直す)。観点と書き方を指定し、「指示の意味を変えない」「リンクと索引のつながりを保つ」「privacy の事実を変えない」等の決まりを付ける | 依頼 1 の報告 (64 KB) だけ。依頼 2 は 54 分走って報告を書く前に利用枠が尽きた。依頼 3・4 は未着手 | 0 |
| `p2-free-2steps` | 1 回目「良くない点を洗い出して、直す計画を立てて。まだ直さない」、2 回目「それも見つつ、総合的に直して」 | 1 回目は完了 (観点ごと・リポごとの指摘と計画の 4 ファイル、計 102 KB)。2 回目は 42 分で利用枠が尽きた。直した事の報告は無い | 150 |
| `p3-free-1step` | 「良くない点を洗い出して、実際に直して。報告も書いて。手順は任せる」 | 1 回目は 8 分で打ち切り (使えない道具 `run_workflow` を使おうとした)。同じ文面の 2 回目は 40 分で完走。報告は `out/report.md` (27 KB) | 95 |
| `p4-improve-only` | 「日本語や文章や構成の総合的な改善をしてほしい (必要ならファイルのリネームや統合や分割も自由にやってよい)」だけ | 42 分で完走。報告は頼んでいないが、最後の応答 (`out/1.stdout.log`、17 KB) に書いてある | 90 |

- 4 つを同時に流したので、Carbon の利用枠 (`Individual quota reached`) を 08:52〜09:02 に使い切った。戻るのは 12:50 頃
- 中身は、流したセッションはまだ読んでいない (数と、報告の頭と末尾を見ただけ)
- `p4-improve-only` の報告は、文章の直しの他に、壊れている所を直したと書いている (`privacy-personal` の索引の相対パスが `reference/` を二重に持っていてリンクが全部切れていた、`claude-rules-personal` の索引に実体の無いファイルの項目があった、等)。本当かは、元のリポで確かめる必要がある
- `p4-improve-only` は、ファイルのリネームや分割をしていない。シェルが使えず古いファイルを消せないため、と自分で理由を書いている

## 完走した 2 つの版の確かめ (2026-11-25)

worker (Opus high) が、版ごとに clone の差分を全部読み、元の状態 (`HEAD~1`) と突き合わせた。全文は置き場の `compare/p3-check.md`・`compare/p4-check.md`。文章が読みやすくなったかは判定させていない (各ファイルの 8 節に、元の文と直した文を 30 か所ずつ機械的に選んで並べてある。kawaz が読んで決める)。

| | `p3-free-1step` | `p4-improve-only` |
|---|---|---|
| 変えたファイル | 95 (+695 / −1053 行)。新規 4、削除と改名は 0 | 90 (+1130 / −1422 行)。新規 1、削除と改名は 0 |
| 常時ロードの rule の量 (元は 84,085 バイト) | 74,160 バイト | 78,733 バイト |
| `just lint-rules` | FATAL 1 → 0、WARN 2 → 1 | FATAL 1 → 0、WARN 2 → 1 |
| 報告と実物 | 29 項目のうち実在 25、一部 4。報告に無い意味の変更が 21 種類 | 22 項目のうち実在 18、一部 3、記述だけ 1 |
| 指示の意味 (抜き取り) | 機械的に選んだ 62 か所のうち、同じ 32、変わった 30 | 機械的に選んだ 43 か所のうち、変わった 13 |
| privacy の事実 | 値が変わった所は無い。索引の要旨から落ちた項目 6、落ちた記述 10、足した記述 11 (うち 2 は出所が無い) | 値が変わった所は無い。落ちた・変わった記述 17 |
| 新しく持ち込んだ言い方 | およそ 25 | 25 |
| 手を付けていない所 | for-all の rule 18 本、reference のトピック 22 のうち 14、privacy の本文のほとんど | for-all の 12 ファイル、reference 146 のうち 131、privacy の本文の大半 |

- どちらの版も、文章を縮める中で、禁則・条件・理由・kawaz の発言の引用を落としたり、指示を足したりしている。報告は「表現の改善」「冗長表現の圧縮」とまとめていて、意味の変更としては書いていない
- FATAL が消えたのは、索引から `local-translate.md` の項目を消したため。このファイルは手元にあり、全体の gitignore の `local-*` に当たって clone に入っていなかっただけ。リポの `.gitignore` で、このファイルだけを否定して版管理に入れた (kawaz の裁定)。版を当てる時、索引のこの行は項目ありのままにする
- 元から壊れていた所の指摘は、今の元のリポで確かめ直した (`compare/broken-in-origin.md`。46 件)。迷いなく直せる 12 件は直して push した。判断が要る 23 件と、public のリポに出ている疑いの 11 件は、直さずに一覧にしてある

## kawaz の判断 (2026-11-25)

kawaz が、意味の変わった所の差分 (`classifier-notes`・`discussion-style`・`empirical-verification`・`no-excessive-apology`・`feedback-evaluation`・`synthesis-temptation-guard`・`push-workflow`・`index-lines-terse`・`claude-config-dir-isolation`・`reference/_index.md` の private 層) を見た結果:

- 大体問題ない。落ちた行には、元々意味の無かった物がある (例: `discussion-style` の「NG なのは『方針が決まった気になって本実装に突入する』こと」)。落ちた行を一律に戻す対象として扱わない
- `emrd` は、必要な所 (設定や運用スクリプトで、フルパスで書かないと意味が無い所) で許される語。説明の文の中の物は一般化してよい
- `push-workflow` に足された「`jj describe` 単体は使わない」は、そのままでよい
- `classifier-notes` の `Edit` の rule のパスの書き方は、どちらの書き方も要らない (書き方は ccmsg が直すので、知る必要が無い)。元の rule からその文を外した。classifier の運用は、kawaz がプロジェクトごとに `autoMode` を調整する
- 入れない物: `p3-free-1step` が `reference/docs-authoring/knowledge-timing.md` の status の値に足した `pending-sublimation` (claude-local-issue v1.0.3 では、`open` として読み替える古い値)

まだ決まっていない事: どの版を土台にするか (残りの 2 つの版が出てから、4 つを並べて決める)。

## `agy -p` で分かった事

- 実行ごとのログが `~/.gemini/antigravity-cli/log/cli-<開始の日時>.log` に残る。`--log-file` で置き場を変えられる
- 使えない道具 (`run_workflow`) を使おうとすると、会話ごと打ち切られる事がある。終了コードは 0 のままで、標準出力には途中の 1 行しか残らない。見分けるのは、ログの `CancelCascadeInvocation`
- ログの `triggered=true` は、打ち切りの印ではない (ファイルの編集のたびに `unsupported_tool: edit_file` として出るが、編集は通っている)
- 自分の rule やメモリに当たるファイルを編集すると、別の検査が印を付ける (`Risk Signal B`)。止められたかは確かめていない
- シェルは使えない。git の操作を許す設定を付けて流す事は、こちらの auto mode の classifier に止められた

## 受け入れ条件

- [ ] `p2-free-2steps` の直しの続き (計画の残りと、直した事の報告) を流す (利用枠が戻ってから。`run-step.sh p2-free-2steps 2b p2-2.md`)
- [ ] `p1-staged` の依頼 2〜4 を流す (同じく。`run-step.sh p1-staged 2 p1-common.md p1-2.md` のように 1 回ずつ。4 つを同時に流さない)
- [ ] 4 つの版の差分と報告を読み比べる: 文章が良くなったか、指示の意味が変わっていないか、リンクと索引が壊れていないか (`just lint-rules`)、privacy の事実が変わっていないか
- [ ] 報告にある「壊れている所」を、元のリポで確かめる。本当なら直す
- [ ] kawaz と、どの版のどの直しを採るかを決めて、元のリポに入れる
