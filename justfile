# claude-rules-personal justfile
#
# rule (.md) / skill (.md) 配布が主。加えて hooks/ を claude plugin として配布する
# ため version を持つ (= `claude plugin update` が plugin.json / marketplace.json の
# version を見る)。lint / test / build は無く、翻訳ペア (-ja.md) も無いため
# check-outdated-translations も無し。Taskfile.pkl は pkf-tasks/pkfire の migrate
# check 用に過渡的に残存 (= 別経路で `pkf run check-migrate` 等で呼ぶ運用)。

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

# (a) for-all→for-me 越境リンク / (b) 自己参照 / (c) .draft- 配置 = fatal
# (d) 5KB 超 rule = warning のみ (省コンテキスト検討材料、fatal にしない)
# rule メタ規約 lint (push-workflow.md の commit 前チェックを機械化)
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

# (重複は片方が黙って破棄される Claude Code 仕様のため fatal)。リポ横断の
# 重複は setup.sh が警告する
# agent 定義 lint: name/description 必須 + リポ内 name 重複を検出
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

# plugin manifest 検証 (marketplace.json / plugin.json の schema)
validate:
    claude plugin validate .

# plugin.json と marketplace.json の version 一致を保証 (multi-file 整合性)。
# bump-semver get は multi-file 時に内部で整合チェック (不一致は error 表示で exit 非 0)。
[private]
check-versions:
    @bump-semver get .claude-plugin/plugin.json .claude-plugin/marketplace.json --no-hint >/dev/null

# 各 update は warn 降格: push は既に成功済なので、ここで失敗しても release 自体は
# 完了している (失敗時に exit 非 0 にすると「push 済みなのに just push 失敗表示 →
# 再実行は version gate で弾かれ詰む」)。
# release 成功後の local 反映 (単独再実行可、push からも自動で呼ばれる)
on-success-release:
    @claude plugin marketplace update rules-personal || echo "[warn] marketplace update 失敗。push は成功済み。'just on-success-release' で単独再実行可" >&2
    @claude plugin update rules-personal@rules-personal || echo "[warn] plugin update 失敗。push は成功済み。'just on-success-release' で単独再実行可" >&2
    @echo ""
    @echo "[hint] /reload-plugins to apply in this session without restart"

# plugin.json と marketplace.json の 2 ファイルを同時に進める (bump-semver が
# version 一致を保証する)。
# version を bump して Release commit を作成 (push は別途 `just push`)
bump-version bump="patch": ensure-clean (_bump-version bump ".claude-plugin/plugin.json" ".claude-plugin/marketplace.json")

[private]
[script]
_bump-version bump *version_files:
    level="$1"; shift
    new_version=$(bump-semver "$level" "$@" --write --no-hint)
    bump-semver vcs commit -m "Release v${new_version}" "$@"

# trigger paths に diff が無い push は自動 skip される (= rule/skill/docs のみの
# 変更では bump 不要)。
# plugin 配布物 (hooks/) を変えたのに version 未 bump なら push を止める
[private]
check-version-bumped: (_check-version-bumped "hooks/")

[private]
[script]
_check-version-bumped *trigger_paths:
    rc=0
    bump-semver vcs diff -q main@origin -- "$@" || rc=$?
    case "$rc" in
      0) exit 0 ;;
      1) ;;
      *) echo "ERROR: bump-semver vcs diff failed (rc=$rc). main@origin が track されていない可能性。先に 'jj git fetch' を試してください" >&2; exit 1 ;;
    esac
    # 初回リリース前は main@origin に manifest が無い = 比較対象がないので素通し。
    # vcs diff -s の name-status が A (追加) を返す = 相手側に存在しない。
    if bump-semver vcs diff -s main@origin .claude-plugin/plugin.json 2>/dev/null |
        grep -q '^A'; then
        exit 0
    fi
    bump-semver compare gt .claude-plugin/plugin.json vcs:main@origin:.claude-plugin/plugin.json --no-hint && exit 0
    echo 'ERROR: hooks/ が変わっているが version 未 bump。"just bump-version" を実行してください' >&2
    exit 1

# gates: check-on-default-branch + ensure-clean + lint-rules + lint-agents
#        + validate + check-versions + check-version-bumped
# push して local plugin cache まで反映する (release artifact 無しなので push = リリース完了)
push: check-on-default-branch ensure-clean lint-rules lint-agents validate check-versions check-version-bumped
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
    @just on-success-release
