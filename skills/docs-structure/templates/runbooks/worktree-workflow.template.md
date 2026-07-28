# Runbook: worktree/workspace 経由作業の合流と push

- Last Updated: YYYY-MM-DD

## 適用ケース

worktree (git linked worktree / jj secondary workspace) 内で編集した change を
default branch に合流させて push したい時。特に:

- Claude Code の background job / `isolation: "worktree"` で `EnterWorktree` が使われた
- `just push` が `check-on-default-branch` で止まり、cascade の hint が出た
- 親 workspace が先に進んでいて、worktree のベースが古い

## 前提

- `bump-semver` v0.40.0 以上 (`vcs is on-default-branch` / `vcs get default-branch` /
  `vcs get worktree-name` / `vcs promote` / `vcs sync` を使う)
- リポの justfile に `sync` / `promote` / `check-on-default-branch` recipe が入っている
  (未導入なら「## adopt 手順」を先に実施)

## 手順

1. **worktree 内で編集 → パス指定で commit**

   ```bash
   bump-semver vcs commit -m "<msg>" <files...>
   ```

   パス指定は必須 (他 workspace の未認識変更を巻き込まないため)。
   期待結果: 変更が固定され、jj なら `@` が空 change に進む。

2. **`just push` を試す**

   ```bash
   just push
   ```

   期待結果: default branch 上にいなければ `check-on-default-branch` が
   cascade の hint を出して exit 1。default branch 上なら通常の push gate に進む。

3. **ベースを default branch に揃える**

   ```bash
   just sync      # = bump-semver vcs sync --onto <default>@origin
   ```

   期待結果: 現 worktree が `<default>@origin` に rebase される。
   conflict は exit 3 で伝播するので、その場合は jj/git のconflict 解決手順で解く。

4. **default branch を current commit に forward**

   ```bash
   just promote   # = bump-semver vcs promote
   ```

   期待結果: default branch/bookmark が current commit に進む (push はしない)。
   forward-only。exit 5 (non-fast-forward) なら手順 3 の sync が済んでいない。

5. **default branch を持つ workspace に移動して push**

   ```bash
   cd "$(bump-semver vcs get default-branch-path)"
   just push
   ```

   期待結果: `check-on-default-branch` を通過し、リポの全 gate を経て push される。

## sync → promote → push が 3 段に分かれている理由

DR-0038 (bump-semver) の設計で、1 verb = 1 副作用に分解されている:

| verb | 副作用 |
|---|---|
| `sync` | worktree を default に揃える (rebase) |
| `promote` | default branch/bookmark を current に forward (ref 移動のみ) |
| `push` | remote へ反映 |

`promote` が push しないので、promote 結果を確認してから push する / promote 後に
commit を足してから push する、といった分解が素直に書ける。

## gate の predicate は `is worktree` ではなく `is on-default-branch`

`vcs is worktree` を push gate に使ってはいけない。git bare + jj workspace 方式では
`main/` 自体が secondary workspace なので、`vcs is worktree` は `main` でも true を
返し、**正常な push を誤ってブロックする** (DR-0038 Adoption pattern 節)。

実際に問うべきは「現 bookmark/branch が push 対象の default か」なので
`vcs is on-default-branch` の反転が正しい。両 predicate の責務は分離されている:

- `is worktree` — **場所** (linked worktree / secondary workspace か)
- `is on-default-branch` — **bookmark/branch** (default か)

## 詰まり所の切り分け

| 症状 | 原因 | 対処 |
|---|---|---|
| `just push` が exit 1、gate 名だけ表示 | `vcs is` は predicate-false 時 stderr に何も出さない仕様 | justfile 側で hint を printf する (下記 adopt 手順のテンプレ参照) |
| `just promote` が exit 5 | default branch が current の ancestor でない (diverged) | 先に `just sync` |
| `just sync` が exit 3 | rebase conflict / 未知の ref | jj/git の conflict 解決手順で解く。ref 不明なら `bump-semver vcs fetch` |
| `vcs is clean` が jj で dirty 判定 | jj は read 時 snapshot するので新規ファイルも dirty | `bump-semver vcs commit -m ... <files...>` で固定するか `jj new` で空 change を上に作る |
| workspace 切り替え後にファイルが読めない | WC 切り替えで AI 側のファイル状態が無効化される | 対象ファイルを読み直す |
| 共通祖先から 2 line に分岐している | 別 workspace が先に進んだ | 自分の line の root change を `jj rebase -s <root-change> -d <default>` で持ち上げる |
| promote 後に別 workspace が "branch is ahead" | git backend は `update-ref` で ref だけ進める仕様 | 別 workspace 側で `git pull --ff-only` / reset (利用者の責任) |

## adopt 手順 (未導入リポに入れる)

justfile に以下 3 recipe を足し、`push` の deps 先頭に `check-on-default-branch` を置く。

```just
# 現在の bookmark/branch が default 上にあるか確認 (bump-semver DR-0038)
# `vcs is on-default-branch` の反転を使う (`vcs is worktree` は
# git bare + jj workspace 方式で main workspace を誤検出する)
[private]
[script]
check-on-default-branch:
    if ! bump-semver vcs is on-default-branch; then
        bn=$(bump-semver vcs get default-branch)
        printf >&2 "⚠ default branch (%s) に合流してから push してください\n  1. just sync         # %s@origin に rebase\n  2. just promote      # %s bookmark を current commit に forward\n  3. %s ワークスペースに移動して just push\n" "$bn" "$bn" "$bn" "$bn"
        exit 1
    fi

# 現在の worktree を default branch (= origin/<default>) に rebase
sync:
    bump-semver vcs sync --onto $(bump-semver vcs get default-branch)@origin

# default branch を現在の commit に forward (push はしない)
promote:
    bump-semver vcs promote

push: check-on-default-branch <既存の gate...>
    bump-semver vcs push --branch "$(bump-semver vcs get default-branch)" --jj-bookmark-auto-advance
```

hint の printf は `vcs is` が predicate-false 時に silent (`compare` と同じ semantics) な
ため justfile 側で持つ。`sync` / `promote` は AI・人間の双方が直接叩くので `[private]` に
しない。

導入確認:

```bash
just sync --dry-run 2>/dev/null || just --list   # recipe が見えるか
bump-semver vcs is on-default-branch && echo on-default || echo not-on-default
```

## 関連

- bump-semver `docs/decisions/DR-0038-vcs-worktree-promote-sync.md` — 3 verb の設計と
  Adoption pattern (gate predicate の選択)
- `bump-semver vcs {is,get,sync,promote} --help` — 引数・exit code の正本
- {自リポの journal / findings}
