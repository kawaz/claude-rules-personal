# justfile の recipe 設計

各リポのタスクランナーは **`justfile`** を canonical とする。kawaz/bump-semver の `justfile` が基準実装。新規リポでは kawaz のアクティブなリポジトリの justfile を参考に書く。言語やカテゴリが近いリポ以外も含む最低 5 個を読んで共通パターンの把握と進出の良パターンを取り入れる検討をする。

```bash
ls -lt ~/.local/share/repos/github.com/kawaz/*/main/justfile | head
```

bump-semver / session-analysis 等の justfile を見ると、概ね次の recipe が並ぶ (詳細は実体):

- `ci` — lint + test
- `check-outdated-translations` — 翻訳 commit-lag 検出 (`bump-semver vcs outdated`)
- `check-version-bumped` — product code 変更時に VERSION 進行を要求 (paths でフィルタ)
- `bump-version` — `bump-semver --write` で version file 更新 + `jj commit`
- `ensure-clean` — working tree clean 検証
- `push` — 上記 gate を deps に並べて `bump-semver vcs push` を叩く

**push 順序の注意 (mutating lint との関係)**: `ci` が `gofmt -w` 等で tree を mutate するリポでは `ensure-clean` を `ci` の **後** に置く (bump-semver は `check-outdated-translations` の transitive 依存で `ensure-clean` が `ci` 後に走る形)。`prettier --check` / `cargo fmt --check` / `oxfmt --check` 等 non-mutating lint のみのリポは `push` の先頭で `ensure-clean` を回しても問題ない。

## just 変数は使わない

just の変数 (`name := value`) は文字列のみ扱え、shell 内 embed で quote 問題を起こす。値の受け渡しは **positional argument** 経由にする (`set positional-arguments` で `$1` / `"$@"` が使える)。

- list 値 (= `bump-trigger-paths` 等) は recipe の dependency 引数渡しで表現:
  ```just
  check-version-bumped: (_check-version-bumped "src/" "go.mod" "go.sum")
  _check-version-bumped *target_paths:
      if ! bump-semver vcs diff -q main@origin -- "$@" ...; then ...
  ```
- shell 内で動的に値を取りたい時は just 変数経由ではなく shell ネイティブの `$(...)` を直接書く:
  ```just
  push:
      @echo "[hint] ... --sha $(bump-semver vcs get commit-id --rev main) ..."
  ```

## バージョン bump recipe

- recipe 名 `bump-version`、引数 `level`（`patch` / `minor` / `major`、default `patch`）
- 実装は `bump-semver` CLI を 1 行で呼び `--write --no-hint` で version file を書き換え、返った新 version を `jj commit -m "Release v..."` に流す
- bump 対象ファイルは各リポで指定（`bump-semver` が basename で形式判定。`VERSION` / `Cargo.toml` / `*.json` を複数一括可、不一致は CLI がエラー停止）
- 言語固有の追従処理（例: Rust の `cargo check` で Cargo.lock 再生成）は `bump-semver --write` の直後・`jj commit` の前に挟み、同一 change で確定
- ツール本体は `kawaz/tap/bump-semver`

## push 時の version bump 漏れ検出

product code に変更があるのに version が `main@origin` から進んでいなければ push を止める gate。`check-version-bumped` recipe を `push` の deps に入れる。trigger paths (= 検出対象) は recipe 内の shell logic で書く (docs / justfile 等の変更は除外)。trigger paths の diff が無い push は自動 skip されるので `push-without-bump` のような別 recipe は不要 (= src 変更したら必ず release という invariant をバイパスさせない)。具体的な実装は bump-semver の `justfile` 参照。

## worktree からの push gate (sync / promote / push)

worktree (git linked worktree / jj secondary workspace) で作業した change を default branch に合流させずに push しようとするのを止める gate。`bump-semver` v0.40.0+ の `vcs sync` / `vcs promote` / `vcs is on-default-branch` (= DR-0038) を使い、jj/git の差異を justfile に隠蔽する。

- `push` の deps 先頭に `check-on-default-branch` を置く
- `sync` (= `vcs sync --onto <default>@origin`) と `promote` (= `vcs promote`) を公開 recipe として並べる (AI・人間の双方が直接叩くので `[private]` にしない)
- gate の predicate は **`vcs is on-default-branch` の反転**。`vcs is worktree` を使ってはいけない — git bare + jj workspace 方式では `main/` 自体が secondary workspace なので `main` でも true を返し、正常な push を誤ってブロックする (DR-0038 Adoption pattern)
- `vcs is` は predicate-false 時に stderr へ何も出さない (`compare` と同じ semantics) ので、cascade の hint は **justfile 側で `printf >&2`** する

recipe の実体と adopt 手順は `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/docs-authoring/templates/runbooks/worktree-workflow.template.md`、実装例は claude-rules-personal 自身の `justfile`。

## リリース artifact の有無

配布 artifact (tag + GH Release で配るバイナリ / library 等) を作るリポは `.github/workflows/release.yml` (or 相当) を持ち、push を契機に tag + Release を自動作成する (詳細は reference の `justfile/release-pipeline`)。

artifact を作らないリポ (release workflow を持たないリポ) では `push = リリース完了` とみなして良く、push 後に release / tag の生成を待たない。他用途の workflow (lint CI / security scan 等) があれば、そちらは通常通り watch する。
