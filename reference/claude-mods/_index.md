# Claude Mods (function hooks)

Claude Code の plugin が持てる TypeScript / JavaScript の hook module。engine の event と描画を `($, e, next)` の middleware で書き換え、外界へは `$` を通して届く。

- [overview](overview.md) — plugin の構成、`register`、pattern と tier、`next`、失敗の扱い、他の拡張手段との差。
  mod の基本, hooks module の書き方, tier, fail open, command hook との違い, MCP との違い
- [develop](develop.md) — built-in mod 一覧、一時読み込み、validate / test / hot-reload、型定義。
  --plugin-dir, claude plugin validate, claude plugin test, reload されない, 型が合わない
- [events](events.md) — hook できる event の全一覧と選び方、1 turn の発火順、`-p` との差、`/clear` の意味論。
  event 一覧, 発火順, どの event で拾う, /clear を拾う, -p で動かない
- [capabilities](capabilities.md) — event ごとに読める・書き換えられる・文脈を足せる欄の表と、thinking の扱い。
  model に文脈を渡す, context を足す, additionalContext, 書き換えたのに効かない, 組織管理下で効かない, thinking を読む
- [practices](practices.md) — mod 設計の選び方: 計測単位、subagent の見分け、状態の置き場、skill と tool の分担。
  mod の設計, 状態をどこに持つ, skill と tool の分担, bundle, 公式 README が古い
- [dollar-api](dollar-api.md) — `$` の noun ごとのメソッドと制限、外部プロセスとの接続、`$.store`、state ライブラリ。
  $ で何ができる, $.store, $.http, $.process, 4 MiB, 予算
- [dialogs](dialogs.md) — permission 等のダイアログで読める・割り込める・返せるもの、deny rule との優先関係。
  permission ダイアログ, ダイアログを外から答える, deny rule が効く, Elicitation
- [prompt-injection](prompt-injection.md) — `$.prompt.submit` と `asUser` の使い分け、外からの入力投入、書きかけの退避・復元。
  prompt を外から入れる, 人の入力として送る, 書きかけの退避
- [lab-setup](lab-setup.md) — 隔離環境での起動・trust・debug log、全 event を記録する観測 mod、peer socket 送信。
  mod を試す, 隔離環境, --debug, 全 event を記録, uds-send
