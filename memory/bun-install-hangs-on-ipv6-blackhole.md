# bun install が IPv6 断で止まる時の回避 (localhost レジストリ proxy)

症状: `bun install` / `bun add` が "Resolving dependencies" のまま止まる。`lsof -p <pid>` で registry (Cloudflare の 2606:4700::…) への TCP が `SYN_SENT` のまま。`curl -6 https://registry.npmjs.org/` は timeout、`curl -4` は 200 (= LAN の IPv6 上流が死んでいて RA だけ生きている状態)。

bun 1.3.x は IPv6 が黒穴でも IPv4 に fallback しない。`--dns-result-order=ipv4first` は install の fetch には効かない。`bun install --offline` はキャッシュに無い package では使えない。

回避: Node (v20+、happy eyeballs で IPv4 に落ちる) で localhost のレジストリ proxy を立て、bun に `--registry` で向ける。JSON 中の tarball URL も自分宛てに書き換える必要がある。

```js
// /tmp/bun-registry-proxy.mjs
import { createServer } from "node:http";
const UPSTREAM = "https://registry.npmjs.org";
const PORT = Number(process.argv[2] ?? 4873);
const SELF = `http://127.0.0.1:${PORT}`;
createServer((req, res) => {
  fetch(UPSTREAM + (req.url ?? "/"), { headers: { accept: req.headers.accept ?? "*/*" } })
    .then(async (upstream) => {
      const type = upstream.headers.get("content-type") ?? "application/octet-stream";
      if (type.includes("json")) {
        const text = (await upstream.text()).replaceAll(UPSTREAM, SELF);
        res.writeHead(upstream.status, { "content-type": type }); res.end(text); return;
      }
      res.writeHead(upstream.status, { "content-type": type });
      res.end(Buffer.from(await upstream.arrayBuffer()));
    })
    .catch((cause) => { res.writeHead(502); res.end(String(cause)); });
}).listen(PORT, "127.0.0.1");
```

```bash
node /tmp/bun-registry-proxy.mjs 4873 > /tmp/bun-registry-proxy.log 2>&1 &
bun add --registry http://127.0.0.1:4873 <pkg>
perl -pi -e 's{, "http://127\.0\.0\.1:4873/[^"]*\.tgz", \{}{, "", {}g' bun.lock   # tarball URL ごと既定表現 (空文字) に戻す。prefix だけ消すと `@types/bun/-/bun-1.4.2.tgz` のような相対値が残り CI の bun install が落ちる
bun install --frozen-lockfile --offline                  # "no changes"
grep -c 127.0.0.1 bun.lock                               # 0 を確認してから commit
kill %1; rm /tmp/bun-registry-proxy.mjs /tmp/bun-registry-proxy.log
```

lockfile の `127.0.0.1` を消し忘れると proxy の URL が commit される。恒久対策は IPv6 経路の修復 (`networksetup -setv6off Wi-Fi` で一時的に切るのも可、管理者操作)。
