# agy の agent 定義・subagent・workflow

agy は会話の中で、自分の仕事を別の agent に分けられる。その agent を自分で定義することもできる。

確かめた版: 1.5.13〜1.5.15 (macOS、2026-11-21〜25)。「ドキュメント」は agy 同梱の `antigravity-guide` skill が引く公式の docs (antigravity.google/docs の `subagents`、`customization-discovery`、`dynamic-workflows`、`cli/headless`)。

## agent を定義する

置き場 (ドキュメント):

| 範囲 | パス |
|---|---|
| プロジェクト | `.agents/agents/<名前>.md` か `.agents/agents/<名前>/agent.md`。作業ディレクトリ (と `--add-dir`) からリポジトリの根まで遡って探す |
| ユーザ | `~/.gemini/config/agents/<名前>.md` か `~/.gemini/config/agents/<名前>/agent.md` |
| plugin | `<plugin の根>/agents/<名前>.md` |

中身は YAML の frontmatter と、システムプロンプトになる本文。

```markdown
---
name: sheller
description: Runs shell commands on request and reports the raw output.
tools:
  - run_command
  - view_file
  - list_dir
commandExecutionPolicy: auto
---

You run the shell commands the user asks for and report their raw output.
```

- frontmatter の欄 (ドキュメント): `name`・`description` (必須)、`tools`、`mainAgent` (`--agent` で選べるか。既定 true)、`subagent` (他の agent から呼べるか。既定 true)、`model` (`inherit` / `flash_lite` / `flash` / `pro`)、`commandExecutionPolicy` (`off` / `auto` / `eager` / `sandbox`)、`mcpServers`、`skills`、`plugins`、`inheritMcp`、`inheritCustomizations`
- `tools` を書かないと、使える道具はごく一部になる (`send_message, read_file, search_web, schedule, generate_image, manage_task`)。全許可で起動してもシェルを使えない。シェルやファイルの編集をさせるなら `tools` に `run_command` 等を並べる
- `tools` に `run_command` を並べても、権限は別に要る。全許可なしでは `uname -s` も拒否された
- 起動は `agy -p '…' --agent <名前>`。無い名前は `unknown agent` で終わる
- `agy agents` の一覧には、作業ディレクトリに置いた定義が出なかった (`--agent` で指定すると使えた)

## 組み込みの subagent

`research` (読むだけの調査)、`browser` (ブラウザ操作)、`self` (自分の写し) がある。会話の中で `invoke_subagent` の道具から呼ぶ物で、`--agent research` のように起動時には選べない (`unknown agent`)。

- 全許可で「research subagent に作業ディレクトリの一覧を作らせて」と頼むと、subagent が動き、その結果まで返った (約 40 秒)
- 全許可なしでは、subagent は起動するが、`-p` は subagent の結果を待たずに終わった (「終わったら知らせが来る」と返すだけ)

## workflow (`run_workflow`)

Python のスクリプトで、多数の agent を並列や段階に分けて走らせ、結果を集める道具 (ドキュメントの Dynamic Workflows)。スクリプトの中の `agent(...)` は、それぞれ独立した会話として走り、JSON Schema に沿った結果をスクリプトに返す。`type_name` に組み込みの agent 名か、自分で定義した agent の名前を渡せる。

- 全許可で「alpha と beta を返す agent を 2 本並列に」と頼むと、`['alpha', 'beta']` を集めて返した (Gemini で約 25 秒、Claude Sonnet で約 9 秒)
- 全許可なしでは `RunWorkflow` が拒否され、会話がそこで打ち切られる (応答は前置きの 1 行だけ。ログに `CancelCascadeInvocation`)

## その他の口

- `agy acp`: Agent Client Protocol (エディタがエージェントを操作するための JSON-RPC) のサーバ。標準入力に `initialize` を送ると応答し、会話の保存・再開・一覧などの機能とログイン方法 4 種を返した。操作する側は自前で書く必要がある
- `--remote-agent`: 遠隔の環境で会話を走らせる。`-p` とは併用できない (`--remote-agent does not support --print yet`)
- `-i` / `--prompt-interactive`、`--remote-control`: 対話の画面を開く物。非対話では使わない
