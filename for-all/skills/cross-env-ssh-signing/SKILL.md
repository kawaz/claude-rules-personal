---
name: cross-env-ssh-signing
description: kawaz の複数 CLAUDE_CONFIG_DIR 環境 (個人面 / emeradaco 業務面 / 他 overlay) をまたいで越境作業する際の SSH 認証・commit signing 切替の詳細手順書。`git push` / `git fetch` の ssh 認証 (経路 A = `~/.ssh/config` の `Match exec` / `IdentityAgent`) と、jj/git の commit signing (経路 B = `ssh-keygen -Y sign` が `SSH_AUTH_SOCK` 直読み) の違い、`No private key found / SSH sign failed` の対処、`SSH_AUTH_SOCK` 一時切替 / `signing.key` の repo-local override 手順を扱う。別環境のリポへ `jj git push` / `git push` / `git commit -S` する場面、越境 signing が `SSH sign failed` で落ちた場面で使う。同一環境内の通常 push では不要。概念 (なぜ環境分離するか) は `claude-config-dir-isolation` rule を参照。
---

# 越境作業の SSH 認証 / commit signing 切替

別環境 (`CLAUDE_CONFIG_DIR=~/.claude-X` で起動中のセッションから、別環境 Y のリポ) で
push / signing を伴う操作をするときの手順。**ssh 系の認証パスは 2 経路あり、それぞれ仕組みが違う**。

概念 (`~/.claude` regular file 化・環境ごとの CLAUDE_CONFIG_DIR・越境の一般形) は
[[claude-config-dir-isolation]] を参照。本 skill はその「SSH 認証の切替メカニズム」の詳細手順。

## 越境の基本形 (cd でほぼ自動切替)

```bash
# 環境 Y の作業ディレクトリへ cd した瞬間に下記が自動で切り替わる:
#   - direnv が .envrc を発火 → 環境変数 (GH_CONFIG_DIR 等) が切替
#   - ~/.ssh/config の Match exec 句が cwd / git remote を判定して
#     IdentityAgent (= 使う ssh-agent) を切替
# サブシェル化 (( ... )) で囲むことで、cwd や env を元のセッションに残さない。
(cd /path/to/env-Y/<repo> && <command>)
```

ただし **commit signing (経路 B) は cd では切り替わらない** (下記)。

## 経路 A: ssh コマンド経由 (`git push` / `git fetch` 等での認証)

`~/.ssh/config` の `Host` / `Match` 句が効く。`SSH_AUTH_SOCK` 環境変数は
`IdentityAgent` 指定があれば**無視される**。

```sshconfig
# ~/.ssh/config 抜粋
Match exec "pwd | grep -qE 'github.com/(env-Y-account)' || git remote get-url origin 2>/dev/null | grep -qE 'github.com[/:](env-Y-org|env-Y-account)/'"
  IdentityAgent ~/.ssh/agent-env-Y.sock

Host *
  IdentityAgent ~/.ssh/agent-default.sock  # 個人面用
```

これにより、`cd /path/to/env-Y/<repo>` で入った瞬間 (= ssh コマンドの cwd が変わった瞬間)、
`Match exec` の判定で IdentityAgent が動的に切り替わる。**`SSH_AUTH_SOCK` の export は不要**
(むしろ ssh.config が優先するので無意味)。

## 経路 B: `ssh-keygen -Y sign` 経由 (jj/git の commit signing)

**`~/.ssh/config` を見ない。代わりに `SSH_AUTH_SOCK` 環境変数で指された
ssh-agent と直接通信する**。`Match exec` の判定は発動しないため、cwd を
変えただけでは signing に使う鍵は切り替わらない。

```
# 失敗パターン: SSH_AUTH_SOCK=agent-A (= 鍵A) のセッションで、
# signing.key = 鍵B (kawaz 個人鍵) を要求する場合
Internal error: Could not write object of type commit
Caused by: Signing error / SSH sign failed
  No private key found for "/var/folders/.../jj-signing-key-..."
```

### 対策

越境作業で signing を含む操作 (`jj git push`, `git commit -S` 等) を行うときは、
**`SSH_AUTH_SOCK` を一時的に対象環境の agent に切り替える** か、`signing.key` を
repo-local で override する:

```bash
# 案 1: SSH_AUTH_SOCK 一時切替 (signing.key は global の値を尊重)
SSH_AUTH_SOCK=~/.ssh/agent-env-Y.sock jj git push

# 案 2: repo-local で signing.key を agent の公開鍵に固定
cd /path/to/env-Y/<repo>
SSH_AUTH_SOCK=~/.ssh/agent-env-Y.sock jj config set --repo signing.key "$(SSH_AUTH_SOCK=~/.ssh/agent-env-Y.sock ssh-add -L | head -1 | awk '{print $1, $2}')"
```

- **デフォルト環境 (個人面) のリポは signing.key を override しない** (global config が正、
  agent も default で正しい鍵を持っているはず)
- **別アカウント鍵で署名すべきリポ** (例: emeradaco のリポは kawaz123 鍵で署名) で
  global signing.key が個人鍵を指している場合、repo-local override が一度必要

## その他注意点

- **Claude Code セッション自体の CLAUDE_CONFIG_DIR は変わらない** (起動時固定)。
  越境作業中も session の rules/settings/memory は元の環境のものを参照する
- **memory は越境しない**: 各環境の `$CLAUDE_CONFIG_DIR/projects/.../memory/` は別物
- **rules は越境する**: 概念 rule (`claude-config-dir-isolation`) は `for-all/rules/` にあり、
  両環境 (personal / emeradaco / ...) の `rules/for-all-from-personal/` に symlink で注入されている

各環境固有の越境手順 (例: emeradaco なら gh トークン / SSH 鍵 / signing.key の
具体的な指定) は当該 overlay の `for-all/rules/` を参照する。

## 関連

- [[claude-config-dir-isolation]] — CLAUDE_CONFIG_DIR 運用と `~/.claude` 汚染対策の概念 (= 本 skill の概念正本)
