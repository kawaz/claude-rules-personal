# jj でのコミットの組み替え

split / squash / rebase / duplicate によるツリーの組み替えパターン。リビジョン指定オプションの網羅は reference の `vcs/jj-rebase-options`。

## jj split — 過去コミットも簡単に分割

`x-y-z-@` で y に docs/aaa.md と src/bbb.ts が混在しているとき:

```bash
jj split -r y -m "docs: add aaa" docs/aaa.md
```

→ `x-y1-y2-z-@` (y1 に docs/aaa.md、y2 に src/bbb.ts。y2 の description は元の y のまま)

y2 の description は元の y のまま (例: "add aaa bbb") だが、aaa は y1 に分割済みで y2 は bbb しか含まないので、必要に応じて更新:

```bash
jj describe -r y2 -m "feat: bbb"
```

y2 を y1 の前に移動したければ:

```bash
jj rebase -r y2 --before y1
```

→ `x-y2-y1-z-@`

## jj squash — コミットの合体

split の逆。amend 的なことをしたいときに使う。

```bash
jj squash                  # @ の差分を親 (@-) に吸わせる（amend 相当）
jj squash -r target --onto dest   # target を dest に吸わせる
jj squash -r target --insert-before dest  # dest の前にマージコミットが作られる
jj squash -r target --insert-after dest   # dest の後にマージコミットが作られる
```

マージコミットは `jj new x y z` のように 2 つ以上の親コミットから new することでも作れる。

## コミット整理の基本パターン

### 安全枝を生やして集める

変なコミットが散在していたら:

1. `jj new -r <安全な起点>` で安全な枝を生やす
2. そこに `split` / `rebase` / `duplicate` + `rebase` で必要なものを集める
3. 不要なものは `abandon`

restore や revert でコミットの中身を書き換えるより、コミットごと移動・複製するほうが安全で速い。

### new と duplicate の使い分け

- ターゲットのコミット自体は触らずにその子 (支流) を生やしたい → `jj new`
- ターゲットのコミット自体をいじりたい → `jj duplicate`

### new で支流を生やす

`jj new -r X` は X の子として空コミットを生やす。X 自体には触らない:

```bash
# x-y-z-@ の状態から
jj new -r x               # x の子として空コミットが生える
# → x-y-z-@
#   └-t (empty)

# t に必要なものを rebase/split 等で集めたり並べ直したりしていく
```

### duplicate で安全に試す

直接 split するのが怖ければ、まず duplicate してから複製側で試す。`duplicate` は同じ親を持つ同じ内容の複製を作る:

```bash
# x-y-z-@ の状態から
jj duplicate -r y          # y の複製 yy が作られる
# → x-y-z-@
#   └-yy

jj split -r yy -m "docs: add aaa" docs/aaa.md   # 複製された yy 側で split 作業
# → x-y-z-@
#   └-yy1-yy2

# 良さそうなら yy2 の先に移動
jj new yy2                 # yy2 の先に @ が移動
# → x-y-z-u
#   └-yy1-yy2-@

# 元の枝が不要なら abandon
jj abandon y z u
# → x-yy1-yy2-@
```

元の状態に戻りたくなったら `jj edit u` で即座に戻れる (abandon 前なら)。

### 中間コミットの削除

不要なマージコミットや空コミットは `jj abandon` するだけ。前後は自動でつなぎ直される。git のように歴史を壊す心配がない。

### コミットの並べ替え

```bash
jj rebase -r X --before Y   # X を Y の前に挿入
jj rebase -r X --after Y    # X を Y の後に挿入
jj rebase -r X -d Y         # X を Y の子に移動（子孫なし）
jj rebase -s X -d Y         # X とその子孫ごと移動
```

## immutable コミットの書き換え

trunk() (≒ origin/HEAD) の祖先は immutable としてガードされる。自分の責任で force push も気にしないなら `--ignore-immutable` を付ければ組み替え可能:

```bash
jj rebase -r X --before Y --ignore-immutable
```

## 過去コミットから特定パスを完全除去 (split で隔離 ws に逃がす)

「dist/ や生成物などを過去コミット全てから消したい」ときの jj 流。git なら `git filter-repo --path dist --invert-paths --force` (無ければ `git filter-branch --index-filter 'git rm --cached -rf --ignore-unmatch dist' -- --all`) に相当する操作を、jj では split で各 change から該当ファイルだけ切り出して隔離 workspace に逃がす形で実現できる。

```bash
drop_filesets="dist/**"
drop_ws="drop-$(printf %s "$drop_filesets" | sha256sum | perl -pe's/ .*//')"

# 1. 隔離先となる workspace を root() に作る
jj workspace add ../$drop_ws -r 'root()' -m "不要ファイルの隔離先: $drop_filesets"

# 2. 対象ファイルを含む change を列挙（隔離 ws 自身の祖先は除外＝冪等性）
change_ids=($(jj log -r "files('$drop_filesets') ~ $drop_ws@::" --no-graph -T 'change_id++"\n"'))

# 3. 各 change から対象ファイルだけ切り出して隔離 ws の後ろに挿入
for change_id in "${change_ids[@]}"; do
  jj split -r $change_id "$drop_filesets" \
    -m "drop $drop_filesets FROM $change_id" \
    --insert-after $drop_ws@ \
    --ignore-immutable
done
```

ポイント:

- `--ignore-immutable` で immutable boundary を超えて過去 commit を書き換える
- `--insert-after $drop_ws@` で「対象ファイルだけの change」を全部隔離 ws の子孫に集める
- `jj log` のデフォルトは子孫→祖先の新しい順なので、取得した順に処理していけばループ各時点で「まだ書き換えられていない」change_id を扱える (祖先から先に書き換えると、子孫側の change_id がリスト時点と乖離して破綻する)
- **multi-branch でループ中に conflict が出ても気にせず最後まで回す**: 並列 ws / 並列 branch がある状態 (= main 系の commit が rewrite される時に別 branch の子孫が auto rebase で 3-way merge) で対象ファイルの内容衝突が出ても、conflict markers は対象ファイル内 (= drop 対象) に書き込まれる。後続の loop で当該 change を split すると marker ごと隔離 ws に移動するので、最終的に全 change から対象ファイルが消えて conflict も同時に解消される。「子孫→祖先順」の前提が崩れる multi-branch でも、loop を中断せず全 change_ids 分回し切るのが正解。途中でユーザに見せる log には `(conflict)` 表示が並ぶが、最後まで実行すれば消える
- 検証: `jj log -r "::main & files('$drop_filesets')"` が空なら main 系統から対象ファイルが消えている
- 後始末: `jj workspace forget $drop_ws && rm -rf ../$drop_ws && jj abandon -r 'descendants(<隔離先のcid>)' --include-roots`

git との違い:

- git の filter-repo / filter-branch は履歴の全 commit_hash が変わり、tag/branch の追従や ref 更新が必要
- jj は同様に書き換えで commit_id (と change_id) が振り直されるが、`jj log` の子孫→祖先順とループの組み合わせで、列挙時点の change_id をそのまま使い切れる (rebase は自動で行われる)
- 隔離 ws を残しておけば「やっぱり戻したい」が `jj op restore` や duplicate で簡単
- リモート push 時は履歴書き換えなので force 系のオプションが必要なのは git と同じ

## 外から作業中の ws に事故なく change を送り込む (隔離 ws + insert-before)

別 workspace (例: `main`) で誰か (kawaz 本人 or 別 agent) が作業中に、外側から無関係の change (例: docs 追記、フィードバック起票) を入れたいとき、対象 ws に直接 Write するのは危険。jj は auto-snapshot するので一見書けたように見えるが、所有者が `jj edit` 等で @ を移動した瞬間に書いた内容は @ から外れて「消えた」ように見える (実体は op log に残るが復旧手間)。

安全な手順:

```bash
# 1. 対象 ws の @ をベースに隔離 ws を立てる（兄弟関係になる）
(cd $REPO/main && jj workspace add ../wip-<topic>)
# 隔離 ws の @ は対象 ws の親（@-）の子として作られる（main@ と兄弟の空 change）

# 2. 隔離 ws 側で Write/Edit（対象 ws には一切触らない）
# (Write/Edit tool で $REPO/wip-<topic>/... を編集)

# 3. 編集を確定 + 空 @ を作る（commit 一発、describe + new ではなく）
(cd $REPO/wip-<topic> && jj commit -m "docs(...): ...")
# これで @- = 確定した私の change、@ = 空 change という形になる

# 4. 確定した change（= @-）を main bookmark の直後に挿入
MY_CHANGE=$(cd $REPO/wip-<topic> && jj log -r '@-' --no-graph -T 'change_id.short() ++ "\n"' | head -1)
(cd $REPO/wip-<topic> && jj rebase -r "$MY_CHANGE" --insert-after main)
# 対象 ws の @ (= main bookmark の元の子) は自動 rebase で「私の change を親に持つ」状態になる
# 結果: ... → 元 main bookmark の commit → 私の change → 対象 ws の @（変わらず、ただし親が変わる）
# main bookmark 自体は動かない（= kawaz が push で進める責任）

# Why bookmark 名 (`main`)、not `main@` or @ 値の取得:
# `main@` (= 対象 ws の @) は kawaz が一時的に `jj edit` で他 change に移動していると別 commit を指す。
# bookmark 名なら delivery point を指して安定するので `--insert-after main` の方が安全。
# `--insert-before` を使う場合も同様に bookmark 名で指定 (= `--insert-before main` だと main 自体が
# X の child に rebase = force push 相当になるので、通常は `--insert-after main` を選ぶ)。

# 5. 隔離 ws を片付け（commit 後の空 @ も一緒に消える）
(cd $REPO/main && jj workspace forget wip-<topic>)
rm -rf "$REPO/wip-<topic>"
```

ポイント:

- 対象 ws の @ が「空 change (uncommitted 状態の入れ物)」のままなら、所有者の working copy は丸ごと安全 (私の change は @ の親に乗るだけ)
- 対象 ws に未 commit の編集があっても、jj が自動 rebase してくれるので所有者の作業内容は失われない (commit ID は振り直されるが)
- 隔離 ws を別ディレクトリに作る代わりに `jj new -r <親>` で支流を生やして書く方法もあるが、Write tool 等の外側ツールが「現在の cwd の working copy」を見るので、別 ws の方が衝突が起きにくい
- 自分のリポでも「複数 agent が同時に同じ ws で書くと事故」防止策として常用してよい

回避できる事故:

- 所有者が `jj edit` / `jj new` で @ を移動した瞬間、外から書いた内容が @ から消える
- 所有者の working copy 編集中ファイルを外側の Write が上書き
- 隔離 ws なら所有者がいくら @ を動かしても私の change は独立して残る
