---
name: agent-browser-session-isolation
description: `agent-browser` CLI (= AI agent 向け headless ブラウザ自動化ツール) を使う場面で、複数 Claude エージェントが同一ホストで default session を共有する事故 (= 操作競合 / snapshot ref 破棄 / Cookie リセット) を防ぐための session 分離規約。`agent-browser open/snapshot/click/fill/screenshot/hover/type` 等のサブコマンドを起動する際、または playwright-cli の session 命名規約を揃える参照として使う。`--session-name` の必須化と命名規則 (`<タスク種別>-<issue/PR番号>-<担当>` 形式)、`AB_SESSION` シェル変数の慣習を提供する。agent-browser CLI を使わない作業中は load 不要。
---

# agent-browser セッション分離 (必須)

複数の Claude エージェントが同時に同一ホストで `agent-browser` を使う可能性があるため、
**必ず `--session-name <一意な名前>` を指定する**こと。default session を共有すると以下の問題が起きる:

- 他エージェントの操作で画面が別ページに遷移していて自分の `click @e3` が別要素に当たる / timeout する
- snapshot で取得した ref が、他エージェントの操作で破棄されている
- ログイン Cookie が他エージェントによってリセットされる

## 命名規則

`<タスク種別>-<issue/PR番号>-<担当>` 形式を推奨:

- 例: `fix-2231-kawazu`, `survey-2240-kawazu`, `review-2234-kawazu`

ログイン → 検証 → 完了 の一連のフローで**同じ session-name を使い続ける**。
明示的に `close` しない (次回同じ session-name で復帰できる)。

## 操作例

```bash
AB_SESSION=fix-XXXX-kawazu  # タスクごとに一意な名前を割り当てる (AB = agent-browser)

# open / snapshot / fill / click すべてに --session-name を付与
agent-browser --session-name "$AB_SESSION" open <url>
agent-browser --session-name "$AB_SESSION" snapshot
agent-browser --session-name "$AB_SESSION" fill @e2 <value>
agent-browser --session-name "$AB_SESSION" click @e5
```

シェル組み込み変数 (`$USER`, `$HOME` 等) や一般的な名前 (`$SESSION` 等) は他コマンド/ライブラリと
コンフリクトしうるため、`AB_` プレフィックスで分離する。
