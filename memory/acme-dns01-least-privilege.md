# ACME DNS-01 用の IAM は対象ゾーンと TXT の `_acme-challenge.` 名に絞る

Route53 で ACME DNS-01 を通す IAM role は、対象ゾーン限定にしたうえで `ChangeResourceRecordSets` を条件キーで絞る。

- `route53:ChangeResourceRecordSetsRecordTypes` で TXT だけに限る
- `route53:ChangeResourceRecordSetsNormalizedRecordNames` で `_acme-challenge.<証明書の名前>` だけに限る (ワイルドカード証明書なら `_acme-challenge.*.` 側の名前も入れる)
- `ListResourceRecordSets` / `GetHostedZone` も対象ゾーンの resource に限る。`ListHostedZones*` / `GetChange` は resource で絞れないので `*`
- role の信頼を MFA 必須にした場合、証明書の更新 (Let's Encrypt なら約 60 日ごと) のたびに MFA の供給元 (1Password の `credential_process` 等) へのアクセスが要る
- 実例の構成は caddy-app-proxy リポの README の IAM 節
