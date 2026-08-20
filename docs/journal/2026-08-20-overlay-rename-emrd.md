# overlay 名リネーム (業務面 overlay を emrd へ) で判明したこと

業務先の組織名はサニタイズ対象なのに、ルール overlay のリポ名がその組織名を冠して
いたため「サニタイズ対象語を参照するたび書かねばならない」矛盾が生じていた。
リポ名・overlay 名を `emrd` に寄せて解消した作業の記録。personal 面 (本リポ) と
業務面 overlay リポの 2 セッションで分担し、ccmsg で同期しながら進めた。

## 一律置換してはいけない — 2 種類の同名文字列

同じ組織名文字列でも、置換対象と保存対象が混在する。

| 分類 | 例 | 扱い |
|---|---|---|
| kawaz 自身のルール基盤の命名 | リポ名 / CLAUDE_CONFIG_DIR / overlay 名 / rule ファイル名とその wikilink | 置換する |
| 組織名そのもの | `identifiers-*.md` の単語リスト本体、実在の GitHub 組織・リポ URL | **残す** |

単語リスト本体を潰すと**サニタイズ規約そのものが機能しなくなる**ので、取りこぼしより
誤置換のほうが高コスト。迷ったら残す側に倒す。

## 落とし穴

### 互換 symlink があると setup.sh の prune が効かない

`setup.sh` の `prune_dangling` は **リンク切れ (dangling) だけ**を消す。旧名の互換
symlink (`<old-repo> -> <new-repo>`) が生きていると旧名リンクは解決できてしまうため
prune されず、新旧が並存して**同じルールが二重ロード**される。

正しい順序:

1. 各環境で `setup.sh` を実行 (新名リンクを生成)
2. 旧名リンクを明示的に `rm`
3. **最後に**互換 symlink を削除

先に互換 symlink を消すと、まだ setup.sh を回せていない環境で overlay のルールが
丸ごと消える。

### ssh agent socket の互換 symlink には期限がある

`~/.ssh/config` の `IdentityAgent` が旧名 sock を指したままだと、互換 symlink の
削除時点で越境リポの ssh 認証が壊れる。`ssh -G git@github.com` を**対象リポの cwd で**
実行すると解決先が確認できる (`Match exec` が cwd を見るため、cwd を変えずに確認すると
別の面の結果が返る)。

### plugin と symlink では反映タイミングが違う

plugin (marketplace 経由) は **push しないとローカルに反映されない**。手置きの agent
定義をリポの `agents/` に移した時点で、push までその agent は使えなくなる。symlink
方式にはない性質なので、移行時の空白を織り込む必要がある。

## 派生して見つかった構造的な穴

### plugins.json に面の分離が無かった

`setup.sh` は全リポの `for-all/plugins.json` を無条件にマージしていた。rules 層は
for-me / for-all / for-others で面を分けているのに、plugins だけ分離手段が無い非対称。
plugin の skill / agent description は**全セッションの context に常時載る**ので、
業務面 plugin を宣言すると個人面に語彙が漏れる。rules と同じ層意味論を与えて解決
(`for-me/plugins.json` = self 環境のみ)。

### 常時ロードルール同士の矛盾 (片側更新)

越境コマンドの形について、`claude-config-dir-isolation` が推奨していた形を
`tooling-tips` が実測に基づく Bad 例として否定していた。前者が後者を「実測参照」として
引用しているのに、後者の改訂に追従できていなかった。**実測を持つ側を正**とし、
もう一方は形の提示と参照に留めた。

## サニタイズ規約の適用範囲 (作業中に誤解していた点)

業務面 overlay の `for-all/rules/` にあるファイルは personal 面にも配布されるため、
「個人面の context に組織名が載り続けるのは今回の目的に反するのでは」と一度提起したが、
**規約の適用対象は public な成果物**であり、private リポの内容や local の config dir に
配られるルールは対象外 (kawaz 明示)。

今回リポ名のリネームが必要だったのは、**public な central リポ (README /
repos_mapping.json / for-all rules) がその名前を参照せざるを得なかった**から。
overlay リポ内部に組織名が残ること自体は問題にならない。
