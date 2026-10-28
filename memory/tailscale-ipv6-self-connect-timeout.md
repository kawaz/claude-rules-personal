# macOS の Tailscale は自分の tailnet IPv6 へ自己接続できない

この Mac から自分の tailnet IPv6 (`fd7a:115c:a1e0:…`) の port へ `curl -6` / `nc -6` すると timeout する (2026-10-25 実測)。同じ port へ tailnet IPv4 (`100.x.x.x`) で自己接続すると通る。Caddy が `*:443` (dual-stack) で listen し cert も取れている状態でも同じなので、サーバ側でなく macOS の Tailscale (userspace) が自分宛 v6 を loopback しない制約。

IPv6 のみで到達する host (canddy の `*.v6-sandbox.kawaz.jp` 等) の疎通確認は、別の tailnet 端末 (iPhone 等) から行う。Mac 上の `curl -6` が timeout しても設定不備とは限らない。
