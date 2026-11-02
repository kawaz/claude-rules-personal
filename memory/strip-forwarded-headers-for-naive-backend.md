# backend が転送ヘッダを real client と誤認するなら reverse proxy で全部剥がす

backend が `X-Forwarded-For` 等を本物の client 情報と取り違えて認可やログを誤る時は、Caddy の `reverse_proxy` で転送ヘッダを全部剥がして素の接続 (127.0.0.1 からの直接接続) に見せる。

```caddyfile
reverse_proxy 127.0.0.1:8080 {
	header_up -X-Forwarded-For
	header_up -X-Forwarded-Proto
	header_up -X-Forwarded-Host
	header_up -X-Real-IP
	header_up -Via
	header_up -Forwarded
}
```
