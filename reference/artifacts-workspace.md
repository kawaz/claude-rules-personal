# artifacts workspace — 生成物をブラウザで見る置き場と URL 対応

Claude セッションが作る HTML / JS / 画像などの生成物を、各リポの `artifacts/` に置いてブラウザ (tailnet 内の任意デバイス) で閲覧する仕組み。置き場 (jj workspace) と配信 (canddy-app-proxy) の 2 層から成る。

## 置き場: `{repo}/artifacts/` (jj workspace)

`~/.local/share/repos/github.com/{owner}/{repo}/artifacts/` は colocate リポ (レイアウトは reference の `vcs/jj-colocate-setup`) の恒久 workspace。作り方は 3 行:

```bash
cd ~/.local/share/repos/github.com/{owner}/{repo}/main
jj workspace add -r 'root()+ & ::main' ../artifacts
cd ../artifacts && printf '*\n' > .gitignore && jj file track --include-ignored .gitignore && jj commit -m "artifacts: 既定で追跡しない枝 (残す物だけ jj file track --include-ignored)" .gitignore
```

- 枝は main 本編の**最初の commit** から生やす別枝。main の履歴に生成物を混ぜない。bookmark は作らず push もしない (ローカル枝。新規リポ作成手順にも組み込み済み、既存 colocate リポは 2026-10-10 に一括作成済み)
- `.gitignore` は `*` 1 行。既定では何も追跡しない (jj の snapshot にも乗らないので、巨大ファイルや作り直しで store が肥大しない)
- 版管理して残したい物だけ `jj file track --include-ignored <paths>` → `jj commit -m "..." <paths>`。**`--include-ignored` を落とすと exit 0 のまま何も起きない**
- 中に symlink を置かない (file_server が追って配信してしまう)
- 置くファイルの名前は URL になるので、`index.html` を各ディレクトリに置くと `/<dir>/` で開ける。無いディレクトリは一覧 (browse) が出る

## 配信: `artifacts-{owner}-{repo}.<host>.tmpspace.net`

canddy-app-proxy (kawaz/canddy-app-proxy の `Caddyfile`、sandbox block) が Host 名からディレクトリへ写像する:

| URL | 実体 |
|---|---|
| `https://artifacts-{owner}-{repo}.kawaz-mbp16-20211217.tmpspace.net/{path}` | `~/.local/share/repos/github.com/{owner}/{repo}/artifacts/{path}` |

例: `https://artifacts-kawaz-hyoui.kawaz-mbp16-20211217.tmpspace.net/bench/index.html` → `.../kawaz/hyoui/artifacts/bench/index.html`

- Host は `artifacts-` の後の**最初の `-` で owner と repo に分かれる** (owner にハイフンを含まない前提。repo はハイフン可)。repo 名に `.` を含むリポ (`kuu.mbt` 等) は hostname のラベルに `.` を入れられないため現状未対応
- tailnet 内からのみ到達可 (`tailnet_only`)、ACME のワイルドカード証明書なので DNS 操作・証明書発行は不要
- `tmpspace.net` 側 = **非信頼コンテンツ用の sandbox site**。`kawaz.jp` 側のアプリ群と eTLD+1 が違うので cookie / passkey / storage を共有できず、生成物の JS が信頼アプリへ届かない。リポごとに origin も分かれるので生成物同士も隔離される
- dot path (`/.jj/`、`/.gitignore`、`/foo/.secret`) は 404 で、一覧にも出ない
- `Cache-Control: no-cache` なのでファイルを書き換えたら reload で反映。Caddy の reload は不要

## いつ使うか

- 画面を伴う成果 (可視化、レポート HTML、eli5 の図、ベンチ結果、スクリーンショット集) を kawaz に見せたい時。チャットにパスを書く代わりに URL を書く
- PoC の UI を手元のブラウザや iPhone で触ってもらう時
- 使わない場面: 本番の webui や daemon の配信 (apps 側の site block に個別追加する)、外部由来の HTML を他人に公開する用途 (tailnet 限定が前提)
