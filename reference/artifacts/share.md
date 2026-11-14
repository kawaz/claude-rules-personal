# artifacts をインターネットに公開して共有する

`artifacts/` の生成物は tailnet の中からしか見られない ([workspace](workspace.md))。kawaz が tailnet の外の人に見せたいとき (Slack やメールで送る比較ページ、スクリーンショット) は、本トピックの `scripts/artifacts-share` で期限付きの公開 URL に上げる。

**個人情報・秘密が写るもの (氏名・連絡先・住所、トークンや鍵、私的なやり取りの画面) は、上げる前に kawaz に確認する。** 公開 URL は知った人なら誰でも見られる。

```bash
S=~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/artifacts/scripts/artifacts-share
$S new ~/.local/share/repos/github.com/<owner>/<repo>/artifacts/design-options   # 新しい URL で上げる (期限は省略すると 3d)
$S sync <UUID>                                                                   # 手元の中身に揃え直す (期限も延びる)
$S prune <UUID>                                                                  # 公開を取り下げる
```

どのサブコマンドも `--dry-run` で、上げる・消すファイルを出すだけにできる (リモートも記録も変えない)。上げる前の確認に、何が上がるかの一覧として使う。

new / sync は、手元のファイルに加えて**ディレクトリビューア** (ファイルツリーと md・コード・画像のプレビュー。tailnet の中で caddy が出すものと同じ) を共有の直下に上げる。公開先は一覧を返さないので、ビューアと一覧をその場で作って同梱する ([同梱するビューア](#同梱するビューア))。

## new: 上げる

```
$ artifacts-share new ../artifacts/design-options
up: ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/index.html  (text/html; charset=utf-8)
...
up: ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/dirview.html  (text/html; charset=utf-8)
up: ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/dirview-list.json  (application/json; charset=utf-8)
artifacts-share: 14 ファイル (ビューアと一覧を含む) を上げた (記録: …/artifacts/design-options/.artifacts-share.jsonl)。消えるのは 2026-11-14 ごろ
{"updated_at":"2026-11-11T08:26:09Z","uuid":"0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60","ttl":"3d","path":"/…/artifacts/design-options/","url":"https://pub-<…>.r2.dev/ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/","viewer_url":"https://pub-<…>.r2.dev/ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/dirview.html"}
```

- 引数は `<ディレクトリ> [<期限>]`。期限は `1d` / `3d` / `7d` で、**省略すると `3d`** (送って見てもらうのに足り、週末をまたいでも残る。長く見せたいときは sync で延ばせる)
- stdout は JSON 1 行 `{updated_at, uuid, ttl, path, url, viewer_url}` だけ (記録の 1 行に `url` と `viewer_url` を足した形。進み具合と注意は stderr)。`uuid` が sync / prune で指すもの。`jq -r .viewer_url` / `jq -r .url` / `jq -r .uuid` で取り出す
- `--dry-run` でもビューアと一覧は作り (一時ディレクトリに作って捨てる)、上がる予定の一覧に `dirview.html` と `dirview-list.json` が出る
- ディレクトリは相対パスでもよい。実体のパス (realpath) に直したうえで、`~/.local/share/repos/github.com/<owner>/<repo>/artifacts/<整理用ディレクトリ>/` の下だけを受け付ける。`<owner>` は設定の `owners` に挙げたものだけ (挙げていない owner のリポの生成物は、このバケットに出さない)。`artifacts/` そのもの (`.jj` や `.gitignore` がある)、リポのルート、worktree (`main/` 等) の中、ドットで始まるディレクトリの中は上げられない
- ディレクトリの構成をそのまま保って上げる。HTML から相対パスで読む CSS・JS・画像もそのまま動く
- 同じディレクトリで new を繰り返すと、そのたびに別の UUID・別の URL になる (前の URL も期限まで残る)

## kawaz に渡す

出力の `url` は**ディレクトリの URL** で、そのままでは開けない (公開 URL はディレクトリに `index.html` を返さず 404 になる)。見せ方に合わせて次のどちらかを kawaz に渡し、「これを共有してください」と伝える。

- **ビューアで見せる** (md・コード・画像を並べて見せる、自前の `index.html` が無い): `viewer_url` をそのまま渡す。特定のファイルを開いた状態で渡すなら、`viewer_url` の後ろに `#<相対パス>` を続ける (名前の `#` は `%23`、`?` は `%3F`、空白は `%20` にする)
- **自前のページを見せる** (`index.html` 等を作ってある): `url` の後ろに開くファイル名を続けた URL を渡す

```
https://pub-<…>.r2.dev/ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/dirview.html
https://pub-<…>.r2.dev/ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/dirview.html#docs/report.md
https://pub-<…>.r2.dev/ttl-3d/0b7d6f1e-9a42-4c3e-8f5a-2d1c9e7b4a60/index.html
```

URL を知った人は誰でも見られる (守りは推測できない UUID だけ。ルートや prefix の URL では一覧は出ない)。共有の URL を知った人は、同梱した一覧 (`dirview-list.json`) から共有したファイルの名前・サイズ・更新時刻を全部見られる (ビューアの URL を渡していなくても、一覧の名前は決まっているので辿れる。`index.html` からリンクしていないファイルも見つかる)。一覧に載るのは上げたファイルと同じものだけ。

## sync: 中身を直す・期限を延ばす

手元のディレクトリを直してから `sync <UUID>` を実行すると、同じ URL のまま手元の中身に揃う。

- 全ファイルを上げ直してから、手元に無いファイルをリモートから消す
- ビューアと一覧も作り直して上げ直す (消す対象にはならない)。一覧は手元の今の中身になるので、手元で消したファイルはビューアからも消える。ビューアを同梱していない共有を sync すると、その時点でビューアが足される
- **まずいファイルを上げてしまったとき**は、手元から消して sync する (ファイル単位で消すコマンドは無い)
- 自動削除はファイルごとに上げた時点から数えるので、全ファイルを上げ直す sync のたびに期限がその時点から数え直しになる。共有を長引かせたいときも sync する
- 期限 (1d / 3d / 7d) は変えられない (UUID が `ttl-<期限>/` の下にあるため)。期限を変えるなら new で別の URL を作る
- リモートの一覧が取れなかったときは、何も上げ下ろしせずに止まる
- stdout は new と同じ形の JSON 1 行 (`updated_at` は上げ直した時刻)

## prune: 取り下げる

`prune <UUID>` で、リモートのファイルを全部消し、手元の記録からも外す。

- 期限を待たずに見られなくしたいときに使う
- 手元の記録が無くても (ディレクトリを消した後でも)、リモートを全期限の prefix で探して消せる
- UUID は UUIDv4 の形に厳密に照合してから消す (空や壊れた値で prefix ごと消す事故を防ぐ)。消すのは一覧で取れたキーを 1 件ずつで、prefix 指定の一括削除は使わない

## 同梱するビューア

new / sync は、kawaz/dirview の `bin/dirview-bundle` で `dirview.html` (ビューア) と `dirview-list.json` (一覧) を一時ディレクトリに作り、共有の直下に上げる (`ttl-<期限>/<UUID>/dirview.html` 等)。

- `dirview-bundle` は `~/.local/share/repos/github.com/kawaz/dirview/main/bin/dirview-bundle` に固定で、実行には bun が要る。無い・実行できない・失敗したときは、何も上げ下ろしせずに止まる (同梱を省いて上げる方法は無い)
- 共有するディレクトリには何も書かない。一時ディレクトリは終わったとき (エラーや中断でも) に消す
- 一覧に載せるのは、上げるファイルと同じ規則のもの (通常ファイルだけ、ドットファイルとドットで始まるディレクトリの中は除く)。上げる前に、一覧に載ったファイルと上げるファイルが同じ集合かを照合し、食い違えば止まる (上げないファイルの名前を一覧から漏らさない)
- ビューアと一覧は手元のファイルの後に上げる (一覧が指すファイルは先に上がっている)
- 共有するディレクトリの**直下**に `dirview.html` か `dirview-list.json` があると、同梱するものと同じ名前になるので止まる。サブディレクトリの中の同名ファイルはそのまま上がる

## 記録 (`.artifacts-share.jsonl`)

new したディレクトリの直下に、共有 1 件につき 1 行 `{updated_at, uuid, ttl, path}` を残す。

- `updated_at` は最後に全ファイルを上げた時刻 (new か sync)。期限の起点になる
- sync / prune は、`~/.local/share/repos/github.com/*/*/artifacts/` の下からこの記録を探して、UUID から元のディレクトリと期限を引く
- **手元にだけ置き、上げない**。R2 はファイル単位で非公開にできない (公開の設定はバケット全体) ので、上げると誰でも読めてしまう。ドットファイルはスクリプトが必ず除くので、記録も上がらない
- ディレクトリを丸ごと複製すると同じ UUID の記録が 2 つになり、sync / prune はどれが元か決められずに止まる。複製した方の記録を消す
- prune で行が無くなったら、ファイルごと消える

## 上げないもの

- **symlink** が 1 つでもあれば、何も上げずに止まる (リンク先の中身まで公開してしまうため。artifacts workspace にはもともと置かない)
- **ドットファイル** (`.DS_Store`、記録の jsonl 等) と、ドットで始まるディレクトリの中は上げない (警告を出して飛ばす)
- **MIME 型が分からない拡張子**は `application/octet-stream` で上げ、警告を出す (ブラウザでは開かずダウンロードになる)。拡張子から決めるのは html / css / js / mjs / json / map / txt / log / md / csv / svg / png / jpg / gif / webp / avif / ico / pdf / woff / woff2 / mp4 / webm。`Content-Type` を付けないと全部ダウンロードになり CSS / JS も効かないので、足すときはスクリプトの `content_type` に足す (macOS の `file --mime-type` は CSS / JS を `text/plain` にするので使わない)

## 置き場の中身

kawaz 個人の Cloudflare アカウントの R2 バケット 1 つ。アカウント ID・バケット名・公開ドメイン・トークンの id はスクリプトにも本文にも書かず、キーチェーンから読む。

| キーチェーン | 中身 |
|---|---|
| `-s artifacts-share -a settings` | 設定の JSON `{"account_id", "bucket", "public_url", "token_id", "owners"}` (秘密ではない。`public_url` は `https://pub-<…>.r2.dev` で末尾の `/` なし。`owners` は上げてよいリポの owner 名の配列) |
| `-s artifacts-share -a r2-token` | このバケットのオブジェクトの読み書き・一覧・削除だけを許した API トークンの値 (秘密) |

```bash
security find-generic-password -s artifacts-share -a settings -w | jq .   # 設定を見る (秘密ではない)
```

- スクリプトは実行のたびに両方を読む。トークンの値は表示しない (S3 のシークレットに直して curl の設定としてだけ渡す)
- 上げ下ろしは R2 の **S3 互換 API** (`curl --aws-sigv4`) で行う。バケット 1 つに絞ったトークンの権限は S3 互換 API でだけ効き、Cloudflare の REST API (それを使う `cf r2 objects`) では 403 になるため。S3 のアクセスキー ID はトークンの id (設定の `token_id`)、シークレットはトークンの値の SHA-256
- バケット一覧・別のバケット・このバケットのライフサイクル / CORS の設定は、このトークンでは 403 になる
- キーは `ttl-<期限>/<UUIDv4>/<相対パス>`。バケットのライフサイクルのルールが prefix `ttl-1d/` 〜 `ttl-30d/` (1 日刻みの 30 個) ごとに、その日数で消す。スクリプトで選べるのはこのうち 1d / 3d / 7d
- それとは別に、**バケット全体 (prefix 空) に 30 日のルール** (`all-30d`) がある。`ttl-*` の外に置いたものも、30 日で必ず消える
- ルールが重なるときは**期限の短い方が効く** (`ttl-1d/` のファイルの期限は `ttl-1d` の 1 日)
- どのルールでいつ消えるかは、S3 互換 API の HEAD の応答ヘッダー `x-amz-expiration` (`expiry-date="…", rule-id="ttl-3d"`) で見られる。期限は上げた時刻からちょうど N 日後で、実際に消えるのはその後おおむね 24 時間以内
- 公開は r2.dev のドメイン (開発用で、回数の制限がある)
- 署名付き URL を使わない理由: R2 の署名付き URL は 1 オブジェクト 1 操作に限られ、相対パスで複数のファイルを読む HTML に使えない (最大 7 日、S3 API のドメインのみ)

## エラーになったとき

| メッセージ | 状況 | 対処 |
|---|---|---|
| 上げてよい場所でない | `<owner>/<repo>/artifacts/<整理用ディレクトリ>/` の下でない (sync なら、記録の元のディレクトリが動いた) | 生成物を artifacts workspace の整理用ディレクトリに置いてから、そこを指す |
| この owner のリポは上げない | リポの owner が設定の `owners` に無い | その owner の生成物をこのバケットで共有してよいなら、kawaz に確認してから設定の `owners` に足す ([置き場を作る・トークンを作り直す](runbooks/share-setup.md) の「owner を足す」) |
| ドットで始まるディレクトリの中は上げない | 指したディレクトリの途中にドットで始まるディレクトリがある | ドットで始まらないディレクトリに置く |
| symlink がある | 上げるディレクトリの中に symlink がある | symlink を実ファイルに置き換えるか消す |
| 期限は 1d 3d 7d のどれか | 期限が規約外 | 3 つのどれかにする。スクリプトで選べる期限を足すなら `TTLS` に足す (バケットのルールは 1〜30 日ぶんある) |
| 引数の順は <ディレクトリ> [<期限>] | new で期限を先に書いた | ディレクトリを先、期限を後にする |
| UUID の形でない | sync / prune に UUIDv4 (小文字) でない値を渡した | new の出力の `uuid` をそのまま渡す |
| 記録が無い | sync で、UUID の記録がどの artifacts workspace にも無い (prune 済み、ディレクトリを消した) | 上げ直すなら new で新しい URL を作る |
| 同じ UUID の記録が複数ある / 記録の場所と記録の path が食い違う | ディレクトリや記録を複製・移動した | 元でない方の記録を消す。ディレクトリを動かしたなら、元の共有は prune して new し直す |
| キーチェーンに項目が無い (`-a settings` / `-a r2-token`) / キーチェーンの設定が読めない | 設定かトークンの項目が無い、または設定の形が壊れている | [置き場を作る・トークンを作り直す](runbooks/share-setup.md) |
| キーチェーンを引けない (終了コード …) | キーチェーンがロックされている等 | キーチェーンを開いてからやり直す |
| 上げられなかった / 一覧を取れなかった (`HTTP 401` / `HTTP 403` / `InvalidAccessKeyId` / `SignatureDoesNotMatch`) | トークンが失効した・消された、または作り直したのに設定の `token_id` が古い | 同上。new の途中で止まったなら、記録は先に残っているので `sync <UUID>` でやり直せる |
| 一覧を取れなかったので止めた | sync / prune で一覧が取れなかった (上と同じ原因か、ネットワーク) | 何も上げ下ろししていないので、原因を直してからやり直す |
| ビューアを作る dirview-bundle が無い / dirview-bundle を実行できない | kawaz/dirview が clone されていない、またはスクリプトに実行権限が無い | `~/.local/share/repos/github.com/kawaz/dirview/main` に kawaz/dirview を clone する (何も上げ下ろししていない) |
| ビューアを作れなかったので止めた (直前に `dirview-bundle: the shared directory already has dirview.html` 等) | 共有するディレクトリの直下に `dirview.html` / `dirview-list.json` がある | そのファイルを改名してからやり直す |
| ビューアを作れなかったので止めた (直前に `env: bun: No such file or directory`) | bun が無い | bun を入れる |
| ビューアを作れなかったので止めた (直前に `released viewer not found`) | dirview リポにリリース済みのビューアが無い | dirview リポで `just release` する |
| dirview-bundle の一覧と上げるファイルが食い違う | `dirview-bundle` と `artifacts-share` の、一覧に載せる・上げるファイルの規則がずれた | 何も上げ下ろししていない。両方の除外の規則を揃える |
