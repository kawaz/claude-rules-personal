# 参照知識の置き場と書き先

読むだけの知識 (実行資源を伴わない) は 3 層に平置きする。索引は統括が起動時に読み、本文は必要時にその 1 ファイルだけ Read する。

| 層 | パス | 役割 |
|---|---|---|
| reference | `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/` | 公開してよい体系知識 (public git) |
| memory | `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/memory/` | rule にするほど一般化していないが別プロジェクトでも効く横断メモ |
| privacy | `~/.local/share/repos/github.com/kawaz/privacy-personal/main/` (`reference/` + `memory/`、上と同構造) | 個人情報系 (本人の表記、アカウント名、連絡先。private git)。業務面は各 overlay の rule が案内する privacy-<面> リポ |

索引はどの層・どのリポでも `reference/_index.md` / `memory/_index.md`。

**どの層に書くか・どう分割するか・索引と commit をどうするかは reference の `rules-authoring` が正本**。知識を書き足す・移す時はそれを読む。
