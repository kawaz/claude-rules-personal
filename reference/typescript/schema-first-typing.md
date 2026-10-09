# スキーマから型を導き、境界で parse する書き方

`typescript-typing` rule の水準を満たすコードの形。例は valibot (1.x) で書くが、zod 等でも構造は同じ。

## ライブラリの選び方

プロジェクトで 1 つに決める。条件は次の 3 つ:

- スキーマから型を導ける (`v.InferOutput<typeof S>` / `z.infer<typeof S>`)。型を手で書き直さない
- 失敗を throw でなく値で返せる (`v.safeParse` / `z.safeParse`)
- Standard Schema に対応している (他のライブラリやフレームワークとスキーマを受け渡せる)

候補の差: valibot は部品を関数として import する作りで、使った部品だけが bundle に入る (ブラウザ向けに効く)。zod は広く使われ機能が多いが、同じ用途で bundle が大きくなりやすい。

## スキーマと型

```ts
import * as v from "valibot";

const RequestSchema = v.object({
  id: v.string(),
  op: v.picklist(["send", "list"]),
  body: v.optional(v.string()),
});
type Request = v.InferOutput<typeof RequestSchema>;
```

- `type Request = { ... }` を別に書かない。形を変える時はスキーマだけを直す
- プロセスやパッケージをまたいで共有する形は共有パッケージに置き、送る側と受ける側が同じスキーマを使う
- 外部仕様で形が変わっていくデータ (他製品のログ・出力) は、使う field だけを定義し、知らない field は通す (strict にしない)

## 境界の関数 (unknown はこの中だけ)

失敗の型をプロジェクトで 1 つにそろえ、境界の関数はスキーマを受けて型付きの結果を返す。

```ts
export type ParseError = { kind: "invalid-json" | "invalid-shape"; message: string };
export type Parsed<T> = { ok: true; value: T } | { ok: false; error: ParseError };

export function parseJsonWith<S extends v.GenericSchema>(schema: S, text: string): Parsed<v.InferOutput<S>> {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch (e) {
    return { ok: false, error: { kind: "invalid-json", message: e instanceof Error ? e.message : "JSON.parse failed" } };
  }
  const r = v.safeParse(schema, raw);
  return r.success
    ? { ok: true, value: r.output }
    : { ok: false, error: { kind: "invalid-shape", message: v.summarize(r.issues) } };
}

const req = parseJsonWith(RequestSchema, line);
if (!req.ok) return reject(req.error);
handle(req.value); // handle(req: Request) — 以降は型付きの値だけが流れる
```

- `Parsed<unknown>` のように `unknown` を返す関数を作らない (境界の外へ `unknown` が漏れる)。スキーマを引数に取って、通した結果だけを返す
- 失敗の扱い (拒否して理由を返す / その行だけ捨てて続ける / 表示を劣化させる) は境界ごとに決める。表す型は 1 つ
- `catch` の束縛は `e instanceof Error` で分けるだけにし、任意の値を `String(e)` で文字列にしない

## 主張を使わずに型を合わせる

| 書きたくなった形 | 代わりに |
|---|---|
| `JSON.parse(s) as Foo` | `parseJsonWith(FooSchema, s)` |
| `(x: unknown) => { if (isRecord(x) ...) }` | 呼び出し元の境界でスキーマに通し、関数は `(x: Foo)` を受ける |
| `map.get(k)!` | `const v = map.get(k); if (v === undefined) { ... }` で分岐する |
| `obj as Foo` で余分な field を黙らせる | `const x: Foo = obj` か `obj satisfies Foo` で検査させる |
| `el as HTMLInputElement` | `if (el instanceof HTMLInputElement)` で narrowing する |
| `x ?? String(x)` で穴を埋める | 穴を作った境界でスキーマに通す |

lint の設定は reference の `typescript/typing-lint` を読む。
