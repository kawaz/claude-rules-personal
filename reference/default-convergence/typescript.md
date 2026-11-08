# TypeScript のデフォルト収束パターン

各 bullet は「危険な使い方」だけが対象。括弧内の文脈では正当。

- `try/catch` で握りつぶし `console.error` だけ (原因も復帰も示さない)、Promise rejection の握りつぶし
- `any` / `as` / 非 null の主張 `!` / `unknown` の持ち回り / 外部データの検証なし利用: 対象外の文脈は無く、水準は `typescript-typing` rule が正本 (書き方は reference の `typescript`)
- 設計不備を隠す `?.` の乱用 (optional なドメイン値への `?.` は対象外)
- 副作用を何でも `useEffect` に詰める、`useMemo` / `useCallback` の儀式化
- boolean prop が増殖して状態の組合せが爆発 (= discriminated union にすべき場面)
