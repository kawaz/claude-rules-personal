# 信頼するアプリと sandbox は登録ドメイン (eTLD+1) を分ける

信頼するアプリ本体と、信頼しないコンテンツ (JS 付きの HTML プレビュー等) を同じホスト群で配る時は、サブドメインでなく登録ドメイン (eTLD+1、registrable domain) を 2 本に分ける。

## サブドメイン分離で抜けるもの

`ccmsg.myhost.example.com` と `ccmsg-files-{hash}.myhost.example.com` は origin は別だが site (eTLD+1) は同じ。ブラウザの境界は 2 種類ある。

- **origin 境界** (scheme + host + port): localStorage / IndexedDB / DOM アクセスはここで切れる
- **site 境界** (eTLD+1): SameSite cookie、cookie の `domain` 属性、WebAuthn の registrable suffix はここで切れる

サブドメインで分けただけでは site 境界が同じままなので、次の 3 つが全部抜ける。

1. **passkey の窃取**: RP ID を `myhost.example.com` にすると、全サブドメインから registrable suffix として使える。信頼しないプレビュー内の JS が `navigator.credentials.get({rpId: "myhost.example.com"})` を呼べ、偽 UI で TouchID を踏ませれば assertion を取得できる
2. **cookie tossing**: sandbox 側から `document.cookie = "sid=...; domain=.myhost.example.com"` を書ける。セッション固定攻撃になる
3. **SameSite の無効化**: 同一 site 扱いなので `SameSite=Lax` / `Strict` が CSRF 防御にならない

## 解

| 用途 | ドメイン | 例 |
|---|---|---|
| 信頼するアプリ本体 | `*.apps.example.com` | `ccmsg.apps.example.com` |
| 信頼しないコンテンツ (sandbox) | `*.sandbox.example.net` | `ccmsg-files-{token}.sandbox.example.net` |

- `*.apps.example.com` と `*.sandbox.example.com` は site がどちらも `example.com` で、何も解決しない
- 末尾の登録ドメインが違えばよい (`.com` / `.net` / 別の名前、どれでも)
- GitHub の `githubusercontent.com`、Google の `googleusercontent.com` と同じ構図。ドメイン 1 本分の年額コストで、上の 3 つの穴が構造的に消える

## 不変条件

apps ドメインには信頼するアプリしか置かない。信頼しないコンテンツを apps ドメインのサブドメインで配ると、そのコンテンツと apps ドメインの間で上の 3 つが開く。
