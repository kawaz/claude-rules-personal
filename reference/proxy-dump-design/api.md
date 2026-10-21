# API: start / end / list / prune、follow モード、labels

書き込み系を HTTP に置かない構成の proxy では、同じ意味を CLI + 制御 socket で持つ (`dump start` / `dump stop` / `dump list` / `dump prune`)。応答の欄の規約: サイズは bytes の整数で `_bytes` suffix、時間は `_ms` または RFC3339 に揃える。

## `POST dump/start`

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| (一致条件) | | 必須 | dump する request の一致条件 ([model](model.md)) |
| `timeout` | duration | 任意 | 省略時は `dump_default_timeout`。`dump_max_timeout` を超える指定は断る |
| `max_bytes` | integer | 任意 | 省略時は `dump_default_max_bytes` |
| `store` | `"raw"` / `"decoded"` | 任意 | 既定 `raw` ([files](files.md)) |
| `follow` | bool | 任意 | 接続を保ってイベントを流す (下記) |
| `embed` | `"bodies"` | 任意 | follow で本文も同梱する (下記) |
| `persist` | bool | 任意 | 既定 `true`。`false` は follow + embed の時だけ許す (下記) |
| `labels` | map | 任意 | 自由な kv (下記) |

応答は `dump_id`、実際に適用されたパラメータ (既定値を補完したもの)、その時点の並列度・容量のスナップショットを返す。容量情報は利用側が重複 dump などに気づくきっかけ情報であり、書き込みを保証するものではない。dump の一覧は含めず、件数と合計値だけを返す。

```json
{
  "dump_id": "0192f3a1-7c00-7abc-8def-0123456789ab",
  "timeout_ms": 300000,
  "max_bytes": 5242880,
  "store": "raw",
  "labels": { "owner": "kawaz", "memo": "pr1234" },
  "started_at": "2026-10-21T00:52:00Z",
  "expires_at": "2026-10-21T00:57:00Z",
  "delete_after": "2026-10-23T00:52:00Z",
  "concurrency": { "limit": 16, "active": 4 },
  "storage": {
    "active_used_bytes": 3145728,
    "active_requested_bytes": 20971520,
    "total_available_bytes": 2144337920,
    "total_limit_bytes": 2147483648,
    "fs_min_free_bytes": 1073741824,
    "fs_free_bytes": 53687091200,
    "fs_checked_at": "2026-10-21T00:51:30Z"
  }
}
```

| フィールド | 説明 |
|---|---|
| `expires_at` | `started_at + timeout`。時限で止まる時刻 |
| `delete_after` | `started_at + dump_cleanup_ttl`。クリーンアップで消える時刻 |
| `concurrency.limit` | `dump_max_concurrency` |
| `concurrency.active` | active な dump の数 (今回の dump を含む) |
| `storage.active_used_bytes` | active な dump の現時点の実使用量合計 |
| `storage.active_requested_bytes` | active な dump の `max_bytes` 合計 (今回の dump を含む)。参考値 |
| `storage.total_available_bytes` | 実際の合計サイズ上限。`max(0, min(total_limit_bytes, fs_free_bytes − fs_min_free_bytes))` |
| `storage.total_limit_bytes` | 設定上の合計サイズ上限 (`dump_max_total_bytes`) |
| `storage.fs_min_free_bytes` | `dump_fs_min_free` |
| `storage.fs_free_bytes` | 保存先 fs の空き容量 (cache 値) |
| `storage.fs_checked_at` | `fs_free_bytes` を計測した時刻 |

`active_requested_bytes > total_available_bytes` の場合は、「全 dump が上限まで書くと途中で止まる」というサインとして読める。

## `POST dump/stop`

指定した dump を、timeout やサイズ制限を待たずに停止する。リクエスト `{ "dump_id": "…" }`。冪等とし、既に stopped の dump に対して呼ばれてもエラーにせず、その時点の状態を返す。既に別の理由で止まっていた場合、`reason` はその元の理由になる。

```json
{ "dump_id": "…", "state": "stopped", "reason": "stop", "stopped_at": "2026-10-21T00:55:12Z", "bytes_written": 1048576 }
```

## list / prune

終了済み・削除待ちを含む dump の一覧と状態を返す `list` と、dump を消す `prune` を持つ。dump の管理や閲覧 UI の構築に使う。

- `list` と `prune` は同じ選択子を取る: labels に対する `owner=kawaz` / `pr!=1234` / `owner` (キーの存在)
- `prune` は `dump_id` か選択子のどちらかを**必須**にする (無指定で全消しさせない)。active な dump を prune する時は stop (`reason: "stop"`) してから削除し、応答に消した `dump_id` を並べる

## follow (接続を保って流す) モード

`start` に `follow: true` を付けると、応答を 1 回で返さず接続を保ち、index.jsonl に追記するイベントをそのまま流す (SSE か ndjson)。接続が閉じたら dump を止める (`reason: "disconnected"`)。timeout や上限で止まった時は `stop` イベントを流してから接続を閉じる。

- **follow でもファイルは常に書く**。dump の意味を変えず、接続側は view。計数はファイル書き込み側の規則のまま ([capacity](capacity.md))
- `embed: "bodies"` でメタ json と body の中身をイベントに同梱できる。無ければファイル名だけを流し、HTTP の一般形では `GET dump/{dump_id}/{file}` で取る。`embed` で流す本文もファイル書き込みの計数の範囲内 (ファイルに書けない本文は流さない)
- **背圧**: 遅い購読者で proxy を止めない。送信バッファが溢れたら接続を閉じ、dump を `reason: "lagged"` で止める (止まったまま繋がっている購読者がプロセスのメモリに本文を抱え続ける事故を防ぐ)
- 書き込み系を HTTP に置かない構成では、CLI (`dump start --follow`) が制御 socket 越しにイベントを標準出力へ流し、Ctrl-C で止める形が同じ意味になる

### persist

`persist` (既定 `true`) で保存の有無を選ぶ。`persist: false` は follow + embed の時だけ許し、それ以外の組み合わせで指定されたら `start` で断る (残らず流れもしない dump は意味がない)。組み合わせは 3 つ:

| 組み合わせ | 意味 |
|---|---|
| follow だけ | 保存しつつメタのイベントだけ流す (本文はファイルから読む) |
| follow + embed | 保存しつつ本文も同梱して流す |
| follow + embed + `persist: false` | 流すだけ |

`persist: false` の時、サーバ側の保存は一時 (spool) だけ: 本文ファイルは書き込み許可の判定を通して書き、接続へ送り終えたら削除する。index.jsonl も接続へ流しているので、停止時にディレクトリごと削除し、`dump_cleanup_ttl` の保持はしない。計数は、全体の実使用量は書いた時点で加算し消した時点で減算、dump 自身の `max_bytes` は累計 (消しても戻さない。「この dump で流してよい量」の上限)。

## labels

dump に自由な kv を付け、list / prune で絞るための選択子。キーの意味は規定せず各利用者に任せる。複数のメンバーが別の目的で dump を取り合う環境 (LB 等) なら `owner` で自分の分だけを見る・消す、のように使える。

- `start` の `labels` (任意、kv の map。例 `{"owner": "kawaz", "memo": "pr1234"}`。キーも値も自由)。set でなく kv にするのは、値を空にすれば set を表せて逆は無理なため。Kubernetes / Docker / クラウド資源と語彙が揃う
- `start` イベントと `start` の応答に入る。キーと値は長さ上限 (例 63 文字) と文字種 (英数字・`-` `_` `.`) を決める
- index に平文で残る。秘密を入れない

## 未決

- 並列度の上限に達している状態で start が来た場合のエラー (HTTP status、応答の形)
- list / prune のエンドポイントと応答の形
- follow の形式 (SSE か ndjson か) と `GET dump/{dump_id}/{file}` の形
- labels の長さ上限と文字種の確定値
