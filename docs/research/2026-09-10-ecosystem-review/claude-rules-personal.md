# エコシステムレビュー指摘 — claude-rules-personal

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

### R-1 ★3 `no-hard-wrap` を lint で検査する

- 指摘: 常時ロード rule 12/40、`reference/` + `memory/` 25 ファイルに文中改行が残る。今日 skill から移設した 25 ファイルは「触った」のに直っておらず、「触ったついでに直す」方針が履行されていない
- 修正案: `justfile` の `lint-rules` に (h) を追加。判定は「行末が `。` `:` `、` `)` `|` `` ` `` 等の句読点・記号でない行の直後に、見出し・箇条書き・表・コードブロック・空行以外の行が続く」を warning。対象は `for-*/rules` `reference` `memory` `skills` `agents`。fatal にはしない (既存の 37 ファイルが全部引っかかるため)
- 併せて: 方針を「一括 reflow を 1 回だけ許す」に変えて 37 ファイルを片付けるか、warning を見ながら触ったついでに直すかは裁定待ち。前者なら `no-hard-wrap.md` の「一括 reflow はしない」行を削る

### R-2 ★3 hook のテストを push gate に入れる

- 指摘: `hooks/tests/vcs-guide.test.sh` (27 件、実行して全 pass 確認済み) が `just push` の deps に無い。9/9 に vcs-guide.sh を 5 回改訂した日にこそ gate が要った
- 修正案: `test-hooks` recipe を追加し `push:` の deps に加える。`jq` 不在時は skip でなく fail (hook 本体は `jq` 不在で黙って exit 0 する設計なので、テストまで黙ると検出できない)
- 併せて: テスト冒頭コメント「許可リスト (/github.com/kawaz/) を通るパスに置く」は v0.8.2 で廃止した仕様への言及 (`no-historical-noise`)。「git 専用除外リストに載らないパス」に書き換える

### R-3 ★3 cmux-msg の残骸掃除

- 指摘: cmux-msg は未使用だが、`for-all/plugins.json` に `cmux-msg@cmux-msg` が残り、`reference/justfile/push-watch.md` と `_index.md` が `cmux-msg notify --self` を前提にしている。統括が読んで実行しようとして詰まる
- 修正案: `plugins.json` の行を削除。`push-watch.md` は ccmsg に同等の notify があれば書き換え、無ければ reference から外して `docs/issue/` に「ccmsg 側に notify --self 相当ができたら復活」として残す。`reference/justfile/recipes.md` の「bump-semver / cmux-msg / session-analysis の justfile が正本」も cmux-msg を外す
- 併せて: `for-me/rules/dogfooding-feedback-upstream.md` の cmux-msg 言及も確認

### R-4 ★2 `model-effort-matrix` から実測値を分離する

- 指摘: `knowledge-guide` は reference を「rule と同水準」と定めるが、この本文は「astra は sol の 2 倍コスト、未実測」「fable-medium が指揮では opus-high/xhigh より遥かに良い」「luna は xhigh にすると上位 tier と並ぶことが多い」等、モデル更新で腐る実測値と主観評価を含む。統括が起動時に必ず Read する
- 修正案: ファイルを 2 つに分ける。`model-effort-matrix.md` には残す: 自 tier 判定、禁則、選定の第一原則、課題の性質 × 選択の表、判定の分岐、agent 定義の固定方針、委譲プロンプト規約、監査側の禁則。`memory/model-observations.md` (または `docs/findings/`) に移す: 「モデル特性差」節の実測・主観部分。表の「選択」列が memory を参照しない形に保つ (表は判定、memory は根拠)
- 効果: 起動時 Read 量も減る (§R-6)

### R-5 ★2 `peer-auth-url-identity` に skew の扱いを戻す

- 指摘: 元文書 `claude-ccmsg/docs/design/mesh-peer-auth.md` §5 末尾にあった「`exp` は時刻同期に依存するが、新鮮さは challenge が担うので skew は可用性の問題」の段落が reference 抽出時に落ちた。元文書は「厳しすぎるなら緩めてよい」で、kawaz の裁定 (数秒以上ズレる相手は落としてよい) と向きが逆
- 修正案: 「前提」表に P5 を追加: 「各ノードの時刻が同期されている (数秒以内)。満たさない場合: `exp` 検証で落ちる。安全性は challenge が担うので `exp` を緩める方向には倒さず、ズレた相手を落とす」。「手順」の `exp` 説明にも 1 句添える

### R-6 ★2 統括の起動コストを別の数字として持つ

- 指摘: 実測 (`/context`) で起動直後 114.9k tokens、うち Memory files 38k (≈ rules 78.6KB)、Messages 26.3k (≈ role-main 経由の Read 36.7KB)。`lint-rules` の予算 81,920 bytes は rules だけを数える。1m 窓の 11% なので窓の圧迫ではなく、毎ターンの cache read と注意の分散の問題。掃除前の 130〜150k から約 30k 減っており、削れる母数 (System tools 43.5k を除く約 70k) の 3 割
- 修正案: `lint-rules` (f) の隣に (f2) として「role-main が Read する本文の合計」を warning 付きで出す (`reference/role-main/_index.md` の列挙を解いて `wc -c`)。線は現況 36.7KB を基準に「増えたら気づく」用途で引く (80KB 予算と同じ思想)。次に効くのは `main-role-playbook` と `model-effort-matrix` (R-4 で減る)

### R-7 ★2 `auth-patterns/` `cli-daemon-subcommands` の位置付けを「バックポート標準」として明示する

- 判明: これらは cache-warden (passkey 初出) / hyoui / llm-gateway / ccmsg と似た仕組みを作るたびに出た反省を、最新の ccmsg で 2 本にまとめ、先行プロジェクトへ打ち消し・バックポートする目的で書かれたもの。「2 系統」は意図的な過渡状態
- 指摘: その意図は reference 本文からも `_index.md` からも読めない。後発が「ccmsg 固有の設計」と誤読するか、逆に cache-warden の旧設計を正と誤読する。ccmsg の `mesh-tls-trust-root` が open のまま = 標準側もまだ動く
- 修正案: `knowledge-guide` に 1 行足す: 「reference の pattern は最新プロジェクトで得た形を標準として書き、先行プロジェクトの差分は各リポの issue (backport) で追う。reference 側に適用状況は書かない」。追跡は R-12 で持つ

### R-13 ★2 rule の廃止基準を持つ

- 指摘: rule の追加基準 (「この内容が context に無いターンで事故が起きるか」) はあるが、廃止基準が無い。38 本は増える一方で、今日の降格は「常時 → reference」の移動であって廃止ではない。「事故が起きなくなった」「モデル更新で不要になった」rule を外す判断がどこにも書かれていない。`self-written-rule-blind-spots` を rule 体系自体に当てると、追加側だけあって削除側が無い片面
- 修正案: `rule-writing-guidelines` に「廃止」節を 3 行: (1) 発火場面が N か月無い / 禁じた事故の記録が無い rule は降格か廃止の候補、(2) 廃止時は docs/journal に「なぜ要らなくなったか」を 1 行、(3) 半年に 1 回 fleet-audit で全 rule を「最後に効いた記憶があるか」で棚卸し。計測 (R-6 / S-1) が無いと (1) は主観になるので、まず ccmsg dump で「rule 名が thinking / 応答に出た回数」を数えるのが安い代用

### R-14 ★2 rule と「踏んだ事故」の逆引き

- 指摘: rule の根拠 (実際に起きた事故) が findings / journal / hyoui の CLAUDE.md「Anti-patterns」/ ccmsg DESIGN の「旧 daemon で計測された偏り」に散っていて、rule 側から辿れない。`sloppy-ai-patterns` だけが症状カタログとして事故を内包している。P-8 の「禁則には踏んだ実例を 1 行添える」の体系側
- 修正案: 各 rule の末尾に `根拠: <findings / journal / issue へのリンク 1 つ>` を置く (bytes は 1 行 60 前後 × 38 = 2.3KB、予算内)。無い rule は「根拠: 予防 (事故未発生)」と書き、R-13 の廃止候補の第一順位にする。lint (j) で `根拠:` 行の有無を warning

### R-15 ★1 rule の節構成の最小型を定める

- 指摘: 38 本のうち `## Why` を持つのが 10、`## How to apply` が 16、対極節が 11 で、節構成は不統一。`rule-writing-guidelines` の記述原則 (具体的 / 省コンテキスト / リンク規約) は文の書き方を定めるが、節の型を定めていない。統一のために節を足すと肥大するので、型は最小形で定めるべき
- 修正案: 型を「禁則 (1〜3 行) / 対極 (1 行、無ければ書かない) / reference 誘導 (1 行、あれば) / 根拠 (R-14)」の 4 要素とし、`## Why` は reference か根拠リンクへ移す方針を guidelines に 1 段落。既存 rule は触ったついでに寄せる (一括改稿はしない)。`_index.md` の降格判断 (findings 2026-09-09 の最大項目) はこの型が決まってから

### R-16 ★1 itumono-review-{claude,codex,gemini} の skill 残置

- 指摘: findings は 3 本を「境界例 (推し: reference)」としたが、`/名前` で直接起動できる経路を残すために skill に残った。中身は外部 CLI の呼び方で、`itumono-full-review` が読む素材。起動経路のためだけの skill が 3 本 (計 6KB、description は常時 context)
- 修正案: 直接起動の実績が無ければ reference (`agent-runtime/external-review-cli.md`) へ移し、`full-review` からパスで参照する。実績があるなら現状維持で、findings の境界例の記述を「裁定: 残す、理由: 直接起動する」に更新して閉じる

### R-12 ★1 [時期: ccmsg 安定後] バックポート追跡 issue を rules-personal に 1 本立てる

- 修正案: `docs/issue/2026-09-09-backport-patterns.md` を起票し、pattern × リポの表を持つ:

| pattern | cache-warden | hyoui | llm-gateway | ccmsg |
|---|---|---|---|---|
| cli-daemon-subcommands | `daemon register` が `service register` 相当。`supervise` 無し (CW-2) | `run --detached` / `serve` の独自体系。unit = session なので適用範囲の判断が要る (H-3) | 準拠 (元ネタ、DR-0028) | 準拠 |
| passkey-registration-local-first | 旧設計 (WebRTC + GitHub Pages rpId、向きが逆) を打ち消す候補 (CW-1) | 対象外 | 対象外 (web 再認証は別物か要確認) | 標準の出所 |
| peer-auth-url-identity | 対象外 | 対象外 | 対象外 | 標準の出所 (`mesh-tls-trust-root` open) |
| self-endpoint-identification | 対象外 | 対象外 | 対象外 | 標準の出所 |

- 各リポ側の issue (CW-1 / CW-2 / H-3) からこの表へリンクし、閉じたら表を更新。reference 本文は触らない

### R-8 ★1 `auth-patterns` の本文の小さな穴

- `passkey-registration-local-first.md`:
  - `__Secure-` を選び `__Host-` にしない理由 (Path を認証経路 prefix に絞るため。`__Host-` は `Path=/` 必須) を cookie の箇条書きに 1 句足す
  - access token を `Sec-WebSocket-Protocol` に載せる形が、jwt を fragment で運ぶ思想と非対称に見える。「短命かつメモリ内なので header 露出を許容」の 1 句を足す
  - `topOrigin` の拒否は `crossOrigin: true` の拒否に含意される。残すなら「明示のため」と添えるか、削る
  - 「library は要らない」の代償として、検証手順の表に authData flags (BE/BS) と extensions の扱いを足す (無視する、と書くだけでよい)
- `self-endpoint-identification.md`: 適用範囲外に「設定に載る正規 peer が悪意を持てば起動を阻止できる (可用性への攻撃)。設定に載せる相手を信頼することが前提」を 1 行
- `cli-daemon-subcommands.md`: 「開発中 / `service` 未登録時は `daemon run` で foreground。`daemon start/stop` は supervise 起動後にのみ意味を持つ」を 1 行。今は行間からしか読めない

### R-9 ★1 lint に hook 参照パスの存在検査を足す

- 指摘: `vcs-guide.sh` が名指しする `reference/vcs/*.md` 7 本は今回全部存在したが、移設が続く間は切れる
- 修正案: `lint-rules` (i): `hooks/*.sh` から `\$ref_dir/[a-z_-]+\.md` を抽出し `reference/vcs/` に存在するか検査。fatal

### R-10 ★1 `vcs-guide.sh` の `git -C` 検出

- 指摘: `tooling-tips` が `git -C` を禁止しているので整合は取れているが、禁止を破った時こそ案内が要る場面で、この形だけ検出から漏れる
- 修正案: `cd` 解決と同じ場所に `git -C <path>` の分岐を足し、`<path>` を target にする。テストに 1 件追加

### R-11 ★1 `design-thinking.md` の hard-wrap

- 「思考設定」節の「本節の手動\n複製」が文中改行。R-1 の象徴例なので単独でも直す。userPreferences との内容一致は確認済み (drift 無し)
