---
title: WorktreeCreate hook で worktree 配置先を kawaz 規約に合わせる (jj workspace 併用の検討)
status: open
category: design
created: 2026-08-20T16:39:34+09:00
last_read:
open_entered: 2026-08-20T16:39:34+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: 別プロジェクトのセッションからの依頼 (ccmsg r149)
---

# WorktreeCreate hook で worktree 配置先を kawaz 規約に合わせる (jj workspace 併用の検討)

## 概要

Claude Code の `isolation: "worktree"` / `EnterWorktree` が作る worktree の配置先を、
kawaz のパス規約 (`{repo}/{name}/` = `main/` の兄弟) に合わせる `WorktreeCreate` hook の
実装を検討する。ある案件リポで jj worktree shim の除去を検討しており、その置き換え先の
候補として挙がった。

## 背景

Claude Code v2.1.237 のバイナリから直接確認した文字列:

```
WorktreeCreate hook failed: hook succeeded but returned no worktree path
(command: echo the path to stdout; http/callback: return hookSpecificOutput.worktreePath)
```

- command 型 hook なら作成したパスを stdout に echo するだけで配置先を決められる
- `claude-plugin-reference` の hooks.md でも WorktreeCreate は blockable (= 既定の git 挙動を replace 可) と記載
- 既定の `.claude/worktrees/` はハードコードで、symlink による差し替えは明示的に防御されている
  = hook が正規経路

依頼元セッションでの実測: jj worktree shim は PATH で git を横取りする層で、以下 3 つの問題を抱える。

- `git worktree list` のパス誤構築
- `--porcelain` 非対応
- メタファイルを作業ツリーに作り追跡対象にしてしまう

shim を除去したいが、除去すると worktree 内で jj が使えなくなるのが唯一の後退点。
hook から `jj workspace add` してそのパスを echo すれば、配置先の規約準拠と worktree 内 jj の
両方が満たせる見込み。shim が PATH 全体を横取りするのに対し、hook は worktree 作成の 1 点だけに
介入する点も利点。

## 未検証事項 (採否の前に裏取りが要る)

- hook の stdin に何が渡るか (要求された名前・ブランチ名) が未確認
- WorktreeRemove の後始末 semantics が未確認 (claude-plugin-reference 側も TODO のまま。
  実務上の経路は下記「実測結果」節で判明済み、stdin 契約の未確認は別)
- jj workspace を hook で作った場合の、Claude Code 側の後始末との整合

## 実測結果 (2026-08-20、依頼元セッション)

jj worktree shim を無効化した状態で `isolation: "worktree"` の agent を実起動した結果。

### 配置先と命名 (hook 無しの既定挙動)

```
pwd:    <repo>/main/.claude/worktrees/agent-<agentId>
branch: worktree-agent-<agentId>
```

- 配置先は `.claude/worktrees/` にハードコード
- **`agentId` は spawn 時にランタイムが生成する内部 ID で、依頼側からは事前に分からない**
  → hook で規約準拠のパスを作るなら、**名前の情報源は stdin しかない**。stdin 契約の確認が
  実装可否を決めるという位置づけが裏付けられた

### agent 完了通知に worktree 情報が同梱される (新発見)

agent 完了通知の末尾に構造化フィールドが付く:

```
<worktree><worktreePath>...</worktreePath><worktreeBranch>...</worktreeBranch></worktree>
```

これは hook の stdin 契約とは別物 (親セッションへの通知経路)。

### 後始末は呼び出し側の責任

- agent 終了後、worktree は **自動削除されない**。branch も commit も残る
- agent 稼働中は `git worktree list` に `locked` が付き、完了後は lock が外れて
  素の `git worktree remove` で消せる (exit 0)
- jj 側は `git worktree remove` 後も bookmark が残るため `jj bookmark delete` が別途要る
  (jj は到達不能コミットの abandon はするが bookmark は消さない)
- ハーネスが自動でやるのは lock 解除まで

### 親リポへの汚染なし

`git status --short` は空 (`.claude/worktrees/` は .gitignore 対象で untracked にも出ない)。
worktree 内の commit は jj 側に自動 import され bookmark として見える (`jj git import` が暗黙実行)。

### 残る穴

**WorktreeCreate hook の stdin 契約は依然未確認。** 依頼元が次に hook を実際に書いて確認する予定。
加えて、hook で `jj workspace add` した場合に「自動削除されない」性質がどう効くか
(= 呼び出し側が `git worktree remove` 相当を試みると jj workspace が壊れないか) も確認が要る。

## 受け入れ条件

- [ ] WorktreeCreate hook の stdin 契約を実機で確認する
- [ ] WorktreeRemove の後始末 semantics を実機で確認する
- [ ] 上記を踏まえて、hook 実装の採否と方針を決める (実装するなら本リポの hooks/ に置く)
- [ ] 確認した契約は claude-plugin-reference 側へ還元する (現在 TODO のため)
