#!/usr/bin/env bash
# PreToolUse(Bash) hook: パターン一致で複数プロセスを殺すコマンドを拒否する。
# 個別 pid の `kill <pid>` は通す。
#
# 目的 — `pkill -f <部分文字列>` や `kill $(pgrep …)` は、隔離テスト用に自分で立てた
# 1 本を止めるつもりで、同じ引数形を持つ全セッションの常駐プロセス (ccmsg subscribe
# 等) を巻き込む。指示書で禁じても worker が守らない事例があったので (2026-09-05、
# 全セッションの subscribe が一斉停止)、設定側で機械的に止める。kawaz 裁定: kill は
# 許可し killall 系をガード。
#
# 判定はコマンド位置 (行頭 / `;` `|` `&&` `||` `(` `$(` バッククォートの直後、
# sudo / env / exec / nohup / time / command の後ろ) にある語だけを見る。commit
# メッセージや echo の引数、grep のパターンに同じ語が出ても拒否しない。
#
# 拒否: pkill / killall / xargs kill / kill … $(pgrep|pidof|lsof|ps …) (バッククォート含む)
# 許可: kill <pid> / kill -TERM <pid> / kill %1 / kill $(cat pidfile)
cmd=$(jq -r '.tool_input.command // ""')
sp='[[:space:]]'
# コマンド位置: 区切りの直後 + 前置コマンドの列
pos="(^|[;&|(\`{]|\\\$\\()$sp*((sudo|command|exec|nohup|time|env)$sp+)*"
w='[^A-Za-z0-9_./-]'
re="${pos}(pkill|killall)([^A-Za-z0-9_.-]|\$)|${pos}xargs$sp+(-[^[:space:]]+$sp+)*kill([^A-Za-z0-9_.-]|\$)|${pos}kill$sp+(-[^[:space:]]+$sp+)*(\\\$\\(|\`)$sp*(pgrep|pidof|lsof|ps)($w|\$)"
if printf '%s' "$cmd" | grep -Eq "$re"; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"pkill / killall / xargs kill / kill $(pgrep|lsof|ps …) はパターン一致で無関係なプロセス (他セッションの ccmsg subscribe 等) を巻き込むため禁止。対象 pid を事前に特定して `kill <pid>` を使うこと。"}}'
fi
exit 0
