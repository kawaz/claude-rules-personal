# rule / skill を参照知識へ降ろす

分類 (classification) で「常時ロードでない」「ユーザ起動でない」と判定したものを `reference/` へ移す手順。

## rule → reference

1. 降ろす範囲を決める。**行動制約 (禁則・自警・評価軸) は rule に残し**、手順・表・テンプレ・コマンド列を降ろす
2. `reference/<topic>/` を作り、使う場面ごとに分割して本文を書く (分割の粒度は reference-layout)
3. rule を「禁則」+「**その作業をする時は reference の `<topic>` を読む**」の 1 行に縮める。rule 側に残す禁則は、参照知識を読まずに踏むと事故るものだけ
4. 縮めた rule を他の rule が `[[…]]` で参照していないか確認する (節ごと消すと参照が宙に浮く)
5. `reference/<topic>/_index.md` とトップの `reference/_index.md` にエントリを足す。rule を消した場合は `for-*/rules/_index.md` からも消す (index-conventions)

## skill → reference

1. SKILL.md の本文を `reference/<topic>/` へ分割して移す。**frontmatter は外す** (name / description / allowed-tools は skill の起動用メタなので参照知識には要らない)
2. `scripts/` 等の付属ファイルはディレクトリごと同じトピックへ移し、索引には載せない (reference-layout)
3. 移した skill の SKILL.md は、frontmatter を残したまま本文を案内だけにする:

   ```markdown
   この skill は reference の `<topic>` へ移動した。
   `<絶対パス>/reference/<topic>/_index.md` を Read すること。
   ```

   案内を残すのは 1 版だけ。**次の release で skill ディレクトリごと削除する** (install 済みのスナップショットや履歴から旧名で起動された時に、行き先が分かる猶予を 1 版だけ置く)
4. skill 名で参照している箇所を洗って書き換える:

   ```bash
   rg -n '<name>' <リポ>/for-*/rules <リポ>/skills <リポ>/reference
   ```

   「`<name>` skill」→「reference の `<topic>`」。**`[[<skill 名>]]` の wikilink は必ず名前参照に直す** (skill ディレクトリを消した時点で dead wikilink になり lint が FATAL になる)
5. 他リポからの参照は書き換えの対象と影響範囲が違うので、勝手に直さず所有者に報告する

## 配布の差 (どこまでやれば効くか)

| 配布物 | 経路 | 反映 |
|---|---|---|
| `for-*/rules/` | setup.sh の symlink | 実体を直接読むので保存した時点で効く |
| `reference/` `memory/` | なし (絶対パスで Read) | 同上 |
| `skills/` `.claude-plugin/` | marketplace 経由の plugin | `just plugin-release` (bump → commit → push → update) が要る |

skill を編集しただけでは install 済みのスナップショットが古いままで、どこにも効かない (version が同じだと `plugin update` も「最新です」と言って何もしない)。plugin 側の反映には Claude Code の restart か `/reload-plugins` も要る。

**skill を参照知識へ移す変更は、案内だけの SKILL.md も plugin 配布物**なので release を通す。rule と reference だけを触った変更に release は要らない。

## 既存リポの移行

一括では動かさず、**触ったついでに**その 1 本だけ移す。移していないものが混在している状態は正常で、混在を理由に一括移行を始めない。
