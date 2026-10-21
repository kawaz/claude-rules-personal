# 保存ファイル構成と index.jsonl

```
dump/{dump_id}/
  index.jsonl
  {ts}-{seq}.request.json
  {ts}-{seq}.request.body
  {ts}-{seq}.{attempt}.response.json
  {ts}-{seq}.{attempt}.response.body
```

1 本 1 ファイルの組にする。1 ファイルの jsonl に追記する形だと、本文を JSON 文字列に包む変換が要り、調べたい 1 本だけを開けない。dump あたり数百〜千のファイルになる懸念は、index.jsonl を入口にしてファイル名を辿ることで受ける。

## メタ json と body の分離

- `*.request.json` / `*.response.json` には status、headers などのメタデータを置く。書いた後は変更しない
- body は stream 型かどうかに関わらず、常に `*.body` として別ファイルに生バイトで保存する。stream 型かどうかは json 側のフラグで示す
- **ファイル名は json 側が指す** (`body_file` 等)。拡張子で中身を表さない (mime ごとの拡張子表を持つと仕様が太る)。body の種類は json 側の `content-type` で判断する
- response のメタ json と body は試行ごとに 1 組 (`{attempt}` は 1 始まり、[model](model.md))
- 認証系ヘッダは json にも書かない ([capacity](capacity.md))

## `seq` (request id)

`{ts}-{seq}` の `seq` は **proxy の request 通し番号と同一**にし、`*.request.json` と index.jsonl にも記録する。proxy の events / stats / log と同じ番号で突き合わせられる。タイムスタンプでの突き合わせは、並行 request で取り違えるおそれがあるため使わない。同じ `ts` の 2 本も `seq` で分かれる。

## 圧縮の保存 (`store`)

start の `store: "raw" | "decoded"`、既定 `raw`。json 側に通信上の `content-encoding` と `body_stored` を残す。

- `raw`: Content-Encoding を展開せず、圧縮されたままのバイトで保存する。`max_bytes` や全体上限で数えるバイト数が通信上のバイト数と一致し、decompression bomb の心配がない。展開は閲覧 UI や CLI など読む側の責務で、読む側で展開後のサイズに上限を設ける
- `decoded`: 展開して保存する。計数 = 展開後の保存バイト数で、判定は展開後の write の位置 ([capacity](capacity.md))

## 手入れの記録 (`rewrites`、任意)

記録本体は受けた形のまま、proxy が加えた変更を `*.request.json` / `*.response.json` の `rewrites` に残せる。

- ヘッダ: `{op: "set" | "add" | "remove", name, value?}` の配列で構造化
- body: アプリ自由の JSON (内容は規定しない。例 `{"cache_control_ttl": "1h"}`)

## 書く時点

- `*.request.json` / `*.response.json` はヘッダが揃った時点で書き、以後変えない。`rewrites` を載せるなら、proxy が送る形を決めた時点 (request なら upstream へ送る直前、response なら upstream のヘッダを受けて client へ返す形を決めた直後) で書く
- body ファイルは逐次追記 (チャンク単位の容量判定は [capacity](capacity.md))
- 1 本の存在の記録は index.jsonl の最初のイベントが担うので、json の書く時点が多少遅れても「来た」ことは残る

## index.jsonl

dump の進行を時系列で追記する**軽いメタだけのイベントログ**。ヘッダや本文は置かない (それらはメタ json と body)。条件に一致する request が一度も来なかった dump でも、index.jsonl だけは作られる。follow モード ([api](api.md)) はこの行をそのまま接続へ流す。

調査用途では「何の待ちで遅いか」を切り分けるため、イベントを時刻点ごとに分ける (1 request あたり複数行)。各イベントは `ts` を持ち、区間を閉じるイベントは直前の対応イベントからの `duration_ms` も持つ。

| event | 時刻点 | 主な欄 |
|---|---|---|
| `start` | dump 開始 | 適用されたパラメータ、labels |
| `request_headers` | client からヘッダ受信完了 | `seq`、メタ json のファイル名、突き合わせに要る軽い欄 |
| `request_body_end` | client から body 受信完了 | bytes、`duration_ms` |
| `upstream_connect` | upstream への接続 (試行ごと) | `attempt` |
| `upstream_headers` | upstream から first byte (試行ごと) | `attempt`、status、メタ json のファイル名、stream かどうか、`duration_ms` |
| `upstream_body_end` | upstream から body 受信完了 (試行ごと) | `attempt`、bytes、`truncated`、`duration_ms` |
| `upstream_close` | upstream の transport close (試行ごと) | `attempt`、`duration_ms` |
| `response_headers_sent` | client へヘッダ送信完了 | `adopted` (返した試行番号、proxy 自身が組んだ応答なら `null`) |
| `response_body_end` | client へ body 送信完了 | bytes、`duration_ms` |
| `transport_close` | client 側の transport close | `duration_ms` |
| `stop` | dump 停止 | `reason`、`stopped_at`、`bytes_written` |

- 完了情報はメタ json を書き直さず、イベントとして追記する。`upstream_headers` があって `upstream_body_end` が無い試行は、書き込み中または異常終了と判断できる
- 上限で打ち切った試行は `upstream_body_end` に `truncated: true` を付け、その後に `stop` を書く。停止後は何も書かない
- `adopted` を client 向けのイベントに置くのは、採用する試行が決まるのが送る時点で、試行のメタ json を書いた時点では決まっていないため ([model](model.md))

## 書き込みのタイミング (flush)

イベントは request / response の完了を待たず、**発生時に書き込みバッファへ載せ、1 秒以内には必ず追記する** (時間か件数で flush)。完了トリガーで開始情報を一緒に書く形だと、完了が来ないまま死んだ場合に request の存在の記録自体が残らない。最初のイベント (`request_headers`) が残っていれば「来た」ことと、どの段階で止まったかが分かる。

## 未決

- `{ts}` の形式
- 各イベントの詳細なフィールド定義 (上の表は主な欄だけ)
- メタ json でのヘッダの表現 (名前 → 値の map か、同名ヘッダを保つ配列か)
