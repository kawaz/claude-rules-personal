---
name: itumono-review-codex
description: Codex CLIを使ったコードレビュー
---

引数: 追加指示（省略可）、または scope を絞る base SHA

## 実行

codex は些細なスタイル指摘を大量に出す傾向があるため、「瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。」を**必ず**含める (= プロンプト経路で実行する場合のみ。下記参照)。これを省略すると有用な指摘がノイズに埋もれる。

### 経路 A: 未コミット変更 + カスタムプロンプト

```bash
codex review -c 'model="gpt-5.3-codex"' "$ARGUMENTS 未コミットの変更をレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。"
```

### 経路 B: 特定 base からの diff を default review prompt でスキャン

`--base` / `--commit` / `--uncommitted` は **`[PROMPT]` と排他**。「特定 commit
範囲をスキャン」したい場合、prompt は諦めて default review prompt + 出力後に
VERDICT を付与する経路を取る:

```bash
codex review -c 'model="gpt-5.3-codex"' --base <BASE_SHA>
# or
codex review -c 'model="gpt-5.3-codex"' --commit <SHA>
```

scope が特定 commit に絞れる利点と、carefully crafted prompt を渡せないトレードオフ。
default review prompt は **致命的な点** を狙う作りになっているので、瑣末指摘の量は
許容範囲のことが多い。

### 経路 C: jj 管理リポで `--base` を使う

`codex review --base` は **git** リポ前提で動くため、jj 管理 (= `.git` が bare
で別 path にある形式) では「is not a git repository」で失敗する。jj リポでは

- `cd <repo_parent>` (bare git のあるパス) して `codex review --base ...` を呼ぶ
- または `jj diff -r 'BASE..HEAD' --git | gemini ...` のように gemini 経由で diff を流す

の 2 択。`codex exec` は base 指定ができないので jj × codex × base の組み合わせは
事実上不可能 (= 2025-05 codex 0.130 で確認)。

## モデル選定の注意 (codex CLI 0.130 で確認)

- モデルは **`gpt-5.3-codex` を明示する**。`codex review` (Code Review 機能) は gpt-5.3-codex 専用で、gpt-5.5 / gpt-5.4 は非対応。指定を省くと CLI デフォルト (gpt-5.5) になり、レビュー対象スコープを正しく扱えず未コミット差分を取りこぼす。`codex review` には `-m` がないため `-c 'model="..."'` で指定する。
- `codex review` は `--uncommitted` / `--base` / `--commit` などのスコープフラグと `[PROMPT]` が**排他**。両立できないため、カスタム指示を渡したいときはスコープフラグを使わず、レビュー対象をプロンプト本文で指定する (経路 A)。スコープを絞りたいときはカスタム指示を諦める (経路 B)。
- `codex review` は `-` を明示しない限り stdin を読まない。`echo ... | codex review` 形式は指示が無視されるので使わない。プロンプトは位置引数で渡す。

## VERDICT の post-process

経路 B (default prompt) では codex 出力に `VERDICT` 行が無いことがある。出力を後処理で
判定して `VERDICT: PASS` または `VERDICT: ISSUES_FOUND` を付与する:

- 「致命的」「critical」「bug」等のキーワードが出力に含まれる → `VERDICT: ISSUES_FOUND`
- そうでなければ `VERDICT: PASS`

結果を報告する。
