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
        bn=$(bump-semver vcs get default-branch)
        printf >&2 "⚠ default branch (%s) に合流してから push してください\n  1. just sync         # %s@origin に rebase\n  2. just promote      # %s bookmark を current commit に forward\n  3. %s ワークスペースに移動して just push\n" "$bn" "$bn" "$bn" "$bn"
        exit 1
    fi

# 現在の worktree を default branch (= origin/<default>) に rebase (DR-0038)
sync:
    bump-semver vcs sync --onto $(bump-semver vcs get default-branch)@origin

# default branch を現在の commit に forward (DR-0038、push しない)
promote:
    bump-semver vcs promote

# rule メタ規約 lint (push-workflow.md の commit 前チェックを機械化)
# (a) for-all→for-me 越境リンク / (b) 自己参照 / (c) .draft- 配置 = fatal
# (d) 5KB 超 rule = warning のみ (省コンテキスト検討材料、fatal にしない)
lint-rules:
    #!/usr/bin/env bash
    set -uo pipefail
    fatal=0
    # (a) 越境リンク: for-all/rules/*.md の [[name]] が for-me/rules/<name>.md を指す
    while IFS= read -r f; do
        while IFS= read -r name; do
            if [ -n "$name" ] && [ -f "for-me/rules/${name}.md" ]; then
                echo "FATAL 越境リンク: $f の [[${name}]] が for-me/rules/${name}.md を指す"
                fatal=1
            fi
        done < <(rg -o '\[\[([^\]]+)\]\]' -r '$1' "$f")
    done < <(rg -l '\[\[' for-all/rules/ || true)
    # (b) 自己参照: rule ファイルが [[自分の slug]] を含む
    for f in for-all/rules/*.md for-me/rules/*.md; do
        base=$(basename "$f" .md)
        if rg -q "\[\[${base}\]\]" "$f"; then
            echo "FATAL 自己参照: $f が [[${base}]] で自身を参照"
            fatal=1
        fi
    done
    # (c) .draft- が rules 配下に存在 (draft は docs/issue/ へ)
    drafts=$(ls for-all/rules/.draft-*.md for-me/rules/.draft-*.md 2>/dev/null || true)
    if [ -n "$drafts" ]; then
        echo "FATAL .draft- が rules 配下に存在:"
        printf '%s\n' "$drafts" | sed 's/^/  /'
        fatal=1
    fi
    # (d) 5KB 超 rule (warning のみ、常時ロード肥大の検討材料)
    big=$(find for-all/rules for-me/rules -name '*.md' -size +5k | sort)
    if [ -n "$big" ]; then
        n=$(printf '%s\n' "$big" | wc -l | tr -d ' ')
        echo "WARN 5KB 超の rule ${n} 件 (rule-writing-guidelines の省コンテキスト検討):"
        while IFS= read -r bf; do
            echo "  $bf ($(wc -c < "$bf" | tr -d ' ') bytes)"
        done <<< "$big"
    fi
    if [ "$fatal" -ne 0 ]; then
        echo "lint-rules: FATAL 違反あり (上記参照)" >&2
        exit 1
    fi
    echo "lint-rules: OK (fatal 違反なし)"

# agent 定義 lint: name/description 必須 + リポ内 name 重複 (重複は片方が黙って
# 破棄される Claude Code 仕様のため fatal)。リポ横断の重複は setup.sh が警告する
lint-agents:
    #!/usr/bin/env bash
    set -uo pipefail
    fatal=0
    names=""
    for f in for-all/agents/*.md for-me/agents/*.md for-others/agents/*.md; do
        [ -f "$f" ] || continue
        name=$(awk '/^---$/{n++;next} n==1 && /^name:/{sub(/^name:[ ]*/,"");print;exit}' "$f")
        if [ -z "$name" ]; then
            echo "FATAL name 欠落: $f (frontmatter に name: が必須)"
            fatal=1
            continue
        fi
        if ! awk '/^---$/{n++;next} n==1 && /^description:/{found=1} END{exit !found}' "$f"; then
            echo "FATAL description 欠落: $f"
            fatal=1
        fi
        if printf '%s\n' "$names" | grep -qx "$name"; then
            echo "FATAL name 重複: $name ($f) — 重複 agent は片方が黙って破棄される"
            fatal=1
        fi
        names="$names"$'\n'"$name"
    done
    if [ "$fatal" -ne 0 ]; then
        echo "lint-agents: FATAL 違反あり (上記参照)" >&2
        exit 1
    fi
    echo "lint-agents: OK"

# push to origin/main (gates: lint-rules + lint-agents + check-on-default-branch + ensure-clean)
push: check-on-default-branch ensure-clean lint-rules lint-agents
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
