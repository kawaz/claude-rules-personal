# TypeScript の参照知識

型の付け方の水準 (スキーマから型を導く、境界で parse する、`as` / `any` / `!` を使わない) そのものは `for-all/rules/typescript-typing.md` が正本。ここはその書き方と検査の設定。

- [schema-first-typing](schema-first-typing.md) — スキーマライブラリの選び方、型の導き方、`unknown` を閉じ込める境界、主張の置き換え表。
  valibot, zod, スキーマ定義, InferOutput, safeParse, JSON.parse as, unknown を受ける関数, isRecord, 型ガード, 外部 JSON の型付け
- [typing-lint](typing-lint.md) — `as` / `any` / `!` を禁じる lint 設定、TS 7 の回避、既存コードへの段階導入。
  oxlint, typescript-eslint, consistent-type-assertions, no-explicit-any, no-non-null-assertion, no-unsafe, does not support TS 7.0, lint で as を禁止
