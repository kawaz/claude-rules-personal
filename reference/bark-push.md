# bark-push — iPhone / iPad の Bark アプリへ通知を送る

自作ツール・スクリプト・Claude のフックから kawaz の端末に push 通知を出す手順。経路は kawaz/bark-admin (登録簿 + ファンアウト) → bark-server → APNs。設計は bark-admin の `docs/DESIGN.md`。

## 送信

```sh
curl -sL --post302 https://bark.kawaz-mbp.kawaz.jp/bark-admin/push \
  -H 'Content-Type: application/json' \
  -d '{"device":{"owner":"kawaz"},"title":"build","body":"tests passed","group":"ci"}'
```

- 常に **FQDN 経由** (tailnet 内のみ到達可)。`127.0.0.1:8086` 直結は on-demand 起動が効かない
- サーバは常駐せず cold start では **302 が返る** (caddy-app-proxy が起動してから同じ URL へ戻す)。`curl -L --post302` か 1 回リトライで吸収する。初回は 1〜2 秒かかる。`--post302` を付けない `-L` は、302 の後の要求から本文を落とす (`-d` だけなら GET に変わり、`-X POST` を付けていても本文の無い POST になる。curl 8.23.0 での観測)。curl 以外で送る時も、302 の後に同じ method と本文で送り直す
- 宛先は `device: {k: v, …}` (AND)。値は完全一致、`*v*` (両端 `*`) で部分一致、`*` でそのタグの存在。否定は無い。省略すると退役していない全台。`device_key` / `device_keys` は受け付けない (400)
- 応答: `{"sent":[{"device_id":"…","status":200}],"skipped":0}`。`skipped` は退役済みで外した台数。該当 0 台なら 404
- URL 形式 (`/<key>/<body>`) や root の `/push` は bark-server への透過面で、キーや本文がアクセスログに残るので自作ツールからは使わない

## パラメータ

body は bark V2 と同じ (`device_key(s)` の代わりに `device`)。よく使う物:

| key | 内容 |
|---|---|
| `title` / `subtitle` / `body` | 本文。`body` 以外は省略可 |
| `group` | 通知センターでまとまる単位。ツール名を入れる |
| `level` | `active` (既定) / `timeSensitive` (集中モードを抜ける) / `passive` (バナー無し) / `critical` (無音設定でも鳴る、`volume` 0〜10 と併用) |
| `sound` | `minuet` `bell` `alarm` 等 (アプリの一覧) |
| `url` | タップで開く URL |
| `copy` / `autoCopy` | 通知からコピーする文字列 / 受信時に自動コピー (`"1"`) |
| `badge` | アイコンのバッジ数 (整数) |
| `icon` / `image` | 画像 URL |
| `isArchive` | `"0"` で履歴に残さない |

全項目と型は `GET https://bark.<host>/bark-admin/api/schema` が返す (bark-admin の `src/schema/push-params.ts` が正本)。

## 端末の管理

- UI: `https://bark.kawaz-mbp.kawaz.jp/bark-admin/` (一覧 / タグ編集 / 退役 / 通知テスト / 追加)
- 端末の追加: UI の「デバイス追加」でタグ (`owner` `family` 等) と暗号化の有無を入れて招待を作り QR を出す。招待は何度でも使え、端末で読むたびに使い切りの登録トークン (期限 24 時間。使った端末の再登録だけは期限後も通る) と端末別の暗号化キーが発行される。案内ページは 3 段 (サーバーを追加 → 受信確認の通知をタップ → 暗号化キーをコピーして Bark に貼り、暗号化の確認通知をタップ) で、各段の完了をページが検出して次の案内を出す。登録された端末には招待のタグ + 自動タグ (`name` / `os` は端末種別 `iphone` / `ipad` / `mac` / `android` とその OS、`lang`。Tailscale があれば `ts_user` も) が付き、名前は後で詳細画面から自由に直す
- 暗号化キーを持つ端末には `/bark-admin/push` が自動で AES-256-GCM で暗号化して送る (送信側は何も意識しない)
  - 暗号化で通知の中身が読めなくなる相手は、bark-server とその先の APNs。送信側から bark-admin までは平文 (TLS の中) で、bark-admin は鍵を登録簿に持つ
  - 鍵は tailnet の中の誰でも読める (端末の詳細の API `GET /bark-admin/api/devices/:id` が返す。bark-admin は認証を持たず、到達できる相手を絞るのは tailnet だけ)。tailnet の中の相手から通知の中身を隠す仕組みではない
  - `id` を付けた通知は、`id` だけ平文でも bark-server に渡る (通知の置き換えと削除に使うため)。隠したい値を `id` に入れない
  - 鍵と IV の形は Bark アプリが決めている。鍵は 32 文字の英数字 (約 190 bit)、IV は送信のたびに作る 12 文字の英数字 (約 71 bit)。IV が乱数で 96 bit より短いので、1 つの鍵で IV が重なる確率を 2⁻³² 以下に保てるのは約 120 万通まで (計算による目安)。reference の `crypto-key-management-glossary` が AES-GCM の目安に挙げる 2³² 回は 96 bit の乱数が前提で、ここには当てはまらない
- API: `GET /bark-admin/api/devices?owner=kawaz` (jsonl)、`PATCH` / `DELETE` `/bark-admin/api/devices/:id`
- device_id (bark の device key) は秘密扱いしない (出来るのは tailnet 内からその端末へ通知を送ることだけ)。タグの語彙は `owner` (人) / `name` (端末) / `family` (世帯) を基本に、必要なら足す

## 運用メモ

- データ: `~/.local/share/bark-admin/devices.json`、設定: `~/.config/bark-admin/config.toml` (`server_url` / `db_path`)、ログ: `~/.local/state/bark-admin/server.log` と `~/.local/state/bark-server/server.log`
- 起動は caddy-app-proxy の on-demand (`bark-admin/ondemand/bark-admin-ensure.sh` が bark-server も起こす)。手で起こすならそのスクリプト
- bark-server のバイナリは caddy-app-proxy の `just bark-fetch`
