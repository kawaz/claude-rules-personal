# 型の主張・any・非 null の主張を lint で禁じる設定

`typescript-typing` rule の水準を機械検査する設定。oxlint 1.87 / typescript-eslint (ESLint 10, TypeScript 6) で動作を確認した。

## 検査する規則

| 禁じるもの | oxlint | typescript-eslint |
|---|---|---|
| `as Foo` / `<Foo>x` (`as const` は通る) | `typescript/consistent-type-assertions` + `assertionStyle: "never"` | `@typescript-eslint/consistent-type-assertions` + `assertionStyle: "never"` |
| `any` | `typescript/no-explicit-any` | `@typescript-eslint/no-explicit-any` |
| 非 null の主張 `x!` | `typescript/no-non-null-assertion` | `@typescript-eslint/no-non-null-assertion` |
| `any` 由来の値の代入・呼び出し・return | (型情報が要る) | `strictTypeChecked` に含まれる `no-unsafe-*` |

`assertionStyle: "never"` は `as const` を違反にしない (両 linter で確認済み)。

## oxlint

`.oxlintrc.json`:

```json
{
  "plugins": ["typescript"],
  "rules": {
    "typescript/consistent-type-assertions": ["error", { "assertionStyle": "never" }],
    "typescript/no-explicit-any": "error",
    "typescript/no-non-null-assertion": "error"
  }
}
```

## typescript-eslint

`eslint.config.mjs`:

```js
import tseslint from "typescript-eslint";

export default tseslint.config(
  tseslint.configs.strictTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname } },
    rules: {
      "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-non-null-assertion": "error",
    },
  },
);
```

- typescript-eslint は TypeScript 7 に未対応で、`typescript-eslint does not support TS 7.0.` で起動しない。lint 用に TypeScript 6 を devDependency に置く
- 型情報を使う `no-unsafe-*` は `projectService` と `tsconfig.json` が要る。型情報なしで回せる 3 規則だけなら oxlint で足りる

## 既存コードへの入れ方

違反が多いコードベースでは、規則を先に `warn` で有効にして違反数を見えるようにし、置き換えの段ごとに減らして、最後に `error` にする。新しく書くコードは最初から違反ゼロで書く。
