---
title: WorktreeCreate hook で worktree 配置先を kawaz 規約に合わせる (jj workspace 併用の検討)
status: resolved
category: design
created: 2026-08-20T16:39:34+09:00
last_read:
open_entered: 2026-08-20T16:39:34+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered: 2026-08-20T23:36:26+09:00
discard_reason:
pending_reason:
close_reason: ["hook を実装・リリース済み (rules-personal v0.2.23)。実際の worktree 作成経路での発火確認のみ別セッションに依頼中。"]
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

## 結論 (2026-08-20)

### jj workspace を返す案は成立しない (決定的)

hook を実装して headless (`claude -p`) から実起動した結果:

```
作成した wt-agent-* ディレクトリには .git ファイルが存在しないため
git identity を検証できず、Refusing to use ... as an isolation worktree で拒否された
```

`isolation: "worktree"` / `EnterWorktree` は **返されたディレクトリが git worktree であること
(= `.git` を持つこと) を検証する**。jj workspace は `.jj` だけで `.git` を持たないため、
この時点で弾かれる。**当初の動機だった「hook 経由で worktree 内でも jj を使う」は実現不能**。

### 確定した入出力契約

`claude-plugin-reference` の hooks.md §6.2 に還元済み (v0.2.31)。要点:

- stdin の `name` field に Claude Code が決めた worktree 名が来る。呼び出し側は事前に知りえないので、
  hook が配置先を決める情報源はこれだけ
- command 型の出力は **JSON でラップせず生のパスを echo**。`hookSpecificOutput` を返すと
  その JSON 文字列がパスとして解釈されて失敗する
- **hook が先にディレクトリを作ってから** echo する
- パスを返さず exit 0 すると既定動作にフォールバックせず **worktree 作成自体がエラー**
- **失敗しても副作用は巻き戻らない** (作りかけが孤児として残る) ので hook は冪等に書く必要がある

### 採否: 実装する (kawaz 裁定 2026-08-20)

当初こちらは「配置先の規約準拠しか得られない」ことを理由に実装しない方に傾いていたが、
これは **現行運用を維持したままの前提** で価値を評価した誤りだった。kawaz の提案は
「bare をやめて colocate にする / ガードは空ファイルで行う / worktree の位置を運用規約に
合わせる」という一体のもので、前提そのものが変数だった。

裁定の内容:

- **配置先**: `dirname(cwd)/<name>` (= 恒久 workspace の兄弟)。名前はハーネスが渡す
  `agent-<id>` のまま使い、「`agent-` prefix = サブエージェントの使い捨て作業場」という
  判別規約とする。掃除対象を `{repo}/agent-*` で機械判定できるようになる
- **配布範囲**: plugin として全リポ一律配布。リポ個別設置は配置が不揃いになるため不採用。
  「hook のバグ = 全リポ影響」は dogfood として受容する
- **掃除**: 自動化しない。`WorktreeRemove` hook は `ExitWorktree` 経路で発火しないことが
  実測済みのため。repo 直下に並ぶので放置に気づきやすく、prefix で消してよいものが分かる。
  SessionStart での sweep 等も**現時点では作らない** (kawaz 裁定: ゴミが溜まってからでいい)

### 実装 (rules-personal v0.2.23)

`hooks/worktree-create-path.sh` + `hooks.json` の `WorktreeCreate` 登録。

裁定に対する実装判断が 2 点:

1. **ブランチ名は `worktree-<name>`** (既定挙動と同じ prefix)。hook を外した時に差分が
   出ないため。ディレクトリ名は `agent-<id>` のままなので掃除の機械判定には影響しない
2. **レイアウトのガードを入れた**。`dirname(cwd)/<name>` を適用するのは「親ディレクトリ名が
   remote のリポ名と一致する」場合のみで、外れたら既定の `.claude/worktrees/` に作る。
   全リポ一律配布のため `{repo}/{workspace}` レイアウトでないリポでも発火し、無条件適用だと
   リポの外側に worktree を撒くことになるため

**この hook はパスを返せないと既定動作に fallback せず worktree 作成自体が落ちる**ので、
どの経路でも必ずパスを 1 つ返す構造にしてある。

検証: **実 worktree 経路での発火確認まで完了** (別セッションが headless から
`isolation: "worktree"` agent を起動して確認、全 3 項目 PASS)。

- 配置先: `{repo}/agent-<id>/` = 恒久 workspace の兄弟 (`git worktree list` でも実体確認)
- branch: `worktree-agent-<id>`
- hook 起因のエラーなし、agent は正常に起動・完了

加えてスクリプト単体で 6 ケース実測済み (規約レイアウトでの作成 / 同一 name 再実行の冪等性 /
素の clone でのフォールバック / remote 無し / 規約パスに無関係な既存ディレクトリがある場合に
既存を壊さず退避 / name のパストラバーサル拒否)。実際の worktree 作成経路での発火確認は
別セッションに依頼中。

## 受け入れ条件

- [x] WorktreeCreate hook の stdin 契約を実機で確認する
- [ ] WorktreeRemove の後始末 semantics を実機で確認する
- [x] 上記を踏まえて、hook 実装の採否と方針を決める (実装するなら本リポの hooks/ に置く)
- [x] 確認した契約は claude-plugin-reference 側へ還元する (現在 TODO のため)
