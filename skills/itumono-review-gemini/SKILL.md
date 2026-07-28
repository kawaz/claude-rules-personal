---
name: itumono-review-gemini
description: Gemini CLIを使ったコードレビュー
---

引数: 追加指示（省略可）

## 実行

### 経路 A: 未コミット変更 / 単純な「レビューして」

```bash
NODE_OPTIONS="--no-warnings=DEP0040" gemini -y -p "レビュー指示 $ARGUMENTS"
```

### 経路 B: diff を直接 stdin に流して特定 scope をレビュー

`gemini -p ...` は stdin を accept するので、jj / git の diff をパイプで渡せば
scope を正確に絞れる:

```bash
jj diff -r 'BASE..HEAD' --git | NODE_OPTIONS="--no-warnings=DEP0040" gemini -y -p "以下の diff をレビュー。致命的な点だけ指摘して、最後に VERDICT: PASS or VERDICT: ISSUES_FOUND を出力。"

# git リポなら同等
git diff BASE..HEAD | NODE_OPTIONS="--no-warnings=DEP0040" gemini -y -p "..."
```

`codex review` が prompt とスコープフラグの併用不可なのに対し、gemini は
**stdin + prompt の併用が可能** なのでカスタム指示と特定 scope を両立できる。

## rate limit 対策

`gemini-2.5-pro` (= default) は free quota がタイトで、レビュー用途で
すぐに `RATE_LIMIT_EXCEEDED` を返すことがある。対策:

```bash
# pro で試みて rate limit したら flash に fallback
NODE_OPTIONS="--no-warnings=DEP0040" gemini -y -p "..." \
  || NODE_OPTIONS="--no-warnings=DEP0040" gemini -m gemini-2.5-flash -y -p "..."

# 最初から flash で投げる (= quota 別、応答もそこそこ良質)
NODE_OPTIONS="--no-warnings=DEP0040" gemini -m gemini-2.5-flash -y -p "..."
```

flash は pro より軽い・速い・別 quota。深い設計レビューには pro が望ましいが、
rate limit 中はとりあえず flash で代用する方が「結果が返らない」より良い。

## 出力の VERDICT

結果を報告する。出力に VERDICT が含まれない場合は `VERDICT: PASS` または `VERDICT: ISSUES_FOUND` を付与する。
