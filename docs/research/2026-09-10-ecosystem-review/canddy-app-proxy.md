# エコシステムレビュー指摘 — canddy-app-proxy

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/10、一時 public 化で clone): 22 コミット (7/12〜8/16)。Caddy + tailscale + Let's Encrypt DNS-01 (Route53) で、Mac 上のローカルアプリ (ccmsg / hyoui / llm-gateway) を `*.<host>.kawaz.jp` (apps) と `*.<host>.tmpspace.net` (sandbox) の **2 本の eTLD+1** で wss 公開する基盤。設計文書 §3「サブドメイン分離では site 境界が同じままで passkey 窃取 / cookie tossing / SameSite 無効化が全部抜ける、登録ドメインを 2 本に分けろ」が核で、§7 (認証の二層構造、forward-auth ゲート不採用、RP ID = 親ドメインとその不変条件、Related Origin Requests 禁止、capability URL) と §7b (WebAuthn の落とし穴: origin を Host から組み立てない、同期パスキーの signCount = 0、BE / BS 記録) は、reference の `auth-patterns/` の前提そのもの。ACME 用 IAM を「TXT かつ `_acme-challenge.` 名前限定」まで絞っているのと、`tailnet_only` の理由 (macOS 非 root は特定 IP + port < 1024 の bind 不可 → 全 IF listen + remote_ip matcher) が Caddyfile のコメントに書かれているのは、インフラ設定リポとして珍しい水準。「localhost のポートで満足するプロダクトが大嫌い」の実体。

### CA-1 ★2 reference の passkey 文書と canddy §7 の間の不一致を解く

- 指摘: 同じ kawaz の設計なのに、後発 (reference / ccmsg DR-0001) と先行 (canddy §7) で 3 点が食い違う。(a) cookie: canddy は「セッション cookie は `__Host-` 必須 (domain 不可、path=/ 強制 → tossing 不可)」、reference は「`__Secure-` + Path を認証経路 prefix + 名前に発行者 id と sub のハッシュ」。(c) BE / BS: canddy §7b は「登録時・認証時に記録して同期鍵かデバイス束縛かを判別」、reference の検証手順には無い (R-8 で私が指摘した内容がここにあった)。(a) は eTLD+1 分離が tossing を構造的に封じているので `__Host-` でなくてよい、という判断だと思うが、書かれていない。library の件は乖離ではなく段階 (自作を上げ切ってからライブラリと比較する kawaz の流儀、P-4) なので除外
- 修正案: reference 側 (後発が正) を正本にし、(a) は「`__Host-` にしない理由: eTLD+1 分離で tossing は既に封じてあり、Path を認証経路に絞る方を優先」を cookie 節に 1 句、(c) は BE / BS の記録を検証手順に足す (R-8 に統合)。canddy §7 / §7b は「後発の設計は reference の passkey 文書が正本。ここには前段 (ドメイン・TLS・到達性) の設計だけを残す」と冒頭に書いて、§7 の passkey 実装部分を削るか reference へのリンクに置き換える。両方に残すと 3 か所目の乖離が出る

### CA-2 ★1 CLIProxyAPI (`cpamc-*`) の route が残骸

- 指摘: Caddyfile に `cpamc-*` の route が 4 か所、README に 3 か所。llm-gateway が CLIProxyAPI を置き換え済み (rules-personal も 9/9 に cliproxyapi 記述を削除) なので、`X-Forwarded-*` を全部削る特殊処理と `/management.html` への 302 は今は誰も通らない経路
- 修正案: route と README の節を削除。`X-Forwarded-*` を削る手法自体は「backend が X-Forwarded-For を real client と誤認する時の対処」として findings か memory に 1 行残す価値がある

### CA-3 ★1 public 化中の README の識別子

- 指摘: README に tailnet IPv4 / IPv6、Route53 zone ID、AWS account ID と role ARN、ホスト名がベタ書き。どれも単体で秘密ではない (zone ID / account ID は公開情報の類) が、`sanitize-local-paths` / `secret-hygiene` の判定軸「public に出るか」で見ると、一時 public 化の間はまとめて出ている。private に戻すなら問題なし
- 修正案: private に戻す。public を続けるなら tailnet IP と account ID を README から `docs/` の private 側か 1Password のメモへ移し、README は「値は運用ノート参照」に
