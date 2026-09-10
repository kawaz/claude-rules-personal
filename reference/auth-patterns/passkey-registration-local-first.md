# 登録をローカルに閉じる passkey 設計

自分で立てた daemon の web 入口を「誰が来たか」で守る時、passkey を使い、**登録の起点をホスト上の CLI にだけ置く**設計。前段の proxy や外部 IdP に認証を寄せず、daemon 自身が判定する。リモートからの登録経路も復旧経路も持たないことが安全性の根になる。

## 最低限のプロトコル

1. ホスト上の CLI が登録用の URL を 1 つ発行する。URL は `<webui の origin と path>/#register=<jwt>`。claims は `{ iss (発行 instance の id), sub (利用者の識別子), endpoint (登録を受ける入口の URL), rp_id, user_id, exp (10 分程度), jti }`
2. jwt の署名は **登録ごとに生成する乱数 secret による HMAC**。検証者が発行者自身なので公開鍵は要らず、secret は発行 instance のメモリにだけ置いて `exp` で捨てる。永続鍵を持たない
3. jwt は **fragment (`#`) で運ぶ**。fragment は server にも proxy log にも Referer にも乗らない
4. ページは `/auth/challenge` で challenge を取り、`navigator.credentials.create()` を呼ぶ (`residentKey: "preferred"`、`userVerification: "required"`、`user.id` = jwt の `user_id`、`rp.id` = jwt の `rp_id`)
5. できた credential と jwt を jwt の `endpoint` の `/auth/register` に POST する
6. 受けた側は jwt を HMAC で検証し、WebAuthn の登録検証を通し、**通ってから jti と challenge を消費する**。順序が逆だと、ブラウザ側の一時的な失敗 1 回で登録 URL が焼ける
7. `{ sub, credential id, COSE 公開鍵, user_id, 登録時刻 }` を credential record として保存する

attestation は `none` で足りる。「この credential を作ってよい人か」は jwt が既に担保しており、authenticator の出自証明は要件に無い。attestation を要求すると証明書チェーンの検証と信頼リストという管理対象が増えるだけになる。

発行 instance が再起動すると secret が消えて登録は失敗する。fallback は置かず、CLI で URL を発行し直す (エラー文言も「登録 URL を再発行してください」にする)。

## RP ID の制約

WebAuthn の RP ID は origin ではなく **domain** で、credential は「今開いているページの effective domain か、その registrable suffix」でしか作成・利用できない。

- 既定の `rp_id` は入口の URL のホスト。これは webui が入口と同じホストから配られている構成を意味する
- webui を別サブドメインに置くなら、共通の registrable domain を `rp_id` に渡す。server 側は「`rp_id` が入口のホストと一致するか、その registrable suffix である」ことだけを検証する
- `clientDataJSON.origin` の期待値は入口の origin ではなく **webui の origin 集合**。ページを配っている場所が origin を決める
- `crossOrigin` は **`true` のときだけ拒否**する。Chrome 系は最上位フレームでも常に `false` を送るので、「present であること」を要求してはならない
- `topOrigin` は present なら拒否する (iframe 内からの登録・認証を許さない)
- 同じ RP ID の入口が複数あっても (`https://h.example/` と `https://h.example/personal`) credential は 1 つで足りる

## 検証手順

登録 (WebAuthn L2 §7.1):

1. `clientDataJSON.type` が `webauthn.create`
2. `challenge` が発行した値
3. `origin` が webui の origin 集合に含まれる
4. `crossOrigin` が `true` でない、`topOrigin` が無い
5. `authData.rpIdHash` が `sha256(rp_id)`
6. UP と UV の flag が立っている (UV は必須にする)
7. `fmt` が `none` で `attStmt` が空
8. credential id が既存 record と重複しない

認証 (§7.2):

1. `type` が `webauthn.get`
2. `challenge`、`origin`、`crossOrigin`、`topOrigin`、`rpIdHash`、UP / UV は登録と同じ
3. `userHandle` が record の `user_id` と一致する
4. 署名 (`authData || sha256(clientDataJSON)`) を ES256 (加えて RS256 / Ed25519) で検証する
5. signCount は **record の値が非 0 なら「提示値 > record」を要求**する (提示 0 も退行として拒否)。record が 0 なら提示値をそのまま保存する。同期される passkey は常に 0 を返すので、0 のまま据え置く経路が要る
6. `authenticatorData` の flags のうち **BE (backup eligible) / BS (backup state) を登録時・認証時ともに record へ記録**する。同期 passkey (BE=1) かデバイス束縛 (BE=0) かが保守 UI の手がかりになる。signCount が常に 0 なのが同期 passkey の常態であることは、BE=1 と対で読むと説明が付く。BE / BS は認証の可否判定には使わない (手がかりに留める)

`user_id` (WebAuthn の user handle) は **server が sub ごとに 1 度だけ決めた 16 byte の乱数**を使い回す。authenticator は handle を server の手の届かない場所に保存するので、同じ人に 2 つの値を配ると端末上で 2 つのアカウントに見える。同じ sub への追加登録では既存の handle を再利用する。

WebAuthn の検証に library は要らない。必要なのは小さな CBOR decoder (attestationObject と COSE 鍵) と WebCrypto (署名の verify、sha256、HMAC) だけで、library を入れると attestation の固定や challenge の転送のような細かい制御が効かなくなる。

## token は署名しない opaque 値

access / refresh token は署名せず、乱数 (base64url) を **token family** に入れて保存し、検証は lookup で行う。署名鍵を持つと保管・rotate・配布という管理対象が増えるが、record を引く形なら同じことが鍵なしで済む。

- family = `{ id, sub, iss (mint した instance), access: { value, exp }, refresh: { value, exp }, 退役世代の記録 }`
- **access はブラウザのメモリにだけ置き**、WebSocket の handshake に subprotocol (`<名前空間>.token.<値>`) で載せる。server は選んだ subprotocol を echo する。proxy が `Sec-WebSocket-Protocol` を透過することが要件になる
- **refresh は httpOnly cookie**。名前は `__Secure-` prefix + 「発行者 id と sub のハッシュ」(同じブラウザが複数の instance / 利用者を持てるように)、`HttpOnly; Secure; SameSite=Strict`、`Path` は認証経路の prefix。**`Path` は認可境界ではない** (同一 origin の JS は任意のパスに fetch できる)。絞るのは帯域と露出面のため
- **`__Host-` prefix ではなく `__Secure-` + `Path` を選ぶ**。同一ホストの別パス prefix (`https://h.example/` と `https://h.example/personal/`) を別の入口 (= 別登録) として扱うには cookie を `Path` で分ける必要があるが、`__Host-` は `Path=/` を強制するのでそれができない。`Path` が認可境界にならない以上この分離は帯域・露出面の絞り込みに留まり、cookie tossing (他ホストが同名 cookie を broader な `Path` で上書きする攻撃) は eTLD+1 の分離 (信頼するアプリと sandbox で登録ドメイン自体を分ける) で構造的に封じるのが前提になる
- localStorage には置かない。XSS 1 つで長期 token が抜ける

### rotate と再利用検知

refresh は使うたびに rotate する。family は **退役した値のダイジェストを、その値本来の exp まで保持**し、**どの世代の値でも再提示を見たら family ごと失効させる**。直前 1 世代だけは再送の猶予として、猶予時間内に限り前回の答えを返す。

family を書けるのは **mint した instance だけ (単一 writer)**。複数 instance で並行に rotate すると、LWW で複製した時に合流で片方が消え、再利用検知が誤発火する。失効は record の削除ではなく **tombstone** にして複製する — 削除だと、分断中の peer が持っていた生きた写しが復帰時に新しい書き込みとして戻ってくる。

同じ人が複数のページを開いている時、access を 1 本に保ったまま refresh する手順は `multi-tab-token-refresh` を読む。

### 接続の期限

認証済みの長命接続には access token の `exp` を接続の期限として持たせ、クライアントは `exp` の前に refresh して **同じ接続上の refresh op で期限を延ばす**。切断はしない。`exp` で必ず切ると画面が周期的に瞬く。切るのは延長を怠った接続だけで、切られた側は refresh → 再接続、refresh も無効なら passkey で認証し直す。

## 複数 instance に複製する

credential record と token family を peer 間で複製すると、どの instance に来た利用者も認証できる。ただし **発行者にしか無いもの**があり、それを受けた instance は発行者へ問い合わせる (問い合わせは instance 間の転送経路に載せる)。要るのは 3 場面だけ:

| 場面 | 発行者にしか無いもの |
|---|---|
| 登録 jwt の検証 | HMAC secret |
| WebAuthn の challenge の消費 | challenge の在庫 |
| token family の rotate | 単一 writer の権限 |

challenge には **発行者の id を埋める**。これで LB の裏で発行と応答の instance が違ってよくなる (応答を受けた側が assertion を検証し、challenge の消費だけを発行者に頼む)。同じ理由で、後述の 6 桁コードは **受けた側が判定せず、そのまま発行者へ運ぶ** — 受けた側が判定すると試行回数が instance ごとに別々に数えられ、cluster 全体に推測をばら撒ける。試行回数は 1 箇所で数える。

record を汎用の kv に載せてはならない。利用者 role が読み書きできる場所に置くと token がそのまま漏れ、record の改竄で権限昇格ができる。role を instance に限定した専用の複製先を持つ。

## 保守情報 — 「記憶の手がかり」は認証の材料ではない

デバイス一覧 / セッション一覧のような保守 UI が持つべき情報の一般則。

**名前は 2 つあり、意味が違う。** 発行時に管理者が付ける「誰宛に発行したか」のラベルと、登録ページで利用者が付ける「どの端末か」のラベル。前者は jwt に載せ、後者は UA から既定値を作って利用者に直させる。複数端末を持つ利用者が自分の一覧を保守できるのは後者があるからで、片方だけでは足りない。

**登録時と最終利用時の `{ 時刻, IP, User-Agent }` は認証の材料ではなく、記憶の手がかりである。** IP が正しいことを検証するのではなく、利用者が一覧を見て「自宅のプロバイダの IP だから自分だ」「この時刻は自分が登録した」と思い出せれば足りる。手がかりとしての精度でよいので、利用者が許可すれば都市レベルの位置情報を足すのも有効。逆に、これらを認証の判断に使い始めると、IP が変わっただけで締め出す・偽装した UA を信じる、のどちらかに転ぶ。

## 任意のゲート (層として独立に積む)

上の最低限プロトコルの上に、独立して積める確認。どちらも「無くても成立する」層として設計する。

### (a) CLI が提示する 6 桁コード

CLI が URL とは**別に** 6 桁のコードを表示し、ページがそれを入力して登録要求に添える。URL とコードが別経路でブラウザに届くので、URL が漏れただけでは登録にならない。

- **試行回数の上限 (3〜5 回でその URL を失効) が無いと総当たりで無意味になる。** コードは jti に束縛し、回数は発行者だけが数える
- jwt から導出したコードを CLI とページの両方に表示して**目視照合させる形は採らない**。それは「端末が CLI の隣にある」確認にしかならず、URL を持っている相手を排除しない

### (b) ホスト PC の生体認証による承認

登録要求を受けても完了させずに保留し、CLI 側で OS の生体認証 (macOS なら LocalAuthentication 等) を要求する。承認画面には **これから登録する credential の内容 (名前 / 端末 / コード / 時刻) を提示する** — 何に同意したかと実際に起きることが一致していなければ (WYSIWYS)、承認は署名として意味を持たない。承認は `create()` が返った後の credential id に束ね、別の要求にすり替わらないようにする。離席中の第三者による登録を防ぐ層で、承認の起点を CLI に置くのは登録がローカルに閉じている性質をそのまま延ばすため。

**守れる範囲を正直に書くこと。** 同じ uid で操作できる第三者は daemon 自体を書き換えられるので、これは「通りすがりが飛ばせない確認」であって完全な境界ではない。境界にしたいなら、承認を **署名済みの別 helper プロセス** (hardened runtime、鍵は Secure Enclave 等) に置き、daemon 側は helper の署名を検証する形にする。

## 不採用

| 案 | 理由 |
|---|---|
| 人の認証を前段 (forward auth / VPN の identity) に寄せる | 前段の構成が利用者ごとに違い、daemon が「誰か」を知る形が揃わない。passkey なら daemon 自身が判定でき、前段は透過でよい |
| instance の永続鍵で token を署名する | 鍵の保管・rotate・配布という管理対象が増える。record の lookup + 発行者への問い合わせで同じことが鍵なしでできる |
| token を localStorage に置く | XSS 1 つで長期 token が抜ける。httpOnly cookie なら JS から読めない |
| WebAuthn の library を入れる | attestation の固定や challenge の転送といった制御が効かなくなる。検証手順自体は短い |
| リモートからの登録・復旧経路 | 登録がローカルに閉じることが、この設計の安全性の根そのもの |
