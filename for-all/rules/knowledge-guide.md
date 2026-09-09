# 参照知識の置き場と書き先

読むだけの知識 (実行資源を伴わない) は 3 層に平置きする。索引は統括が起動時に読み、本文は必要時にその 1 ファイルだけ Read する。

| 層 | パス | 役割 |
|---|---|---|
| reference | `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/` | 公開してよい体系知識 (public git) |
| memory | `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/memory/` | rule にするほど一般化していないが別プロジェクトでも効く横断メモ |
| privacy | `~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/` | 個人情報系 (本人の表記、アカウント名、連絡先。private git) |

索引はそれぞれ `reference/_index.md` / `memory/_index.md` / privacy リポの `INDEX.md` (privacy の索引は `reference/_index.md` の「private 層」節にも写す。索引は public でよく、本文だけ private)。

## 書き先の判定

- そのプロジェクトでしか意味を持たない → そのプロジェクトの auto-memory
- 別プロジェクトでも効くが一般化前 → `memory/`
- 個人情報系 → privacy リポ
- 公開してよい体系知識 → `reference/`
- 全セッションで毎ターン効く行動制約 → rule

昇格させたら下層の元エントリは消す (正本の二重化を避ける)。`memory/` は気軽に書いてよく、rule / reference への昇格・整理は気づいた人がその時にやる。

## memory / reference への書き込みは確認なしで完結させる

どのプロジェクトのセッションからでも、`memory/` `reference/` への追記は**ユーザに確認せず**行う: ファイルを書き、`_index.md` を更新し、その場でパス指定 commit (`jj commit -m "memory: <slug>" memory/<slug>.md memory/_index.md`)、そのまま `(cd <rules リポ> && just push)` まで通してよい (これらのパスは version bump gate の対象外)。「越境なので commit しますか」「push しますか」と聞かない。業務固有名詞・個人情報が混ざる時だけ止まる (書き先が privacy / overlay になるため)。

## 索引と本文の 1:1

本文の追加・削除・改名は、同じ変更で該当 `_index.md` も更新する。本文の書き方 (知識そのものだけ、hard-wrap しない) は [[rule-writing-guidelines]] が正本。
