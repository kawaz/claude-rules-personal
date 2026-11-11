# artifacts-share の置き場を作る・トークンを作り直す

[share](../share.md) が使う R2 バケット・API トークン・キーチェーンの 2 項目を用意する手順。バケットの作成・ルール・公開の切り替え・トークンの作成は、kawaz のログイン (`cf auth login` 済みの `cf` = Cloudflare CLI) で行う。ログインが切れていると `Could not refresh your stored OAuth token` になるので、そのときは kawaz に `! cf auth login` を頼む (エージェントが自分で再ログインしない)。

## 値の扱い

- トークンの値は**表示しない・コマンドの引数に出さない・ファイルに書かない**。`cf user tokens create` の応答を変数に受け、`security -i` の標準入力でキーチェーンに入れる (`security add-generic-password -w <値>` と書くと `ps` に出る)。`$(…)` で受けた値を echo しない
- アカウント ID・バケット名・公開ドメイン・トークンの id は秘密ではないが、公開リポには書かない。キーチェーンの `settings` 項目にだけ置く

## トークンを作り直す (バケットはそのまま)

トークンが漏れた・失効したときはこれだけでよい。設定の `token_id` も新しい id に替える。

```bash
cfg=$(security find-generic-password -s artifacts-share -a settings -w)
A=$(jq -r .account_id <<<"$cfg"); B=$(jq -r .bucket <<<"$cfg"); jq -r '.token_id // "(なし)"' <<<"$cfg"   # 古いトークンの id (後で消す)
# 権限グループ Workers R2 Storage Bucket Item Write (オブジェクトの読み書き・一覧・削除) を、このバケット 1 つだけに
POL="[{\"effect\":\"allow\",\"permission_groups\":[{\"id\":\"2efd5506f9c8494dacb1fa10a3e7d5b6\"}],\"resources\":{\"com.cloudflare.edge.r2.bucket.${A}_default_${B}\":\"*\"}}]"
resp=$(cf user tokens create --name "artifacts-share ($B objects)" --policies "$POL" 2>/dev/null)
printf 'add-generic-password -U -s artifacts-share -a r2-token -w "%s"\n' "$(jq -r .value <<<"$resp")" | security -i >/dev/null 2>&1
NEW=$(jq -r .id <<<"$resp"); unset resp
security add-generic-password -U -s artifacts-share -a settings -w "$(jq -c --arg id "$NEW" '.token_id = $id' <<<"$cfg")"
security find-generic-password -s artifacts-share -a r2-token >/dev/null && echo "r2-token: 入った"   # -w を付けないので値は出ない
```

- アカウントのトークン (`cf accounts tokens`) は今のログインでは作れない (403)。ユーザーのトークン (`cf user tokens`) で作る
- 古いトークンは kawaz が Cloudflare のダッシュボード (My Profile → API Tokens) で消す。今のログインの `cf` はトークンを作れるが、一覧・更新 (無効化)・削除は 403 (`cf user tokens delete` も通らない)
- トークンに期限は付けていない。漏れたら上の手順で作り直し、古いトークンをダッシュボードで消す
- `security -i` の出力は捨てる (エラー時に入力の行をそのまま出すことがあるため)

## バケットから作る

```bash
B=<バケット名>
A=$(cf accounts list | jq -r '.[0].id')   # アカウント ID (アカウントが 1 つの前提。複数なら選ぶ)
cf r2 buckets create --name "$B"
# ルール: 途中で止まったアップロードの片付け (作成時からある) + ttl-1d〜ttl-30d + 全体 30 日
RULES=$(jq -cn '[{id:"Default Multipart Abort Rule",enabled:true,conditions:{},abortMultipartUploadsTransition:{condition:{type:"Age",maxAge:604800}}}]
  + [range(1;31) as $d | {id:"ttl-\($d)d",enabled:true,conditions:{prefix:"ttl-\($d)d/"},deleteObjectsTransition:{condition:{type:"Age",maxAge:($d*86400)}}}]
  + [{id:"all-30d",enabled:true,conditions:{prefix:""},deleteObjectsTransition:{condition:{type:"Age",maxAge:2592000}}}]')
cf r2 buckets lifecycle update "$B" --rules "$RULES" --force   # ルールの更新は全体の置き換え
D=$(cf r2 buckets domains managed update "$B" --enabled --force | jq -r .domain)   # r2.dev で公開。これが公開ドメイン
security add-generic-password -U -s artifacts-share -a settings \
  -w "$(jq -cn --arg a "$A" --arg b "$B" --arg u "https://$D" '{account_id: $a, bucket: $b, public_url: $u}')"
```

続けて上の「トークンを作り直す」を実行する (設定に `token_id` が入る)。

確かめる:

```bash
cf r2 buckets lifecycle get "$B" | jq '.rules | length'   # 32
security find-generic-password -s artifacts-share -a settings -w | jq .
```

最後に、artifacts workspace の下の検証用ディレクトリで `new` → 公開 URL を `curl -sI` → `prune` を通す。
