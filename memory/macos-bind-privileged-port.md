# macOS で特権 port を特定 IP に bind できない時は全 IF listen + remote_ip で絞る

macOS は非 root プロセスに「特定 IP + port < 1024」の bind を許さない (ワイルドカード bind だけ許す)。tailnet IP 等へ bind を固定して到達性を絞る設計は、非 root のままでは 443 / 80 で成り立たない。

- 全インターフェースで listen し、送信元 IP の matcher を一次防御にする (Caddy なら `remote_ip` matcher + `abort`。例は caddy-app-proxy リポの Caddyfile の `tailnet_only` snippet)
- root の LaunchDaemon にして特定 IP に bind するより安全側。root で動かすと `~/.aws` 等の秘密に root で触ることになる
- Caddy では `abort` が既定順序で `handle` / `reverse_proxy` より後に評価されるので、global options に `order abort first` を置く。無いと host に一致した要求が送信元検査に届かず応答する
