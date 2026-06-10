# 過去仕様への言及は code / docs に残さない

最新を見る読者にとって「過去にあったが今はない」「以前は X だったが今は Y」は **無意味なノイズ**。判断 history は DR / commit log / journal に残ってれば十分。

## 削除対象 (= 書かない / 見つけたら消す)

- **跡地コメント**: 削除した関数 / フィールドの場所に「ここに X があった」「X is removed」
- **history narrative**: 「以前は set-subtraction だったが backend pathspec forward に変更」「phase 1 では Y、phase 2 で Z」
- **バージョン番号付き注釈**: 「(v0.33.4 で確認)」「(v0.29.0 で削除)」 — 最新版なら不要、削除した機能なら言及自体不要
- **過去名の旧 alias 言及**: 「(旧名 `oldFunc` 由来)」 — rename したなら新名だけ書く
- **「dead code として残置」** — dead なら delete、残す理由が無い

## 残してよい (= 判断の必要性が現在も生きている場合)

- **意図的な誤判断 record** (= 「片面確認」回避目的、DR-0020 PR-2.1/2.2 のような明示意図): grep 可能な history として正規に残す
- **Migration hint**: 削除した機能を user が探すかもしれない場面で「v0.X で `vcs:latest-tag()` は廃止、代替は ...」のような移行誘導 (= help / error message に限り、code comment ではない)
- **DR Status: Superseded by DR-NNNN** 注記: DR 自体は判断 record、supersede 関係は構造的に必要

## 適用フロー

- 書く時: 「previously」「once」「以前」「旧」「v0.X で」「phase 1 では」が出たら削れないか確認
- 既存 file 修正時: 見つけたら ついで削除

## Why

AI (= 自分) は「変更経緯」を書きたがる癖がある。history が必要な読者は git log / DR を見るので、code/docs は current 専用にする。
