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

# push to origin/main (gates: ensure-clean のみ)
push: ensure-clean
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
