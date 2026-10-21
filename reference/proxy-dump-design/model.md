# 一時ダンプの目的と残すもの

proxy (gateway / ロードバランサ / 中継) を通過する通信を、外部 upstream の挙動調査や client 側の記録との突き合わせのために、**一定期間だけ**ファイルに残す機能の設計パターン。常設の観測 (metrics / events / OTel) とは別物で、調査が終われば消えるものとして設計する。検索や集計のような常設の機能はダンプに足さない。

## 芯になる 3 つの要件

- **一時的**: `start` で始め、必ず時限で切れる。設定ファイルに書いて常設にしない (消し忘れがそのまま常設になる)
- **外から on / off**: `start` / `stop` の API (HTTP に書き込み系を置かない構成なら CLI + 制御 socket) で制御し、timer は proxy のプロセスが持つ。「ダンプ中」をディスクに書いて restart を跨いで続けない
- **勝手に片付く**: 保存先は一定時間 (`dump_cleanup_ttl`) の経過後に自動削除される ([capacity](capacity.md))

## 系列 (dump) と `dump_id`

`start` 1 回 = 1 dump。UUIDv7 の `dump_id` を発行し、停止条件に達するか `stop` が呼ばれるまで、一致した request / response を `dump/{dump_id}/` に保存する ([files](files.md))。UUIDv7 なので `ls` で始まった順に並び、同時に始めても衝突しない。

dump どうしは互いを知らない。同じ条件に期間の重なる dump を複数作ってよく、重なっている間の 1 本は動いている dump の全部に書かれる (計数もそれぞれに乗る)。「延長したい」は新しい `start`、「短くしたい」は `stop` で足り、置き換えや同時 1 つの制限は要らない。

## 何を残すか

| 対象 | 形 |
|---|---|
| request | proxy が client から受けた形 (proxy が書き換える前) |
| response | upstream から受けた形 (proxy が書き換える前)。圧縮は既定で展開せずそのまま ([files](files.md) の `store`) |

proxy が upstream に送った書き換え後の request は残さない。突き合わせの相手 (client 側の記録) は送った形であり、両端の生の姿だけ残せば書き換えの効き方は response から読める。本文を 2 通り残すと置き場も計数も倍になる。proxy が加えた変更を残したいなら、記録本体は受けた形のまま、メタ json の `rewrites` (任意) に差分として書く ([files](files.md))。

## 試行 (attempts)

upstream を替えて試し直す proxy / LB では、1 request に複数の upstream 応答がありうる。全部残す。

- 試行番号は 1 始まりで、**proxy の送信ループが振る**。経路名から推定しない (同じ経路名を設定に重ねて書けるため)
- 試行ごとに response のメタ json と body を持つ (ファイル名に試行番号、[files](files.md))。前の試行を消さず、書いた量からも差し引かない (proxy は先に断られた応答を持ったまま次を試し、後の応答を捨てて先の応答を返すこともある)
- client へ返した試行を `adopted` で示す。proxy 自身が組んだ応答 (エラー本文など) を返した時は採用試行なし (`adopted: null`)。upstream が 1 度も答えていなければ試行は 0 件

## 一致条件

`start` で、dump する request の一致条件を指定する。

- **最低 1 つの軸を必須**にする (無条件の dump を作れないようにする)
- プロダクトが面 (tenant / namespace) を持つなら、**面の指定を必須**にし、面をまたぐ dump を作れないようにする。別の面の内容が別の面の作業で読まれる事故を防ぐため。複数の面を取りたければ面ごとに `start` する
- 1 本をどの dump に書くかは request を受けた時点で決める。途中から始めた dump にその 1 本は入らない

## 状態と停止理由

| 状態 | 説明 |
|---|---|
| `active` | 書き込み待ちまたは書き込み中。条件に一致する request が一度も来ていなくても active |
| `stopped` | 終端状態。一度 stopped になった dump は、その後ディスクに空きができても再開しない |

| reason | 条件 |
|---|---|
| `timeout` | `timeout` に達した |
| `max_bytes` | その dump の `max_bytes` に達した |
| `total_limit` | 全体の実使用量が `dump_max_total_bytes` に達した |
| `fs_min_free` | fs 空き容量が `dump_fs_min_free` を下回る書き込みになった |
| `stop` | `stop` が呼ばれた (`prune` が active な dump を消す時もこれ) |
| `disconnected` | follow モードの接続が閉じた |
| `lagged` | follow モードの購読者が遅く、送信バッファが溢れた |

停止後は、流れている途中の応答も含めて何も書かない。判定のタイミングと途中打ち切り (`truncated`) は [capacity](capacity.md)、follow は [api](api.md)。

## 適用例

kawaz/llm-gateway の DR-0038 がこのパターンの最初の適用先。1 request の本文が 500 KB 前後 (稼働中の実測で中央値 554 KB、最大 2.6 MB、応答は中央値 18 KB) あるので `max_bytes` の既定を 200 MiB 程度に置く。follow モードの背圧 (`lagged` で切る) は、先行の購読型の口で「止まったまま繋がっている購読者が、最大バックログ件数分の本文をプロセスのメモリに抱え続け、読み始めるまで切断されない」実測を根拠にしている。

## 未決

- 一致条件の文法 (軸の種類、複数軸の組み合わせ方)
