# Claude harness template 変数の展開境界 (= 推移しない)

`${CLAUDE_SKILL_DIR}` / `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PROJECT_DIR}` 等の Claude
harness template 変数は **「harness が直接ロードするファイル」でのみ展開**される。
そこから「参照される側」「サブエージェント側」「bash subprocess」には **推移しない**。

## 展開される側 / されない側

| 場所 | 展開されるか | 例 |
|------|------------|-----|
| `SKILL.md` 本文 | ✓ | Skill 起動時、本文が context に流入する直前に template 展開される |
| `hooks.json` の `command` 文字列 | ✓ | hook 起動時に展開、shell exec される |
| `.claude-plugin/*.json` / `marketplace.json` 内のパス | (該当箇所のみ) | plugin 規約による |
| `instruction.md` / `reference/*.md` 等 supporting files | **✗** | SKILL.md が `${CLAUDE_SKILL_DIR}/instruction.md` を指しても、その file の中身は raw |
| **サブエージェントの prompt** | **✗** | Agent tool に渡す `prompt` 文字列は親が組み立てる時点で展開済の値を埋める必要あり |
| Bash で起動した script の env | **✗** (実機検証済) | `echo $CLAUDE_PLUGIN_ROOT` は空。SKILL.md 本文の `${CLAUDE_PLUGIN_ROOT}/foo` は展開済で流入するが、bash 自身は env を持たない |
| MCP サーバ / 外部プロセスの env | ✗ | 親プロセスから明示伝達しない限り見えない |

## How to apply

### 1. supporting files (instruction.md 等) でパス参照したい場合

SKILL.md 内で `${CLAUDE_SKILL_DIR}` を使い、supporting file に **渡す側** が絶対パスを
組み立てる:

```markdown
<!-- SKILL.md -->
サブエージェントへの委譲 prompt:
> CLAUDE_SKILL_DIR=${CLAUDE_SKILL_DIR}
> 上記 SKILL_DIR 配下の `instruction.md` に従って処理してください。
```

サブエージェントは prompt 内に絶対パスを受け取れるので、instruction.md を Read できる。
instruction.md 自体に `${CLAUDE_SKILL_DIR}` と書くのは無意味 (展開されない literal)。

### 2. Bash script 内でパス参照したい場合

SKILL.md 本文の Bash code block で `${CLAUDE_SKILL_DIR}` を書けば、code block も template
展開対象 → bash には絶対パスが渡る:

```bash
# SKILL.md 内に書く (= 展開済で bash に渡る)
bash "${CLAUDE_SKILL_DIR}/scripts/run.sh" "$@"
```

ただし supporting script (`run.sh`) 内で `$CLAUDE_SKILL_DIR` を読もうとしても空。
script 側に渡すなら引数 / env として明示的に export して exec する:

```bash
SKILL_DIR="${CLAUDE_SKILL_DIR}" bash "${CLAUDE_SKILL_DIR}/scripts/run.sh"
```

### 3. サブエージェント prompt で指示する場合

Agent tool への prompt 文字列は親 (= メイン context) で組み立てるので、`${CLAUDE_SKILL_DIR}`
を直接埋め込めば展開済の値が乗る:

```text
subagent_type: general-purpose
prompt: |
  CLAUDE_SKILL_DIR=${CLAUDE_SKILL_DIR}
  上記ディレクトリ配下の instruction.md に従って ... を実施してください。
  完了したら OUTPUT 形式で結果のみ返してください。
```

サブエージェントは独立 context だが、prompt に絶対パスが書かれていれば Read できる。

## Why

template 展開は **harness の boundary でだけ起きる single-pass** な機構。
推移するように設計されていない (= shell の env と同じく明示伝達が必要)。
この境界を意識しないと:

- supporting file 内に書いた `${CLAUDE_SKILL_DIR}` が literal で残り、Read が ENOENT
- サブエージェント prompt 内で同様にハマる
- Bash script の hardcoded env 依存で別マシン / 別 user で動かない

## 参考: 検証履歴

- 2026-06-10: `kawaz/claude-rules-personal` の `personal-gh-image-attach` skill で
  `${CLAUDE_SKILL_DIR}` を SKILL.md 本文に記載 → Skill 起動時に `/Users/kawaz/.claude-personal/skills/personal-gh-image-attach`
  に展開されることを確認 (symlink パス、resolve 後の実体パスではない)
- 同 skill の冒頭プロローグとして `Base directory for this skill: <path>` が自動付与される
- `${CLAUDE_PLUGIN_ROOT}` の bash env 内では空 = 実機検証済 (kawaz/claude-plugin-reference)

## 関連

- `claude-plugin-reference` skill — template 変数の一覧と各経路の有効性 (実機検証込)
- `claude-config-dir-isolation` — `CLAUDE_CONFIG_DIR` も harness boundary で読まれる
