# claude-rules-personal justfile
#
# rule (.md) / skill (.md) 配布が主。lint / test / build / version は持たない。
# 翻訳ペア (-ja.md) も無いため check-outdated-translations も無し。push gate は
# `ensure-clean` のみで十分。Taskfile.pkl は pkf-tasks/pkfire の migrate check
# 用に過渡的に残存 (= 別経路で `pkf run check-migrate` 等で呼ぶ運用)。

set shell := ["bash", "-euo", "pipefail", "-c"]

set positional-arguments

# default: list
default: list

# show recipes
list:
    @just --list --unsorted

# uncommitted change がない状態か確認 (dogfood: bump-semver vcs is clean)
[private]
ensure-clean:
    bump-semver vcs is clean

# 現在の bookmark/branch が default (= main) 上にあるか確認 (DR-0038 dogfood)
# default 以外なら sync→promote→push の cascade hint を出して exit 1。
# `vcs is on-default-branch` の反転を使う (= `vcs is worktree` だと kawaz の
# jj 運用で main workspace 自体が secondary workspace なので誤検出する、
# bump-semver v0.40.1 DR-0038 Adoption pattern 節参照)。
[private]
[script]
check-on-default-branch:
    if ! bump-semver vcs is on-default-branch; then
        cur=$(bump-semver vcs get current-branch 2>/dev/null || echo "(ambiguous)")
        bn=$(bump-semver vcs get default-branch)
        printf >&2 "⚠ 現在 '%s' bookmark/branch にいます。%s に合流してから push してください\n  1. just sync         # %s@origin に rebase\n  2. just promote      # %s bookmark を current commit に forward\n  3. %s ワークスペースに移動して just push\n" "$cur" "$bn" "$bn" "$bn" "$bn"
        exit 1
    fi

# 現在の worktree を default branch (= origin/<default>) に rebase (DR-0038)
sync:
    bump-semver vcs sync --onto $(bump-semver vcs get default-branch)@origin

# default branch を現在の commit に forward (DR-0038、push しない)
promote:
    bump-semver vcs promote

# push to origin/main (gates: check-on-default-branch + ensure-clean)
push: check-on-default-branch ensure-clean
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
