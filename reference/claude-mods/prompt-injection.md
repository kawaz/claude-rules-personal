# 外部から「人の入力」として prompt を入れる

外部プロセスが決めた文を、engine から見て人が打った prompt (`origin.kind: 'composer'`) として session に入れる手順。人が書きかけていた文は退避して、送信直後に composer へ戻す。Claude Code 2.1.284 の対話 session で一巡を実測済み。

## なぜ `$.prompt.submit` ではないか

`$.prompt.submit({ text })` は `origin` が `{ kind: 'plugin', name }` になり、model にも hook にも plugin 由来として見える。`origin.kind` は閉じた集合で、plugin が `composer` を名乗る口は無い。`composer` を得るには composer に文を置き、Enter を端末のキー入力として送る。

## 部品

- `$.prompt.read()` → `{ text, cursor }`。書きかけが無ければ `{ text: '', cursor: 0 }`。never reject
- `$.prompt.fill({ text, mode })` → `{ isFilled, text, cursor, refusal? }`。`mode` は `replace` (既定) / `append` / `insert` (cursor 位置)。ダイアログ中は `refusal: 'dialog'`、`-p` / SDK は `refusal: 'no_composer'`。他 plugin の `prompt.fill` hook が拒むこともある
- `prompt.submit` hook の `await next(e)` は prompt が session に入り turn が始まった時点 (実測 2〜8ms) で resolve する。model の応答は待たない
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
