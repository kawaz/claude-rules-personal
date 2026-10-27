# JWKS を信頼の根にした webhook 署名 (鍵管理ゼロのメッセージ単位認証)

公開 endpoint を持つサービス同士で、送り側 (S) が受け側 (R) の endpoint へイベントを POST する webhook を、**IP 許可リストも共有 secret も配布鍵も持たずに**認証する設計。信頼の根は Web PKI で、S の identity は「R の設定に書かれた `jwks_url`」に置く。`peer-auth-url-identity` の P1 (ステートフル接続) を満たさない場面の方式で、鍵キャッシュ・リプレイウィンドウ・鍵の世代管理を代わりに持つ。

## 一般的な方式との位置づけ

| 方式 | 代表例 | 管理対象 |
|---|---|---|
| HMAC 共有 secret (timestamp + 署名ヘッダ) | GitHub / Stripe / Shopify、Standard Webhooks `whsec_` | endpoint ごとの secret の生成・配布・保管・rotate |
| 非対称署名 + 公開鍵の配布 | Standard Webhooks `whpk_`、Apple (x5c) | 送り側公開鍵の配布と rotate 時の再配布 |
| **JWT + JWKS (本文書)** | Google Cloud Pub/Sub push (OIDC token、`aud` = endpoint) | `jwks_url` 1 つ。rotate は自動 |
| RFC 9421 HTTP Message Signatures + JWKS | Cloudflare Web Bot Auth | 同上。method / path / header も署名対象にできるがライブラリが薄い |
| mTLS | 社内間 | CA と証明書配布 |

JWT + JWKS は「鍵管理ゼロ」を満たす中で最も標準に近く、JOSE ライブラリだけで実装できる。代償は信頼の根が TLS / DNS に移ること (R が `jwks_url` を信頼する = その origin の TLS を信頼する)。

## 前提

| # | 条件 | 満たさない場合 |
|---|---|---|
| P1 | S が公開 FQDN と有効な TLS 証明書を持ち、`jwks_url` を https で配信する | 信頼の根が無い |
| P2 | R の endpoint が https | S が R を認証できない (送信先の確認は TLS に依存) |
| P3 | S と R の時刻が同期している (30 秒以内) | `exp` / `iat` の検証で落ちる。許容幅を広げず、ズレた相手を可用性の問題として扱う |
| P4 | S のインスタンスが 1 つ、または JWKS を全インスタンスの鍵を集約した形で配信できる | プロセスごとのエフェメラル鍵が `jwks_url` に載らず、R が常に未知 kid を見る |

## 設定

R (受け側) は送り元 (receiver) 単位で持つ。受け口が 1 つなら `path` は省略できる。複数の receiver を持つなら、受信 path か `iss` のどちらかで `jwks_url` が一意に引けなければならない (受け口の種類が多いなら path で分ける方が無駄が無い)。

```
receivers:
  - path: /hooks/s2            # 受け口が 1 つなら省略可
    jwks_url: https://s2.example/.well-known/jwks.json
    aud: https://s1.example/hooks/s2   # S が発行した値を転記。省略時は受け口の URL
    iss: https://s2.example            # 任意。指定時は完全一致
algs: ["Ed25519"]                      # 許可リスト。今は 1 本だが複数前提の形
```

S (送り側) は送信先単位で持つ。`aud` は **S が発行**し、R に転記してもらう (登録レコードを持つのは S なので)。既定値は endpoint URL で、S が知っている URL と R が自分と思っている URL は一致するので、既定のままならやり取りは要らない。`aud` の役目は「受け口ごとに一意で R が完全一致で検証する」ことだけなので、誰が決めても安全性は変わらない。

```
webhooks:
  - endpoint: https://s1.example/hooks/s2
    aud: https://s1.example/hooks/s2   # 省略時は endpoint
```

## 鍵の世代管理 (S)

S は起動時にエフェメラルな Ed25519 鍵ペアを作り、ランダムな `kid` を採番する。鍵は 3 状態を持ち、JWKS には最大 3 本載る。決める固定値は**鍵寿命 1 つ (標準 1h)** だけで、遷移はすべてその比率で書く。

| 状態 | JWKS に載る | 署名に使う | 遷移 |
|---|---|---|---|
| 次 (pre-published) | 載る | 使わない | 現鍵の寿命 **50%** で生成して公開 |
| 現 (active) | 載る | 使う | 寿命 **100%** で「次」を「現」に昇格 |
| 旧 (retiring) | 載る | 使わない | 寿命 **110%** で外す |

成立条件は `10% × 鍵寿命 > token 寿命 + 時刻ずれ許容 + R の再取得 interval` (1h なら 6 分 > 30 秒 + 30 秒 + 30 秒)。鍵寿命を極端に短くするとこれが破れるので、短くする時はこの不等式だけ確認する。**次鍵の事前公開が肝**: 期限直前 (99% など) に初めて公開すると、R のキャッシュは必ず miss し、再取得の最小 interval や一時的な fetch 失敗と重なった間のイベントが全部拒否される。50% 公開なら R の定期取得 (下記) が先に拾う。

S が再起動すると鍵は全部作り直しになる。送信中だった旧鍵の token は R 側のキャッシュが残っていれば通り、残っていなければ R が拒否して S の再送に任せる。

## token (S → R)

body は `application/jwt` の compact JWS。payload 全体が署名で覆われる。

```
header:  { "alg": "Ed25519", "kid": "<kid>", "typ": "webhook+jwt" }
claims:  {
  "iss": "https://s2.example",            # R の設定に iss があれば完全一致
  "aud": "https://s1.example/hooks/s2",   # S が発行した値、既定は endpoint URL
  "iat": 1760000000,
  "exp": 1760000030,                      # iat + 30 秒
  "jti": "<ランダム、送信試行ごとに一意>",
  "event": { ... }                        # アプリの payload
}
```

- `exp` は **`iat` + 30 秒** (標準値)。Standard Webhooks の 5 分は retry queue の遅延込みの値で、**S が送信試行ごとに署名し直す**なら 30 秒で足りる。生成時に 1 回だけ署名して queue に積む実装では、1 回目の失敗後の再送が全部 `exp` 切れになるので、再署名が 30 秒の前提
- `alg` は fully-specified の `"Ed25519"` (RFC 9864)。`"EdDSA"` は曲線が多義なので使わない。Ed448 は環境が足りない。Ed25519 自体はどのプラットフォーム・言語でも困らない。**alg 選定判断基準日: 2026-10-27** (選定を変えたらこの日付も一緒に更新する)
- `typ` は専用値にして検証する。他用途の JWT (ログイン token 等) が webhook として通るのを防ぐ (RFC 8725)
- `jti` はリプレイ防止用で、送信試行ごとに新しくする。アプリの event id は claims 側に別に持ち、R の冪等処理はそちらで行う

## 検証 (R)

受信 path (または `iss`) から receiver 設定を引き、次の順で検証する。どれか 1 つ落ちたら 4xx で終わり、再取得や救済はしない。

1. `Content-Type` が `application/jwt`、body が compact JWS として parse できる
2. header の `alg` が許可リスト `algs` (今は `["Ed25519"]`) にある、`typ` が専用値、`kid` がある
3. receiver の `jwks_url` のキャッシュ (JWKS 全体) から `kid` を引く。無ければ再取得 (下記) して再度引き、それでも無ければ拒否
4. 署名を検証する
5. `exp` が未来 (ずれ許容 30 秒)、`iat` が過去かつ `exp - iat` が上限 (例 60 秒) 以内
6. `aud` が設定値 (既定は受け口 URL) と完全一致。`iss` は設定にあれば完全一致
7. `jti` が未使用。使用済みなら拒否。使用済み集合は `exp` まで保持する (メモリの上限を持ち、超えたら古い順に捨てる。捨てた分はリプレイ窓が縮むだけで安全側)

4〜7 の順序は、署名が通る前のクレームを一切信じないため。

## 鍵キャッシュと再取得 (R)

- キャッシュのキーは **`jwks_url`**、値は取得した JWKS 全体 (kid の集合)。起動時に全 receiver 分を取得する。失敗しても起動は続け、最初の受信時に再取得する
- **再取得に成功したら、その `jwks_url` のエントリを新しい JWKS で丸ごと置き換える** (載らなくなった kid は落ちる)。これが唯一の失効経路で、S が捨てた鍵を R が使い続けないため
- 未知 kid を見たら再取得する。ただし `jwks_url` ごとに**最小 interval (10〜30 秒)** を置く。未知 kid の連打で JWKS fetch を強制する DoS を抑える。interval 内の未知 kid は再取得せず拒否
- miss 時だけでなく**定期 (10 分程度) にも再取得する**。S の次鍵を切替前に拾い、失効も S 再起動から 1 周期以内に効く
- fetch は https のみ、タイムアウト (数秒)、サイズ上限 (数十 KB)、リトライは頑張らない (次の受信か定期で拾う)
- JWK は `kty: "OKP"`、`crv: "Ed25519"`、`use: "sig"` (あれば) を確認してから取り込む

## 信頼の連鎖

R が初期状態で信頼しているのは、設定 (`path` → `jwks_url`) と CA の 2 つだけ。設定への信頼で `jwks_url` が送り元の鍵置き場だと信頼する → `jwks_url` の TLS でその内容 (JWK) を信頼する → JWK で署名を信頼する → 署名で claims を信頼する → `aud` で「自分宛て」を、`jti` + `exp` で「初見で新鮮」を確定する。

S 側は、設定への信頼で `endpoint` が送ってよい URL だと信頼し、endpoint の TLS で相手を信頼する。S 側の認証はこれで閉じている。

## やらないこと

- **IP 許可リスト、共有 secret、鍵の手動配布**: 本方式の目的がそれらを持たないこと
- **署名失敗時の救済** (別の鍵で再試行、`alg` の緩和、`aud` 不一致の黙認): 拒否して S の再送に任せる
- **body 以外 (method / path / header) の署名**: `aud` が宛先を束縛するので十分。必要になったら RFC 9421 へ移る
- **detached JWS (RFC 7797 `b64: false`)**: body を平文 JSON に保てるがライブラリ対応が薄い。ログで読みたいなら R が検証後に claims をログに出す

## 関連

- [peer-auth-url-identity](peer-auth-url-identity.md) — ステートフル接続向けの同系統 (接続確立時に一度だけ認証)。`iss` / `aud` の完全一致、鍵空間の分離の考え方は共通
- [self-endpoint-identification](self-endpoint-identification.md) — R が `aud` の既定値 (自分の受け口 URL) を確定する手順
