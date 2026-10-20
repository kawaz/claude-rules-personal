# Claude Mods (function hooks)

Claude Code の plugin が持てる TypeScript / JavaScript の hook module。engine の event と描画を `($, e, next)` の middleware で書き換え、外界へは `$` を通して届く。

- [overview](overview.md) — plugin の構成、`register(on, options)`、pattern と matcher、tier、`next`、失敗と `.catch`、実行環境と時間予算、security モデル、command hook・MCP・skill との差分表。
  発火語: mod の基本, hooks module の書き方, tier, fail open, command hook との違い, MCP との違い
- [develop](develop.md) — built-in mod の一覧、一時読み込み、validate / test / hot-reload、型定義と tsconfig、noun の契約。
  発火語: --plugin-dir, claude plugin validate, claude plugin test, reload されない, 型が合わない
- [events](events.md) — hook できる event の全一覧、pattern での選び方、1 turn の実測時系列、対話と `-p` の差、`/clear` 等の意味論。
  発火語: event 一覧, 発火順, どの event で拾う, /clear を拾う, -p で動かない
- [capabilities](capabilities.md) — event ごとの能力表 (読める欄、書き換えられる欄、model に届く文脈を足す欄、pinned な欄) と、文脈を渡す時の event の選び方。
  発火語: model に文脈を渡す, context を足す, additionalContext, 書き換えたのに効かない, 組織管理下で効かない
- [practices](practices.md) — mod を設計する時の選び方: 計測の単位、main と subagent の見分け、状態の置き場、skill と tool の分担、境界での parse、実機で確かめる (公式文言が実装より古いことがある)。
  発火語: mod の設計, 状態をどこに持つ, skill と tool の分担, bundle, 公式 README が古い
- [dollar-api](dollar-api.md) — `$` の noun ごとのメソッドと制限、外部プロセスとつなぐ形、`$.store` の保存先、state ライブラリ。
  発火語: $ で何ができる, $.store, $.http, $.process, 4 MiB, 予算
- [dialogs](dialogs.md) — permission / AskUserQuestion / Elicitation / engine 自身のダイアログで読めるもの・割り込める点・返せるもの、deny rule との優先関係、待つ形。
  発火語: permission ダイアログ, ダイアログを外から答える, deny rule が効く, Elicitation
- [prompt-injection](prompt-injection.md) — `$.prompt.submit` と `asUser` の使い分け、外部からユーザプロンプトとして入れる手順、書きかけの退避・復元。
  発火語: prompt を外から入れる, 人の入力として送る, 書きかけの退避
- [lab-setup](lab-setup.md) — 別 `CLAUDE_CONFIG_DIR` と `env -i` による隔離環境、起動・trust・debug log の見方、観測 mod (全 event を JSONL に記録) と peer socket への直接送信スクリプト。
  発火語: mod を試す, 隔離環境, --debug, 全 event を記録, uds-send
