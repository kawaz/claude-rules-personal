# TypeScript の参照知識

型の付け方の水準 (スキーマから型を導く、境界で parse する、`as` / `any` / `!` を使わない) そのものは `for-all/rules/typescript-typing.md` が正本。ここはその書き方と検査の設定。

- [schema-first-typing](schema-first-typing.md) — スキーマライブラリの選び方、スキーマから型を導く形、`unknown` を閉じ込める境界の関数、主張を使わずに型を合わせる置き換え表。
  発火語: valibot, zod, スキーマ定義, InferOutput, safeParse, JSON.parse as, unknown を受ける関数, isRecord, 型ガード, 外部 JSON の型付け
- [typing-lint](typing-lint.md) — `as` / `any` / 非 null の主張を禁じる oxlint と typescript-eslint の設定、TS 7 非対応の回避、既存コードへの段階導入。
  発火語: oxlint, typescript-eslint, consistent-type-assertions, no-explicit-any, no-non-null-assertion, no-unsafe, does not support TS 7.0, lint で as を禁止
