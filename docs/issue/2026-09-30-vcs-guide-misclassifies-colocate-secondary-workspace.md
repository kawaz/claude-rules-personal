---
title: vcs-guide hook が colocate の恒久 workspace を旧方式と誤判定する
status: open
category: bug
created: 2026-09-30T09:46:48+09:00
last_read:
open_entered: 2026-09-30T09:46:48+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: workboard-personal
---

# vcs-guide hook が colocate の恒久 workspace を旧方式と誤判定する

## 概要

個人リポ (colocate 新標準、`{repo}/main/` + 恒久 workspace `{repo}/incubator/`) の
`incubator/` を cwd にして `bump-semver vcs push --branch incubator` を実行したところ、
PreToolUse の vcs-guide hook が「このリポは旧方式 (git bare + jj workspace) です」と案内した。
同じリポの `main/` では正しく colocate と案内された。

## 背景 (観測 2026-09-30)

案内文は hook の bare 分岐 (135 行付近) の内容で、`jj-bare-workspace-setup.md` を読み、
あわせて `jj-colocate-setup.md` の「移行 (旧方式リポの入れ替え)」節を読んで colocate への
移行を検討してくださいという内容だった。

## 一次資料

- `hooks/vcs-guide.sh:44-49` で `repo_root` を `git rev-parse --show-toplevel` で求め、
  `hooks/vcs-guide.sh:59-68` で `[ -d "$repo_root/.git" ] && [ -d "$repo_root/.jj" ]` なら
  colocate、`[ -e "$repo_root/.jj" ]` なら bare、それ以外は git-only と判定している。
  コメント (59-60 行) は「secondary workspace では `.jj` が file のことがある」を bare 側の
  ものと想定している。
- 恒久 workspace `{repo}/<name>/` は `jj workspace add` で作られ `.jj` のみを持つ
  (`.git` は無い) ため、`repo_root=<name>/` では 62 行の条件を満たさず 64 行の bare 分岐に
  落ちる (repo_root が `<name>/` になる点は `git rev-parse` の結果に依存するので裏取り要)。
- `reference/vcs/jj-colocate-setup.md` の「レイアウト」節は
  `<name>/  # 恒久 workspace (jj workspace add で作る。命名は従来規約のまま)` を colocate の
  正規レイアウトとして定義し、「作業場所の使い分け (最重要)」節の表でも恒久 workspace
  `<name>/` を `main/` 内から `jj workspace add ../<name>` で作り中で jj を使う場所と
  定めている。つまり正規レイアウトの作業場所が旧方式と誤判定されている。

## 要望

恒久 workspace を cwd にした時も colocate として案内してほしい (判定に
`{repo}/main/.git` の存在や `jj workspace root` / `jj root` の結果を使う等は hook 側の
判断)。フラグ止まりなので、対象コードを読んで該当性を裏取りしてから採否を決めてほしい。

## 実機確認

上記観測 1 件 (incubator/ で誤案内、main/ で正案内)。マトリクス検証 (他リポの恒久
workspace) は未実施。

## 受け入れ条件

- [ ] hook 側のコードを読み、該当性を裏取りした上で採否を判断する
