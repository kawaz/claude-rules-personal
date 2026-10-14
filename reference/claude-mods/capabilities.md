# Claude Mods の event ごとの能力表

event ごとに、hook が `e` から何を読めて、`next(e)` が何を返し、結果で何を書き換えられて、model が読む文脈を足せるかを 1 行で引く表。根拠は Claude Code 2.1.299 が書き出した型定義 (`EngineEventOf` / `OpEventOf` / `ClassicEventOf` と各 `*Input` / `*Result` の doc コメント)、公式リポの built-in mod のソース (実例)、2.1.299 の実機確認。event の一覧と発火順は reference の `claude-mods/events`、`$` のメソッドと制限は `claude-mods/dollar-api`、ダイアログまわりの実測は `claude-mods/dialogs`。

## 読み方

- **配置**: 1 つの hook での置き方 (overview の before / after / during / instead / modifying)。表の「書き換え」列は、その event で意味を持つ配置と、そこで変えられる欄を書く
  - modifying: `next({ ...e, x })` で下に渡す `e` を変える
  - after: `await next(e)` の結果を変えて返す
  - instead: `next` を呼ばずに自前の結果を返す
  - during: `next(e)` を走らせたまま別の契機を待つ (pending のまま返すと下が abort される event がある)
  - 観測のみ: 違う値を返しても engine の動作は変わらない
- **pinned**: 型定義で「書き換えると拒否される / 無視される / 戻される」と書かれた欄。modifying で変えられない
- **model に届く**: 結果や `e` のどの欄に書くと model が読む文脈になるか。「—」は足せない。既存の文 (system prompt の節、attachment、tool の説明) を置き換えられるだけのものはそう書く
- **出典**: 無印は型定義の記述。実機で確かめたものは「実測:」を付ける (すべて 2.1.299)。どちらでも決まらないものは「未確認」
- 全 event 共通: 失敗した hook (throw・予算超過・型の違う答え) は飛ばされ、下の hook と core が代わりに走る。拒否する guard は `.catch` を付けないと素通しになる (overview)。`next(e)` が答えた後に拒否 (`{ deny }` / `{ drop }`) を返すと、拒否ではなく hook の失敗として名指しで報告される event がある (`config.set` / `state.set` / `env.set` / `agent.spawn` / `prompt.submit`)
- 組織が管理する機械では built-in `sec-default` が最外に座り、`classic.*`・`prompt.section` / `prompt.context` / `prompt.attachment` / `prompt.compose`・`skill.prompt`・`attribution.text`・`session.compact`・`settings.read` と `session.append` の一部の door で、user tier (人が install した mod と `--plugin-dir`) の hook を飛ばす。下の表で「model に届く」口の多くがそこでは効かない (overview の `sec-default` 節)
- `tool.check` / `prompt.compose` / `prompt.autocomplete` は、どれかの plugin が hook している時だけ engine が上げる

## engine の event

| event | `e` の主要な欄 | `next(e)` の結果 | 書き換え (配置) | model に届く | 備考 |
|---|---|---|---|---|---|
| `tool.call` | `tool`, `tool_use_id`, tool の引数 (平たく、名前を修復した後の実際に走る引数), `agentId?`, `requestMeta?`, `consent?` | `{ ref, result, text, context?, isReadOnly? }` / `{ isError: true, result, text }` / `{ deny }` | modifying: 引数 (`tool` / `tool_use_id` / `agentId` は書き換えられない)、`requestMeta` (MCP request の `_meta` に載る `anthropic/sources` だけ)。instead: `{ deny }` / `{ result }`。after: 結果の差し替え、`{ deny }` (実行済みは戻らず、model には `<tool> ran, and a plugin withheld its result: <text>` が届く)。during: pending のまま返すと下が abort | 結果の `context: readonly string[]` (after。10 万字を超えると先頭と path)。実測: PostToolUse hook と同じ reminder として届き、transcript では `hookName: "tool.call", hookEvent: "PostToolUse"`。plugin 自身の `$.tool.call` には付かない | 実測: `e.agentId` で subagent の呼び出しを見分ける。実測: `$.tool.register` した tool には `{ result }` で答える (`{ text }` は wrong shape で skip)。managed settings の hook の deny が先。`consent` は人の press から起きた call の人の言葉 (tool には渡らない)。built-in `agents-md` は `Read` の after で `{ ...result, context: [...(result.context ?? []), frame] }` と足し、`result.deny` / `result.isError` の時は触らない |
| `tool.check` | `tool`, `input`, `tool_use_id?` (問い合わせでは無し), `agentId?`, `ceiling?`。全欄 pinned (問いの同一性) | `{ decision, reason?, rule?, hook?, ceiling? }` | after / instead: `{ decision: allow / ask / deny, reason? }` でどちら向きにも覆せる。modifying は無い (呼び出しを変えるのは `tool.call`)。hook が答えに付けた `ceiling` は捨てられる | deny の `reason` が model の読むエラー文、ask の `reason` はダイアログに出る | 人に答えさせる tool (AskUserQuestion、plan の承認) と plan mode の非 read 呼び出しは締める方向だけ。`$.tool.check` は同じ chain を実行なしで走らせる (classic hook は走らず `hook` は無い)。settings の PreToolUse hook が allow した call では起きない。`sec-default` が座る機械では user tier の緩和は deny rule 等に戻される (dialogs) |
| `tool.describe` | `tool`, `description`, `isDeferred?`, `provider` (pinned) | `{ description, isDeferred? }` | after / instead: `description`, `isDeferred` | `description` の置き換え (tool の説明そのもの) | session 内で cache (`$.ui.invalidate("tool.describe")` まで)。変えると次 turn で prompt cache 全体が書き直る |
| `prompt.submit` | `text`, `origin`, `wait`, `context?`, `command?` (pinned), `isMeta?` (pinned), `attachments?` (`{ type, mediaType?, filename?, id? }`、bytes は無い), `turnId?` | `{ text, context?, origin? }` / `{ drop }` | modifying: `text` (画面の user message も追従。`command` 付きでは適用されず人に告げられる。`isMeta` の行は実行中の turn に配送されるものだけ書き換えが効く)、`context`。instead: `{ drop }` (skill・prompt command は展開前に止まる)。`next` の後の `{ drop }` は hook の失敗 | `e.context` (modifying で `next({ ...e, context: [...(e.context ?? []), mine] })`。10 万字・合計 20 万字を超えると先頭と path)。after に足したものは付かず log される | `origin` は hook が設定できない。`next` は turn 開始時点で resolve (events)。managed settings が install した mod は hook の中で `$.prompt.media({ id })` で添付の bytes を読める (dollar-api)。built-in `diff` は armed な file の hunk を `context` に足して送り、`result.drop === undefined` を見てから disarm する |
| `prompt.attachment` | `type`, `text`, `origin` (pinned), `agentId?` (pinned), `detail?` (pinned) | `{ text }` | modifying / after / instead: `{ text }`、`{ text: null }` で外す | 既存の attachment の文の置き換え・削除。結果は `{ text }` だけで、新しい attachment は足せない | engine が model 向けに差し込む文 (reminder・mode 遷移・mention したファイル ...) ごとに発火。`type` 例: `todo_reminder`, `auto_mode`, `nested_memory`, `skill_listing`, `file`, `queued_command`。`<system-reminder>` 枠は chain の外で付く。答えは attachment ごとに process 内で保持 (resume と `$.ui.invalidate` で再問い合わせ)。transcript は engine の記録のまま。`origin.kind` は `engine` / `hook` (settings hook の出力) / `plugin` (`tool.call` / `prompt.submit` / `prompt.mention` の `context`) |
| `prompt.mention` | `mention` (pinned), `path`, `offset?`, `limit?`, `agentId?` (pinned) | `{ type, context? }` / `{ deny }` | modifying: `path` / `offset` / `limit`。instead: `{ deny }` | 結果の `context` (after。`next` が返した entry は全部残す) | `@` で名指したファイルごと。この read に `tool.call` は起きない。失敗した hook は飛ばされファイルは読まれる |
| `prompt.section` | `name`, `text` (null 可) | `{ text }` | after / instead: `{ text }`、null で節を外す | system prompt の節の置き換え | `$.ui.invalidate("prompt.section")` まで cache、変更は次 turn |
| `prompt.compose` | `model` (pinned), `promptModel`, `surfaces`, `tools`, `outputStyle`, `traits` | `{ sections: [{ id, text, scope }] }` | after: 節の追加 (末尾は `session`)・置換・並べ替え・削除 | system prompt 全体 | `shared` の節が `session` の後に来る答えは hook ごと skip。plugin の節の id は `<plugin>:<name>`。節の id は `traits` (`lean` / `bare` ...) で変わるので `next(e)` から読む。`$.prompt.compose(facts?)` で誰にも送らずに組める |
| `prompt.context` | `blocks` (`claudeMd` / `userEmail` / `attachedProject` / `currentDate`), `instructionFiles?` (`{ path, kind, content, parent? }`、kind は `managed` / `user` / `project` / `local` / `memory`) | `{ blocks, instructionFiles? }` | modifying / after: block の追加・削除・並べ替え・書き換え。`instructionFiles` を変えると `claudeMd` の本文が engine の枠付けで描き直される | 最初の user message に載る context block | 会話ごと 1 回 (compaction と `/clear` で再計算)。engine が扱わない名前の block (plugin 独自のもの) は会話に 1 部だけ載り、立っている間は後の答えで変わらない。変わる文は `instructionFiles` か `prompt.submit` の `context` に置く。上の hook が `claudeMd` の本文を書き換えると `instructionFiles` は `undefined` になる。built-in `agents-md` は `AGENTS.md` を `kind: 'project'` の file として足し、engine がそれを CLAUDE.md と同じ位置・枠・告知・agent からの除外規則で描く |
| `prompt.fill` | `text`, `mode`, `origin` (pinned), `decorations?` | `{ isFilled, refusal? }` | modifying: `text` / `mode`。instead: `{ isFilled: false }` | — | composer への書き込み。詳細は `claude-mods/prompt-injection` |
| `prompt.suggest` | `text`, `origin` (pinned) | `{ isShown }` | modifying: `text`。instead: `{ isShown: false }` | — | composer の薄字の提案 |
| `prompt.edit` | `origin` (pinned), `key?` (pinned), `text`, `cursor`, `start`, `end`, `inputText` | `{ text, cursor, decorations? }` | modifying: `text` / `inputText`。after: 表示する box。instead: `{ text: e.text, cursor: e.cursor }` で打鍵を消費 | — | 人の打鍵・貼り付け |
| `prompt.autocomplete` | `text`, `cursor`, `token` (cursor で終わる非空白の連なり), `start`。全欄 pinned | `{ suggestions: [{ text, label?, description? }] }` (core は空) | after: 行の追加 (`[...(await next(e)).suggestions, mine]`) | — | engine 自身の候補の下に強調なしで並び、選ぶと `text` が token を置き換える。matcher `{ token: /^#/ }` で先頭文字ごとに答える |
| `skill.prompt` | `skill`, `text`, `frontmatter`, `frontmatterProblem?`, `source` (`userSettings` / `projectSettings` / `policySettings` / `plugin` / `built-in` / `mcp` / `syncedSkills` ...), `pluginName?`, `path?` (SKILL.md かコマンドの `.md` の絶対パス)。`text` と `frontmatter` 以外は pinned | `{ text }` | modifying: `text` / `frontmatter` (下の hook に渡す)。after / instead: `{ text }` | 実測: 返した `text` が model の読む prompt そのものになる | 実測: matcher `{ skill: "<plugin>:<name>" }` で絞れる。`/name`・Skill tool・preload で発火。`frontmatter` は作者の書いたままで、実効の権限ではない (それは `tool.check` で読む)。engine は `frontmatterProblem` があっても何も拒まないので、frontmatter で判断する hook が拒む。`sec-default` が座る機械では user tier の hook は飛ばされる |
| `command.run` | `command` (書き換え拒否), `args`, `origin`, `presentation` (pinned) | `{ text?, context?, exitCode?, ref? }` | modifying: `args`。instead: `{ text }`。after: 表示された出力の差し替え (開いた panel や model 向け prompt は差し替えない) | 結果の `context` (人には見えない user message)。実測: plugin の `.md` (prompt 型) command では `next(e)` の後に足した `context` は捨てられる (debug `a hook's own answer after next() dropped`)。他の種類の command での after は未確認 | `exitCode` は `-p` で command だけを渡した run の終了コード。失敗した hook は飛ばされ command は走る。`presentation` は `{ isFullscreen, columns }` で、描く command が幅に合わせられる。built-in `diff` は `{ command: ['clear', 'resume'] }` を hook し `await next(e)` の後に自分の状態を捨てる (`/clear` では `session.start` が起きないため) |
| `command.describe` | `command` (pinned), `description`, `argumentHint?`, `isHidden`, `immediate` (読み取り専用), `provider` (pinned) | `{ description, argumentHint, isHidden }` | modifying / after: 3 欄 | — | typeahead と `/help` 用。`$.ui.invalidate("command.describe")` まで cache |
| `config.set` | `key` (pinned), `value`, `previous` (pinned), `provider` (pinned), `origin` (pinned) | `{ value }` / `{ deny }` | modifying: `value`。instead: `{ deny }` | — | trusted source が持つ行は core が拒む |
| `config.describe` | `key` (pinned), `label`, `description?`, `isHidden`, `provider` (pinned) | `{ label, description, isHidden }` | modifying / after: 3 欄 | — | |
| `attribution.text` | `kind` (`commit` / `pr` / `exemption` / `remedy`), `text` | `{ text }` | after / instead: `{ text }` | model が書く commit・PR 文向けの指示文の置き換え | |
| `telemetry.log` | first-party の行 (`event`, `props`) か collector への record。`to` (`anthropic` / `collector`) は pinned | `{ value: undefined }` / `{ deny }` | modifying: record の中身。instead: `{ deny }` (呼び手の Promise が reject) | — | 送り先は変えられない (matcher `{ to: 'collector' }` で流れを選ぶ)。installed plugin では `*` に選ばれず、名指しか `telemetry.*` で hook する。built-in `telemetry` は `telemetry.*` の gate で built-in 以外の呼び手を拒む |
| `telemetry.mark` | `feature`, `kind` (`ok` / `sad` / `bad`), `reason?`, `props?` | `{ value: undefined }` / `{ deny }` | instead: `{ deny }` | — | 常に `anthropic` 行き。engine 自身は何もせず、hook した built-in が行を queue する |
| `agent.offer` | `agent`, `description`, `source`, `provider` (pinned) | `{ isOffered: true }` | instead: `{ isOffered: false }` で一覧から外し dispatch も拒否 | 一覧から消せるだけ (説明の書き換えは結果に無い) | 失敗した hook は素通し |
| `agent.spawn` | `tool_use_id` (pinned), `prompt`, `description`, `subagentType`, `model?`, `parentModel` (pinned), `parentAgentId?` (pinned), `permissionMode?` (pinned), `background`, `fork` (pinned), `isTeammate?`, `workflow?`, `resume?`, `name?` (pinned), `cwd?` | `{ model, agentId?, teammateId? }` / `{ deny }` | modifying: `prompt` / `description` / `subagentType` / `model` / `background` / `cwd`。instead: `{ model }` / `{ deny }` | `prompt` の書き換え (subagent が受け取る task)。`deny` の文は Agent tool のエラー | workflow の `agent()` と resume は deny だけ効く。`next` 後の deny は hook の失敗 |
| `session.start` | `cwd`, `surface`, `isInteractive` | `{ cwd }` | 観測のみ | — | process ごと・読み込みごとに 1 回で、`/clear` では起きない (events)。最初の 1 回は await されるので、ここでの `$.tool.register` / `$.command.register` は turn 1 に間に合う。built-in は `next(e)` を待たせない (`agents-md` は telemetry を await せず投げて `return next(e)`) |
| `session.receive` | `origin` (pinned), `text`, `event?` (pinned), `agentId?` (pinned) | `{ text }` / `{ consumed }` | modifying: `text`。instead: `{ consumed }` (queue にも transcript にも入らない) | 配送本文の置き換え・握りつぶし | 別 session・Remote Control・relay からの配送 |
| `session.append` | `message` (`type` / `name?` / `role?` / `isMeta?` は pinned、`content`), `door` (pinned), `origin` (pinned), `uuid` (pinned), `agentId?` (pinned) | `{ message, uuid }` / `{ deny }` | modifying: `content` (text block、tool_result の `content` / `is_error`。media block は落とす・動かすだけ。tool_use・thinking・未知の block・`tool_use_id` は戻される)。`next` 無しの答えや別の行を返す hook は skip | 保存される行の書き換え (以後の request はその形で送られる) | 会話が保持する行ごと (prompt・応答 block・tool result・notice) に保存前に発火。`door`: `prompt` / `command` / `response` / `tool-result` / `tool-message` / `delivery` / `attachment` / `hook-context` / `note` (plugin の `$.session.append`) / `compaction` / `notice` / `queue`。`queue` は会話の行ではなく transcript の `queue-operation` 記録の本文で、書き換えると queue 記録を送った prompt と違う形にできる。画面・SDK stream には書き換え前の形が一瞬出ることがある。`{ deny }` は door `note` (plugin 自身の append) だけ。matcher `{ door: 'tool-result' }` で絞る |
| `session.send` | `to`, `text`, `origin` (pinned), `agentId?` (pinned) | `{ isDelivered: true }` / `{ isDelivered: false, reason }` | modifying: `text` / `to` (宛先は判定し直し)。instead: `{ isDelivered: false, reason }` | 受け手が読む本文。拒否の `reason` は送り手の model が tool 結果として読む | plugin 自身の `$.session.send` は自分の hook を通らない (events) |
| `session.compact` | `trigger` (pinned), `agentId?` (pinned), `instructions?`, `messages` | `{ messages, tokensBefore?, tokensAfter?, usage? }` / `{ skip }` | modifying: `instructions` / `messages`。after: `messages`。instead: `{ messages }` / `{ skip }` | compaction 後の会話そのもの | `trigger`: `manual` / `auto` / `plugin` / `precompute` |
| `session.attach` | `surface`, `clientId`, `viewport?` | `{ clientId }` | 観測のみ | — | remote client が roster に入った時 |
| `session.detach` | `surface`, `clientId`, `reason` | `{ clientId }` | 観測のみ | — | `reason: end` は `session.end` の短い予算の中で走る |
| `session.measure` | `context`, `rateLimits`, `cost?`, `changed` | `{ changed }` | 観測のみ | 実測: — | main の turn ごとと rate limit の窓が 1 point 動いた時 |
| `session.end` | `reason`, `sessionId`, `resume` | `{ sessionId }` | 観測のみ | — | chain 全体で短い wall-clock 予算を共有 (`next.budget`) |
| `plugin.register` | `name`, `tier`, `root`, `version?`, `provenance`, `uses` (`events` / `calls` / `env?` / `state?`、validate と同じ走査結果)。全欄 pinned | `{ allow: true }` | instead: `{ refuse }` | — | 判定は `tier` と `uses` で (`name` / `root` / `version` / `provenance` は自己申告で、改名で迂回される)。judge は先に admit された plugin と binary のもの。built-in `sec-default` は `{ tier: 'user' }` の matcher と `.catch` で fail closed にしている。`provenance` は `<name>@<marketplace>` / `<name>@inline` / `<name>@builtin`。実測: `--plugin-dir` の mod は plugin id が `<name>-inline` で、`$.plugin.root` は指定したディレクトリそのまま。marketplace から install した mod は root が `<plugins>/cache/<marketplace>/<plugin>/<version>`、data dir が `<plugins>/data/<plugin>-<marketplace>` |
| `turn.start` | `text`, `turnId`, `agentId?` (pinned) | `{ turnId }` | 観測のみ | 実測: — | main だけを見るなら `e.agentId !== undefined` を素通し。spawn の入れ子にいた hook は agent の start を聞かない |
| `turn.step` | `turnId` (pinned), `index` (pinned), `model`, `effort?`, `messageCount` (pinned), `agentId?` (pinned) | stream。最後に `{ turnId, index, answer, toolUses, serverToolUses?, stopReason, usage }` | modifying: `model` / `effort`。chunk の書き換え。instead: `next` 無しの答え (request を送らない) | — (送る messages は engine のもので pinned) | `serverToolUses` は API 側が走らせた tool で、拒否・書き換えはできない |
| `turn.complete` | `answer`, `durationMs`, `isAborted`, `turnId`, `agentId?` (pinned), `usage?`, `reason` (`answer` / `aborted` / `refusal` / `error`), `refusal?` | `{ text, usage? }` | after: 違う `text` を返すと answer の下に表示 (transcript は不変) | 実測: — | agent の end は spawner 含む全 hook が聞く |
| `engine.create` | `plugins` | ここまで組まれた `$` | after: noun の追加。`user` tier 以外は noun を withhold できる | — | 他 plugin の noun を置き換えると読み込み失敗。この時点の `$` は空 (events)。built-in `telemetry` は `const beneath = await next(e)` の上に自分の noun を組み、`{ ...{ telemetry }, ...beneath }` で engine に既にある noun を上書きしない形で足す |
| `ui.render` | `surface`, `component`, `requestId`, `viewport?`, `props` | 描画 tree | modifying: `props`。after: 包む。instead: 自前の tree | — | 頻度が高いので matcher で絞る (events)。不正な tree や描画中の throw は engine 自身の描画に戻る。`Pane` は plugin が `$.ui.open` で開く唯一の component で、permission ダイアログは描けない |
| `ui.resolve` | `surface`, `component` | surface の element 表 | after: element の差し替え・削除 | — | 描画ごとでなく読み込み時 |
| `ui.press` | `plugin`, `element`, `component`, `requestId`, `surface`, `link?` | `{ element }` | instead: `{ element }` で押下を取る。modifying: `link.href` | — | 対象は plugin が描いた要素だけ |
| `ui.input` | `plugin`, `element`, `component`, `requestId`, `surface`, `kind`, `value` | `{ element, value }` | modifying: `value`。instead で取る | — | |
| `ui.select` | `plugin`, `element`, `component`, `requestId`, `surface`, `value` | `{ element, value }` | modifying: `value`。instead で取る | — | |
| `ui.message` | `surface`, `component`, `requestId`, `element`, `module`, `data` | `{}` / `{ props }` | modifying: `data`。after: `{ props }` で再描画なしに props を渡す | — | 自 plugin の `Client` の post だけ |
| `ui.fault` | `surface`, `component`, `requestId`, `element`, `module`, `phase`, `reason` | `{}` | 観測のみ | — | 自 plugin の `Client` の失敗だけ。`reason` は信用しない文字列 |
| `ui.scroll` | `component`, `requestId`, `offset`, `by`, `bodyRows`, `contentRows`, `origin`, `pointer?` | `{}` / `{ deny }` | modifying: `offset`。instead: `{}` / `{ deny }` で動かさない | — | |
| `ui.focus` | `component`, `requestId`, `plugin?`, `element?`, `origin` | `{}` / `{ deny }` | modifying: `element`。instead: 動かさない | — | |

## `$` の操作 (op event)

`e` はその `$` 呼び出しの引数、結果は `{ value }` か `{ deny }`。どれも modifying (引数の書き換え)・instead (`{ value }` で代わりに答える / `{ deny }`)・after (`value` の差し替え) が効き、呼んだ hook 自身は飛ばされる (`next.origin` が呼び手)。model に届くのは、model が読む定義を登録する op の引数を書き換えた場合だけ。代表的なものを挙げる。

| event | `e` | `value` | 書き換え | model に届く | 備考 |
|---|---|---|---|---|---|
| `fs.read` / `fs.write` | `{ path, as }` / `{ path, text }` | 本文 / なし | path・本文の書き換え、拒否 | — | 4 MiB 上限 (dollar-api) |
| `http.fetch` | `{ url, init? }` | `{ status, ok, headers, text }` | 宛先・init の書き換え、拒否 | — | |
| `process.run` | `{ argv, init? }` | `{ exitCode, stdout, stderr, isStdoutTruncated, isStderrTruncated }` | argv の書き換え、拒否 | — | |
| `process.spawn` | 起動 request | stream | request の書き換え。`{ deny }` は呼び手の stream を reject し、走っている子は kill | — | streaming op |
| `env.get` / `env.set` | `{ name }` / `{ name, value? }` | 値 / なし | `name` は pinned。`env.set` で `next(e)` の後に deny すると hook の失敗 | — | |
| `store.get` / `store.set` / `store.delete` / `store.keys` | `{ key }` / `{ key, value }` / `{ key }` / `{}` | 値 / なし / なし / key 一覧 | key・値の書き換え、拒否 | — | 実測: 保存先は `<plugins dir>/store/<plugin id>-<hash>.json` で、resume と別 session を跨いで残る |
| `state.get` / `state.set` | 参照 (`plugin`, `key`, `id?`) / 参照 + `value`, `previous`, `ifVersion?` | `StateRead` / `StateSetResult` | 参照は pinned。`state.set` は `value` だけ書き換え可、`next(e)` の後の deny は hook の失敗 | — | 書くのは値の持ち主だけ。実測: `/clear` と resume で消える |
| `ui.log` | `{ text, to }` | なし | `next({ ...e, to: 'debug' })` で画面から外す | — | `to` は常に入っている |
| `ui.notify` | `{ text, title? }` | `{ isSent: true, channel }` / `{ isSent: false, reason }` | 書き換え、拒否、代答 | — | 通知は `classic.Notification` でも聞こえる。timer から通知し直す mod 同士は無限に反響し、engine は止めない |
| `ui.open` / `ui.close` | `{ id, title, focus, ... }` / `{ id, origin }` | 結果 / なし | open は改題・拒否 (改名は不可)。close は `next` 無しで答えると閉じない (`origin` が `unload` の時を除く) | — | close は人 (`person`)・unload でも起きる。built-in `diff` は `{ id }` の matcher で自分の pane の close を取り、詳細表示中なら `{ deny }` を返して一覧に戻す |
| `ui.selection` / `ui.copy` | `{}` / `{ text, surface }` | 選択 / `{ isCopied, reason? }` | 代答、拒否、copy は書き換え | — | |
| `mcp.call` / `mcp.connect` | `{ server, tool, args }` / `{ server }` | MCP の結果 / `{ isConnected, ... }` | 書き換え、拒否、代答 | — | `mcp.call` は permission prompt を通らないので、上の hook が許可の代わり |
| `session.identity` / `prompt.read` | `{}` | 下記 / `{ text, cursor }` | 代答、拒否 | — | `session.identity` は managed で install された mod にだけ答える (dollar-api) |
| `tool.register` | `{ name, description, inputSchema, isDeferred? }` | `{ tool }` | spec の書き換え、拒否 | 登録される tool 定義の書き換え | 答え方は `tool.call` の行 |
| `agent.register` | agent 定義 (`name`, `description`, `prompt`, `tools?`, `model?` ...) | `{ agent }` | 定義の書き換え (型は呼び手のまま)、拒否 | `description` (model が読む agent 一覧の行) と `prompt` (その agent の system prompt) の書き換え | |
| `command.register` | `{ name, description, argumentHint?, immediate? }` | `{ command }` | spec の書き換え、拒否 | — | |
| `session.messages` | `{ agentId?, as? }` | 会話 | 引数の書き換え、代答 | — | 他 plugin が読む会話を差し替えられる |
| `model.complete` / `model.fork` / `model.classify` | `{ model, prompt, system?, ... }` / request / `{ text, labels, options? }` | 応答 | request の書き換え (`prompt` を変えれば送る文が変わる)、代答、拒否 | — | plugin が呼ぶ completion の request で、session の会話の model 入力ではない |
| `clock.sleep` / `clock.after` / `clock.every` | 待ち時間 | なし | 待ち時間の書き換え、拒否 | — | timer の callback から呼んだ `$` は同じ plugin の `*` hook に現れない (events) |

## command hook の event (`classic.*`)

`e` は command hook が stdin で受け取る JSON (共通欄 `session_id`, `transcript_path`, `cwd`, `prompt_id?`, `permission_mode?`, `agent_id?`, `agent_type?`, `effort?`)。`agent_id` は subagent の中で起きた時だけ入り、main と subagent を見分ける欄になる (`agent_type` は `--agent` の main でも入る)。結果はどの event も `block` (command hook の `decision: "block"`)・`preventContinuation`・`stopReason` を持ち、下の表の欄を足せる。下の settings hook の答えは fold される (後勝ち、`additionalContext` は連結)。`sec-default` が座る機械では user tier の `classic.*` hook は飛ばされる (overview)。chain の順は events。

| event | 固有の `e` | 結果に足せる欄 | model に届く | 備考 |
|---|---|---|---|---|
| `classic.PreToolUse` | `e` は stdin 形ではなく `tool`, `tool_use_id`, 引数 (平たく) | `allow` / `ask` / `deny`, `updatedInput`, `additionalContext` | `additionalContext` | `tool.call` の core の中で起きる (dialogs) |
| `classic.PostToolUse` | `tool_name`, `tool_input`, `tool_response`, `tool_use_id`, `duration_ms?`, `mcp_server?` | `additionalContext`, `updatedToolOutput`, `updatedMCPToolOutput` | `additionalContext` (実測: command hook と同じ reminder)。`updatedToolOutput` は model が見る tool 結果の置き換え | |
| `classic.PostToolUseFailure` | `tool_name`, `tool_input`, `tool_use_id`, `error`, `is_interrupt?`, `duration_ms?` | `additionalContext` | `additionalContext` | |
| `classic.PostToolBatch` | `tool_calls` | `additionalContext` | `additionalContext` | |
| `classic.PermissionRequest` | `tool_name`, `tool_input`, `permission_suggestions?`, `mcp_server?` | `decision` | — | `tool_use_id` は無い (dialogs) |
| `classic.PermissionDenied` | `tool_name`, `tool_input`, `tool_use_id`, `reason` | `retry` | — | auto mode の classifier が拒んだ時 |
| `classic.UserPromptSubmit` | `prompt`, `source?`, `session_title?` | `additionalContext`, `sessionTitle`, `suppressOriginalPrompt` | `additionalContext` | |
| `classic.UserPromptExpansion` | `expansion_type`, `command_name`, `command_args`, `command_source?`, `prompt` | `additionalContext`, `suppressOriginalPrompt` | `additionalContext` | slash command・MCP prompt の展開 |
| `classic.SessionStart` | `source` (`startup` / `resume` / `clear` / `compact` / `fork`), `agent_type?`, `model?`, `session_title?`, resume 時の cache 見積り欄 | `additionalContext`, `initialUserMessage`, `sessionTitle`, `watchPaths`, `reloadSkills` | `additionalContext` | engine の `session.start` とは別物 |
| `classic.SessionEnd` | `reason` | — | — | |
| `classic.Stop` | `stop_hook_active`, `last_assistant_message?`, `background_tasks?`, `session_crons?` | `additionalContext` | `additionalContext` (実測: command hook と同じ reminder) | 実測: 足すと model 呼び出しが 1 回増え、2 回目は `stop_hook_active: true` |
| `classic.StopFailure` | `error`, `error_details?`, `last_assistant_message?` | — | — | |
| `classic.SubagentStart` | `agent_id`, `agent_type` | `additionalContext` | `additionalContext` | |
| `classic.SubagentStop` | `stop_hook_active`, `agent_id`, `agent_transcript_path`, `agent_type`, `last_assistant_message?`, `background_tasks?`, `session_crons?` | `additionalContext` | `additionalContext` | |
| `classic.PreCompact` | `trigger`, `custom_instructions` | — | — | |
| `classic.PostCompact` | `trigger`, `compact_summary` | — | — | |
| `classic.PreModelSwitch` | `from_model`, `to_model`, `requested_model`, `source`, `context_tokens`, `prompt_cache_warm`, `cache_ttl`, `estimated_cache_write_usd`, `pricing` | `permissionDecision`, `permissionDecisionReason` | — | |
| `classic.PostModelSwitch` | PreModelSwitch と同じ欄 (`source` に `auto` / `resume` が増える) | `additionalContext` | `additionalContext` | |
| `classic.Setup` | `trigger` | `additionalContext` | `additionalContext` | |
| `classic.Notification` | `message`, `title?`, `notification_type` | — | — | 対話 session は応答完了の 60 秒後に `idle_prompt` (events) |
| `classic.MessageDisplay` | `turn_id`, `message_id`, `index`, `final`, `delta` | `displayContent` | — (表示の置き換え) | |
| `classic.Elicitation` / `classic.ElicitationResult` | dialogs | — | — | 返せるのは共通の 3 欄だけ (dialogs) |
| `classic.TeammateIdle` | `teammate_name`, `team_name` | — | — | |
| `classic.TaskCreated` / `classic.TaskCompleted` | `task_id`, `task_subject`, `task_description?`, `teammate_name?` | — | — | |
| `classic.ConfigChange` | `source`, `file_path?` | — | — | |
| `classic.InstructionsLoaded` | `file_path`, `memory_type`, `load_reason`, `globs?`, `trigger_file_path?`, `parent_file_path?` | — | — | |
| `classic.WorktreeCreate` | `name` | `worktreePath` | — | |
| `classic.WorktreeRemove` | `worktree_path` | — | — | |
| `classic.CwdChanged` | `old_cwd`, `new_cwd` | — | — | |
| `classic.FileChanged` | `file_path`, `event` | — | — | |
| `classic.DirectoryAdded` | `directory`, `source` | — | — | |

## model に文脈を渡したい時の event の選び方

| 渡したい場面 | event と欄 | 配置 |
|---|---|---|
| tool の結果に添える (subagent の tool も `e.agentId` で区別して) | `tool.call` の結果 `context` | after |
| 人の prompt に添える | `prompt.submit` の `e.context` | modifying (after は付かない) |
| `@` で名指したファイルに添える | `prompt.mention` の結果 `context` | after |
| skill の展開文を変える | `skill.prompt` の `{ text }` | after / instead |
| engine が差し込む reminder 等を書き換える・消す | `prompt.attachment` の `{ text }` / `{ text: null }` | after / instead |
| system prompt・会話冒頭の context block を変える | `prompt.section` / `prompt.compose` / `prompt.context` | after |
| command hook と同じ口で添える | `classic.*` の結果 `additionalContext` | after |
| turn の終わりに model をもう 1 回動かす | `classic.Stop` の `additionalContext` | after。2 回目は `stop_hook_active: true` なので、それを見て止める |
| event を待たずに会話へ 1 行足す | `$.session.append({ message: { type: 'user', content: [{ type: 'text', text }] }, agentId? })` | 任意の時点 (人には打鍵として見えず、model が読む) |
| 別の turn として渡す | `$.prompt.submit({ text })` (`asUser: true` で plugin の枠なし) | session が idle になってから |

`session.measure` / `turn.start` / `turn.complete` は観測用で、ここからは渡せない (実測)。拾った値を次の機会に渡すなら、`$.state` に置いて上の event で読む。

`sec-default` が座る機械 (組織が管理する機械) では、user tier の mod の hook のうち `skill.prompt`・`prompt.attachment`・`prompt.section` / `prompt.compose` / `prompt.context`・`classic.*` は飛ばされる。そこでも効くのは `tool.call` / `prompt.submit` / `prompt.mention` の `context` と、`$.session.append` (door `note`) / `$.prompt.submit`。

## 2026-10-14 時点の未確認

- `command.run` の after に足した `context` が、plugin の `.md` 以外 (`$.command.register` した command、built-in) で届くか
- `classic.*` の `block` の文が mod 経由の時に event ごとにどう model・人に届くか
- `classic.PreToolUse` / `classic.UserPromptSubmit` / `classic.SubagentStart` 等、実測していない event の `additionalContext` の届き方 (型定義は「event と共に model に渡す」とだけ書く)
- `classic.SessionStart` (`source: clear`) が `/clear` で mod に届くか (engine の `session.start` は起きない)
