# claude-rules-personal justfile
#
# 2 系統の配布を持つ:
#   - rules (for-*/rules/) — setup.sh が $CLAUDE_CONFIG_DIR へ symlink。plugin には
#     rule を注入する機構が無いのでこちらは symlink 継続
#   - plugin (hooks/ skills/ agents/) — `rules-personal` plugin として配布。
#     version を持つのはこのため (`claude plugin update` が manifest の version を見る)
# lint / test / build は無く、翻訳ペア (-ja.md) も無いため check-outdated-translations
# も無し。Taskfile.pkl は pkf-tasks/pkfire の migrate check 用に過渡的に残存。

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
    # (e) dead wikilink: [[slug]] が rules ファイル名 / skills ディレクトリ名 /
    #     外部 overlay の許容リストのいずれにも解決できない = 改名・統合の置き去り。
    #     除外するもの: [[#見出し]] (同一ファイル内アンカー)、`[[名前]]` のような
    #     記法そのものの説明 (バッククォートで囲まれた 1 語)。
    { ls for-all/rules/ for-me/rules/ 2>/dev/null | grep '\.md$' | sed 's/\.md$//'
      ls -d skills/*/ 2>/dev/null | xargs -n1 basename
      grep -vE '^[[:space:]]*(#|$)' .lint-external-slugs 2>/dev/null
    } | sort -u > /tmp/lint-known-slugs.$$
    grep -rhoE '\[\[[^]]+\]\]' for-all/ for-me/ skills/ agents/ 2>/dev/null |
        sed 's/^\[\[//; s/\]\]$//' | grep -v '^#' | sort -u > /tmp/lint-used-slugs.$$
    dead=$(comm -23 /tmp/lint-used-slugs.$$ /tmp/lint-known-slugs.$$)
    rm -f /tmp/lint-known-slugs.$$ /tmp/lint-used-slugs.$$
    while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        # 記法の説明 (`[[名前]]` のようにバッククォート内) は実体を持たない
        if rg -qF "\`[[${slug}]]\`" for-all/rules/ for-me/rules/ 2>/dev/null; then continue; fi
        echo "FATAL dead wikilink: [[${slug}]] が解決できない"
        rg -n --no-heading -F "[[${slug}]]" for-all/ for-me/ skills/ agents/ 2>/dev/null | sed 's/^/    /'
        echo "  → 改名なら参照を直す / 外部 overlay の rule なら .lint-external-slugs に追加"
        fatal=1
    done <<< "$dead"
    # (d) 5KB 超 rule (warning のみ、常時ロード肥大の検討材料)
    big=$(find for-all/rules for-me/rules -name '*.md' -size +5k | sort)
    if [ -n "$big" ]; then
        n=$(printf '%s\n' "$big" | wc -l | tr -d ' ')
        echo "WARN 5KB 超の rule ${n} 件 (rule-writing-guidelines の省コンテキスト検討):"
        while IFS= read -r bf; do
            echo "  $bf ($(wc -c < "$bf" | tr -d ' ') bytes)"
        done <<< "$big"
    fi
    # (f) 常時ロード合計の予算 (warning のみ、kawaz 裁定 2026-07-26 BD-Q1=a)
    #     80KB は「現況から増えたら気づく」ための線であって目標値ではない。
    #     現況を下回る値にすると常時 warning になり警告が無視されるので避けた。
    #     検査できるのは自リポ分のみ (他 overlay の rules は lint から見えない)。
    total=$(cat for-all/rules/*.md for-me/rules/*.md 2>/dev/null | wc -c | tr -d ' ')
    budget=81920
    if [ "$total" -gt "$budget" ]; then
        echo "WARN 常時ロード rules 合計 ${total} bytes が予算 ${budget} を超過 (skill への降格を検討)"
    fi
    if [ "$fatal" -ne 0 ]; then
        echo "lint-rules: FATAL 違反あり (上記参照)" >&2
        exit 1
    fi
    echo "lint-rules: OK (fatal 違反なし)"

# (重複は片方が黙って破棄される Claude Code 仕様のため fatal)
# agent 定義 lint: name/description 必須 + name 重複 + ゼロ件を検出
lint-agents:
    #!/usr/bin/env bash
    set -uo pipefail
    fatal=0
    names=""
    count=0
    for f in agents/*.md; do
        [ -f "$f" ] || continue
        count=$((count + 1))
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
    # ゼロ件は「検査した結果 OK」ではなく glob の破綻 (パス変更・移動漏れ)。
    # 無検査で OK を出すと移行事故を silent pass するので fatal にする。
    if [ "$count" -eq 0 ]; then
        echo "FATAL agents/*.md が 1 件も見つからない (glob の破綻か移動漏れ)" >&2
        exit 1
    fi
    if [ "$fatal" -ne 0 ]; then
        echo "lint-agents: FATAL 違反あり (上記参照)" >&2
        exit 1
    fi
    echo "lint-agents: OK (${count} 件)"

# plugin manifest 検証 (marketplace.json / plugin.json の schema)
validate:
    claude plugin validate .

# plugin.json と marketplace.json の version 一致を保証 (multi-file 整合性)。
# bump-semver get は multi-file 時に内部で整合チェック (不一致は error 表示で exit 非 0)。
[private]
check-versions:
    @bump-semver get .claude-plugin/plugin.json .claude-plugin/marketplace.json --no-hint >/dev/null

# plugin cache は $CLAUDE_CONFIG_DIR 配下にあるため、環境ごとに update が要る
# (personal で叩いても emeradaco 側は古いまま)。環境一覧の正本は repos_mapping.json
# の home フィールド (rule 側に環境一覧を複製しない規約)。
# 各 update は warn 降格: push は既に成功済なので、ここで失敗しても release 自体は
# 完了している (失敗時に exit 非 0 にすると「push 済みなのに just push 失敗表示 →
# 再実行は version gate で弾かれ詰む」)。
# release 成功後の local 反映 (全 CLAUDE_CONFIG_DIR、単独再実行可、push から自動)
[script]
on-success-release:
    fail=0
    while IFS= read -r home; do
        dir="${home/#\~/$HOME}"
        [ -d "$dir" ] || { echo "[skip] $home (dir 無し)"; continue; }
        echo "--- $home"
        CLAUDE_CONFIG_DIR="$dir" claude plugin marketplace update rules-personal || fail=1
        CLAUDE_CONFIG_DIR="$dir" claude plugin update rules-personal@rules-personal || fail=1
    done < <(jq -r '.repos[] | select(.home != null and .home != "") | .home' repos_mapping.json)
    if [ "$fail" -ne 0 ]; then
        echo "[warn] 一部環境で update 失敗。push は成功済み。'just on-success-release' で単独再実行可" >&2
    fi
    echo ""
    echo "[hint] 各環境のセッションで /reload-plugins すると restart 無しで反映される"

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

# trigger paths に diff が無い push は自動 skip される (= rules/ や docs/ のみの
# 変更では bump 不要)。
# plugin 配布物 (hooks/ skills/ agents/) を変えたのに version 未 bump なら push を止める
[private]
check-version-bumped: (_check-version-bumped "hooks/" "skills/" "agents/")

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
    echo 'ERROR: plugin 配布物 (hooks/ skills/ agents/) が変わっているが version 未 bump。"just bump-version" を実行してください' >&2
    exit 1

# gates: check-on-default-branch + ensure-clean + lint-rules + lint-agents
#        + validate + check-versions + check-version-bumped
# push して local plugin cache まで反映する (release artifact 無しなので push = リリース完了)
push: check-on-default-branch ensure-clean lint-rules lint-agents validate check-versions check-version-bumped
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
    @just on-success-release
