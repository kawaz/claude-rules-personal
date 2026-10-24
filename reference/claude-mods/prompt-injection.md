# 外部から「人の入力」として prompt を入れる

外部プロセスが決めた文を、engine から見て人が打った prompt (`origin.kind: 'composer'`) として session に入れる手順。人が書きかけていた文は退避して、送信直後に composer へ戻す。部品の仕様は Claude Code 2.1.299 の型定義、一巡は 2.1.284 の対話 session で実測。

## なぜ `$.prompt.submit` ではないか

`$.prompt.submit({ text })` は `origin` が `{ kind: 'plugin', name }` になり、model は "The <name> plugin sent a message: ..." の枠で読む。`$.prompt.submit({ text, asUser: true })` なら model は枠なしで人の言葉として読むが、hook と provenance の判定が見る origin は `{ kind: 'plugin', name, asUser: true }` のままで、transcript も plugin を名指す。plugin の prompt では `@file` の mention と貼り付け画像は展開されない (`asUser` でも)。

| 欲しいもの | 口 |
|---|---|
| model が人の言葉として読めばよい | `$.prompt.submit({ text, asUser: true })` (session が idle になってから自前の turn) |
| hook・transcript からも人の入力に見える (`origin.kind: 'composer'`)、`@file` も展開される | 下の手順 (composer に置いて端末から Enter) |

`origin.kind` は閉じた集合で、plugin が `composer` を名乗る口は無い。`composer` を得るには composer に文を置き、Enter を端末のキー入力として送る。

## 部品

- `$.prompt.read()` → `{ text, cursor }`。書きかけが無ければ `{ text: '', cursor: 0 }`。never reject
- `$.prompt.fill({ text, mode, decorations? })` → `{ isFilled, text, cursor, refusal? }`。`mode` は `replace` (既定) / `append` / `insert` (cursor 位置)。ダイアログ中は `refusal: 'dialog'`、`-p` / SDK や自前の composer を描く surface は `refusal: 'no_composer'`。他 plugin の `prompt.fill` hook が拒むこともあり、その時は `refusal` が無い (原因不明として扱い、box が無いとは見なさない)。返る `text` / `cursor` は module のどこかで `$.prompt.read` を呼んでいる plugin にだけ入り、それ以外には空の box が返る。端末で何も描かれない code point は除かれて入る。`decorations` (`{ start, end, color?, bold?, italic?, ... }`) で入れた文に色を塗れる (次の編集で消える)
- `prompt.submit` hook の `await next(e)` は prompt が session に入り turn が始まった時点 (実測 2〜8ms) で resolve する。model の応答は待たない。turn の実行中 (tool の実行中) の Enter でも、その時点で起きて数 ms で resolve し、prompt は実行中の turn の次の request に入る (実測: 2.1.299。応答の stream 中は未確認、詳細は reference の `claude-mods/events`)
- 文が session に入ったことの確認は、`prompt.submit` の `e.origin.kind === 'composer'` と、fill した文との一致で見る。実測: `classic.UserPromptSubmit` の `prompt` は fill した文から末尾の空白 (改行・空白・タブ・全角空白) を落とした形で届く (2.1.293)。`prompt.submit` の `e.text` で同じかは未確認
- Enter の送出は mod の外。端末にキーを送れる道具 (tmux の `send-keys`、kawaz 環境なら hyoui の `key:Enter` 等) を使う

## 手順

1. 外部が mod に「この文を入れろ」と伝える。実測ではファイル (`{"op":"fill","text":"..."}`) を書き、mod が `session.start` で始めた `$.clock.every(2000)` で読んだ。`$.process.spawn` で session 寿命の子を持ち、その出力で受ける形でもよい
2. mod が `$.prompt.read()` で composer を読み、`text` が空でなければ退避する
3. mod が `$.prompt.fill({ text, mode: 'replace' })`。`isFilled: false` なら (ダイアログ中等) 外部に失敗を返して待つか別経路に回す
4. 外部が端末に Enter を送る
5. mod の `prompt.submit` hook が `await next(e)` の直後に、退避した文を `$.prompt.fill` で戻す

```ts
let stash: string | undefined

async function inject($, text: string) {
  const box = await $.prompt.read()
  if (box.text !== '') stash = box.text
  return $.prompt.fill({ text, mode: 'replace' })
}

on('prompt.submit', async ($, e, next) => {
  const r = await next(e)
  if (stash !== undefined) {
    const text = stash
    stash = undefined
    await $.prompt.fill({ text, mode: 'replace' })
  }
  return r
})
```

## 実測結果

| 項目 | 書きかけ無し | 書きかけ有り |
|---|---|---|
| `read()` | `{ text: '', cursor: 0 }` | `{ text: 'half-typed draft 書きかけ', cursor: 21 }` |
| `fill()` | `isFilled: true` | `isFilled: true` |
| `prompt.submit` の `e.origin` | `{ kind: 'composer' }` | `{ kind: 'composer' }` |
| `prompt.submit` の `next.origin` | `{ plugin: 'engine', tier: 'core' }` | 同じ |
| 復元 | 対象なし | submit の 6ms 後に `isFilled: true`。応答完了後も composer に残る |

- 注入文は transcript でも hook でも人の入力と区別が付かない (`UserMessage` の `props.origin` も `composer`)
- slash command (`$.command.register` した `/name`) の中から fill しても同じく成立し、`command.run` の `origin` は `composer`
- AskUserQuestion 表示中の fill は `{ isFilled: false, refusal: 'dialog' }`
- `$.clock.every` の callback から呼んだ fill は、同じ plugin の `*` hook には現れない。`prompt.submit` hook の中から呼んだ復元の fill は `prompt.fill` event (`origin: { kind: 'plugin', name }`) として現れる

## 注意

- fill から Enter までの間に人が打鍵すると混ざる。人が TUI を触らない運用か、打鍵と衝突しない時機を選ぶ前提の手順
- 退避は module 変数なので、fill と Enter の間に reload が入ると失われる。気になるなら `$.state` に置く
- Enter を送る前に fill の結果 (`isFilled`) を外部が知る手段を用意する (mod がファイルに結果を書く等)。`refusal: 'dialog'` のまま Enter を送ると、Enter はダイアログに届いて選択中の項目を確定させる (ダイアログがキーを持っていることからの推測、未検証)
