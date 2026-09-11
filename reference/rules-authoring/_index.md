# ルール群の編集規約

rule / skill / 参照知識 (reference / memory / privacy) を書く・移す・消すときの正本。まず classification で置き場を決め、書式は index-conventions、reference の中の構成は reference-layout、既存のものを動かすなら migration を読む。

- [classification](classification.md) — 常時ロード / skill / 参照知識の 2 段判定、3 層の書き先、本文の書き方、書いたら確認なしで commit・push まで完結させる。
  発火語: rule を書く, skill を作る, どこに書く, 常時ロードが重い, skill か reference か, memory に書く, 知識を残す
- [reference-layout](reference-layout.md) — トピックでの階層化、分割の粒度、スクリプト・テンプレの同梱、索引で引けない時の grep。
  発火語: reference の構成, トピックを作る, 分割, scripts を同梱, templates, 索引に載せない, 見つからない, rg で探す
- [index-conventions](index-conventions.md) — 索引エントリの書式と発火語、本文と索引の 1:1、private 層の写し、`just lint-rules` の検査項目。
  発火語: _index.md, 索引, 発火語, 索引漏れ, lint-rules, FATAL, dead wikilink, .lint-external-slugs
- [role-main-loading](role-main-loading.md) — 3 段のロードリスト、必読 / 必要時の 2 節構成、必要時から必読への昇格。
  発火語: ロードリスト, role-main, 必読, 必要時, 段 1, 段 2, 昇格, 読んでない
- [migration](migration.md) — rule / skill を reference へ降ろす手順、skill 案内の残し方、配布の差 (symlink / plugin-release)。
  発火語: reference へ移す, skill をやめる, 降ろす, plugin-release, 反映されない, 触ったついで移行
