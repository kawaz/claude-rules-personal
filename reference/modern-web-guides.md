# モダンな Web 標準の実装ガイドを引く

HTML / CSS / クライアント側 JS で UI を実装・修正する前に、該当する機能の実装ガイドを引く。Google Chrome チームの modern-web-guidance のガイド約 200 本 (dialog, popover, anchor positioning, container queries, view transitions, scroll-driven animations, forms, アクセシビリティ, Core Web Vitals, セキュリティ, passkeys など) を、kawaz の private リポ `kawaz/modern-web-guides` に取り込んである。ブラウザが標準で持つ機能で書くための実装手順と、やってはいけない書き方が 1 機能 1 ファイルで載っている。

置き場: `~/.local/share/repos/github.com/kawaz/modern-web-guides/main/`

## 引き方

1. 置き場の `index.md` をキーワードで Grep する。キーワードは UI 部品か機能の英語の名詞 (`dialog`, `tooltip`, `table`, `scroll`, `validation`, `LCP` など)。1 回で当たらなければ同義語でもう 1 回引く
2. 用途の説明が作業に合う行の `guides/<category>/<id>.md` を Read する。複数の機能にまたがる作業は機能ごとに引く
3. ガイド本文に出てくる他のガイドの id は、同じく `index.md` で引ける
4. 実装したら、読んだガイドの MANDATORY と DON'T に照らして確認する

`index.md` の各行にある数字は本文のトークン数。`accessibility` / `security` / `performance` のような分野全体のガイドは 1 万を超えるので、個別機能のガイドで足りる時は読まない。合うガイドが無ければ、無理に近いものを当てはめずに進める。

worker に webui の実装を委譲する時は、置き場のパスとこの引き方を委譲プロンプトに書く。

上流の CLI (`npx modern-web-guidance`) は実行しない (検索クエリを外部へ送信するため)。

## 対象ブラウザの読み替え

ガイドは「Baseline Widely available でない機能には fallback を付ける」前提で書かれている。kawaz の webui の対象は最新の Chrome と Safari だけ (memory の `webui-modern-platform-first`) なので、次のように読み替える。

- 最新の Chrome と Safari の両方で使える機能: fallback も polyfill も付けない
- どちらかで使えない機能: ガイドの fallback に従う。fallback が大きい (外部依存を足す、数十行を超える) 時は付ける前に kawaz に確認する

プロジェクトの CLAUDE.md や DR に対象ブラウザの定めがあれば、そちらを優先する。

## 置き場が無い・古い時

- 置き場が無いマシンでは、reference の `vcs/jj-colocate-setup` の「既存リポジトリの clone」で `kawaz/modern-web-guides` を clone する
- 上流の版を上げる手順は置き場の `README.md` にある (`./sync.sh latest` で最新版を確認し、版を書き換えて `./sync.sh`)
