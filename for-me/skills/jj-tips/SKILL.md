---
name: jj-tips
description: jj 実践 Tips。jj コマンド (= `jj commit` / `jj split` / `jj rebase` / `jj edit` / `jj new` / `jj squash` / `jj duplicate` / `jj abandon` / `jj op restore` / `jj bookmark` 等) を使ったコミット操作・組み替え・bookmark 管理・トラブル対処のパターン集。「git 脳を捨てる」原則、覚えるべき 5 コマンド、過去コミット分割 (split)、安全枝を生やして集める、過去コミットから特定パス除去、`jj commit` と `jj split` の使い分け、外から作業中 ws に事故なく change を送り込む手順、bookmark 移動と push のハマりどころ、リモートブックマーク削除、fork で upstream に追従、AI がハマりやすいアンチパターン (`jj describe` だけで終わる commit したつもり事故 等)。jj リポでコミット組み替え・分割・bookmark 操作・op restore による復旧などの実践的判断が必要なときに使う。
---

# jj 実践 Tips（AI 向け）

jj-workflow skill は手順書、jj プラグインはリファレンス。このファイルは実践で得た「こうすると失敗しない」パターン集。

## 原則: git 脳を捨てる

jj で git のやり方（restore, revert, reset）を持ち込むとだいたい破綻する。jj はコミットの並べ替え・組み替えが圧倒的に簡単なので、「元に戻す」のではなく「正しい形に組み替える」。

## 覚えるべき5コマンド

副作用のない参照系（st/show/diff/log）は除いて、コミット操作はこの5つでほぼ全部できる:

- **`jj commit -m "msg"`** — @ を msg で確定し、子に空 @ を作って前進する。日常の「commit したい」はこれ一発で完了 (= `jj describe + jj new` の合体、公式 help 明記)。git の `git commit -m` と同じ感覚で使える
- **`jj new`** — 名無しの編集可能な空コミットを生やす。jj では add や commit は不要（ワークスペースの変更は全て自動コミット）。`jj new` で空コミットに移動すれば、さっきまでのコミットとワークスペースが切り離されてカジュアルに保護される。`commit` を使わず手動で「描いて→新空 change へ」したい時や、特定 revision の子として空 change を生やしたい時に使う
- **`jj rebase`** — コミットを移動・挿入する
- **`jj split`** — コミットを分割する（commit との差は [[#jj-commit-と-jj-split-の使い分け]] 節参照）
- **`jj edit`** — カレントワークスペースを別コミットに切り替える（git switch に近い）

なお `jj describe -m "msg"` 単体は **過去 change の description を後から書き直す時 (`-r <change>`) にだけ使う**。@ に describe しても空 @ は進まないので「commit したつもり」事故になる ([[#jj-describe-だけ実行して終わるcommit-したつもり事故]] 参照)。

## jj edit — 気兼ねなくコミット間を行き来

`jj edit X` でワークスペースの中身が X の状態に完全に切り替わる。

- 編集中のファイルは？→ jj はあらゆる jj コマンド実行時（`jj st` や `jj --help` すら）にワークスペースの変更を自動 snapshot する。`jj edit` 等でワークスペース切り替えが必要な場面でも同様に保護される
- git の stash のようなコンフリクトも起きない。元のコミットに `jj edit` すればすぐ元の状態に戻れる
- 複数コミット間を気兼ねなく行き来できるのが jj の強み
- デフォルトでは 1MB 以上のファイルは自動 snapshot 対象外だが、config で変更可能。対象外ファイルがあれば jj が Warning/Hint で教えてくれるので、最初から特別気にする必要はない

## jj split — 過去コミットも簡単に分割

`x-y-z-@` で y に docs/aaa.md と src/bbb.ts が混在しているとき:

```bash
jj split -r y -m "docs: add aaa" docs/aaa.md
```

→ `x-y1-y2-z-@`（y1 に docs/aaa.md、y2 に src/bbb.ts。y2 の description は元の y のまま）

y2 の description は元の y のまま（例: "add aaa bbb"）だが、aaa は y1 に分割済みで y2 は bbb しか含まないので、必要に応じて更新:
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

マージコミットは `jj new x y z` のように2つ以上の親コミットから new することでも作れる。

## コミット整理の基本パターン

### 安全枝を生やして集める

変なコミットが散在していたら:

1. `jj new -r <安全な起点>` で安全な枝を生やす
2. そこに `split` / `rebase` / `duplicate` + `rebase` で必要なものを集める
3. 不要なものは `abandon`

restore や revert でコミットの中身を書き換えるより、コミットごと移動・複製するほうが安全で速い。

### new と duplicate の使い分け

- ターゲットのコミット自体は触らずにその子（支流）を生やしたい → `jj new`
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

元の状態に戻りたくなったら `jj edit u` で即座に戻れる（abandon 前なら）。

### 中間コミットの削除

不要なマージコミットや空コミットは `jj abandon` するだけ。前後は自動でつなぎ直される。git のように歴史を壊す心配がない。

### 過去コミットから特定パスを完全除去（split で隔離 ws に逃がす）

「dist/ や生成物などを過去コミット全てから消したい」ときの jj 流。git なら `git filter-repo --path dist --invert-paths --force`（無ければ `git filter-branch --index-filter 'git rm --cached -rf --ignore-unmatch dist' -- --all`）に相当する操作を、jj では split で各 change から該当ファイルだけ切り出して隔離 workspace に逃がす形で実現できる。

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
- `jj log` のデフォルトは子孫→祖先の新しい順なので、取得した順に処理していけばループ各時点で「まだ書き換えられていない」change_id を扱える（祖先から先に書き換えると、子孫側の change_id がリスト時点と乖離して破綻する）
- **multi-branch でループ中に conflict が出ても気にせず最後まで回す**: 並列 ws / 並列 branch がある状態 (= main 系の commit が rewrite される時に別 branch の子孫が auto rebase で 3-way merge) で対象ファイルの内容衝突が出ても、conflict markers は対象ファイル内 (= drop 対象) に書き込まれる。後続の loop で当該 change を split すると marker ごと隔離 ws に移動するので、最終的に全 change から対象ファイルが消えて conflict も同時に解消される。memory の「子孫→祖先順」前提が崩れる multi-branch でも、loop を中断せず全 change_ids 分回し切るのが正解。途中でユーザに見せる log には `(conflict)` 表示が並ぶが、最後まで実行すれば消える
- 検証: `jj log -r "::main & files('$drop_filesets')"` が空なら main 系統から対象ファイルが消えている
- 後始末: `jj workspace forget $drop_ws && rm -rf ../$drop_ws && jj abandon -r 'descendants(<隔離先のcid>)' --include-roots`

git との違い:
- git の filter-repo / filter-branch は履歴の全 commit_hash が変わり、tag/branch の追従や ref 更新が必要
- jj は同様に書き換えで commit_id（と change_id）が振り直されるが、`jj log` の子孫→祖先順とループの組み合わせで、列挙時点の change_id をそのまま使い切れる（rebaseは自動で行われる）
- 隔離 ws を残しておけば「やっぱり戻したい」が `jj op restore` や duplicate で簡単
- リモート push 時は履歴書き換えなので force 系のオプションが必要なのは git と同じ

### コミットの並べ替え

```bash
jj rebase -r X --before Y   # X を Y の前に挿入
jj rebase -r X --after Y    # X を Y の後に挿入
jj rebase -r X -d Y         # X を Y の子に移動（子孫なし）
jj rebase -s X -d Y         # X とその子孫ごと移動
```

### `jj commit` と `jj split` の使い分け

シンプルな用途では両者の動作はほぼ同じだが、`commit --help` に明示された 4 つの差がある:

1. **interactive デフォルト**: commit=no (全選択) / split=yes (diff editor)
2. **`-r` の有無**: commit は @ 専用 / split は任意 revision に効く (= 過去 change の分割可)
3. **bookmark の前進**: split (without `-o`/`-A`/`-B`) は @ (= remaining 側) に bookmark を前進させる / commit は前進させない
4. **`-o`/`-A`/`-B` 配置オプション**: split のみ (selected を別位置に挿入できる)

公式 help 引用:

> When called without path arguments or `--interactive`, `jj commit` is equivalent to `jj describe` followed by `jj new`.

= `jj commit -m "msg"` は `jj describe + jj new` の合体。基本フローはこっちで一発。

実用上の選び方:

| やりたいこと | 選ぶコマンド |
|---|---|
| @ を全部確定して空 @ で次へ (= git commit -m 感覚) | `jj commit -m "msg"` |
| @ の中身を path 指定で部分 commit | `jj commit -m "msg" <paths>` |
| bookmark を末端に追随させながら過去を切り分け | `jj split -m "msg" <paths>` |
| 過去 change を後から分割 (`-r <change>`) | `jj split` 一択 |
| selected を別位置に挿入 (`-o`/`-A`/`-B`) | `jj split` 一択 |

シンプルな部分 commit は commit、bookmark を進めたい / 位置を選びたい / 過去を分割したい時だけ split、というのが棲み分けの目安。

### 外から作業中の ws に事故なく change を送り込む（隔離 ws + insert-before）

別 workspace（例: `main`）で誰か（kawaz 本人 or 別 agent）が作業中に、外側から無関係の change（例: docs 追記、フィードバック起票）を入れたいとき、対象 ws に直接 Write するのは危険。jj は auto-snapshot するので一見書けたように見えるが、所有者が `jj edit` 等で @ を移動した瞬間に書いた内容は @ から外れて「消えた」ように見える（実体は op log に残るが復旧手間）。

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

# 4. 確定した change（= @-）を対象 ws の @ の前に挿入
MY_CHANGE=$(cd $REPO/wip-<topic> && jj log -r '@-' --no-graph -T 'change_id.short() ++ "\n"' | head -1)
MAIN_CHANGE=$(cd $REPO/main && jj log -r '@' --no-graph -T 'change_id.short() ++ "\n"' | head -1)
(cd $REPO/wip-<topic> && jj rebase -r "$MY_CHANGE" --insert-before "$MAIN_CHANGE")
# 対象 ws の @ は自動 rebase で「私の change を親に持つ」状態になる
# 結果: ... → 対象 ws の元 @- → 私の change → 対象 ws の @（変わらず）

# 5. 隔離 ws を片付け（commit 後の空 @ も一緒に消える）
(cd $REPO/main && jj workspace forget wip-<topic>)
rm -rf "$REPO/wip-<topic>"
```

ポイント:

- 対象 ws の @ が「空 change（uncommitted 状態の入れ物）」のままなら、所有者の working copy は丸ごと安全（私の change は @ の親に乗るだけ）
- 対象 ws に未 commit の編集があっても、jj が自動 rebase してくれるので所有者の作業内容は失われない（commit ID は振り直されるが）
- 隔離 ws を別ディレクトリに作る代わりに `jj new -r <親>` で支流を生やして書く方法もあるが、Write tool 等の外側ツールが「現在の cwd の working copy」を見るので、別 ws の方が衝突が起きにくい
- 自分のリポでも「複数 agent が同時に同じ ws で書くと事故」防止策として常用してよい

回避できる事故:

- 所有者が `jj edit` / `jj new` で @ を移動した瞬間、外から書いた内容が @ から消える
- 所有者の working copy 編集中ファイルを外側の Write が上書き
- 隔離 ws なら所有者がいくら @ を動かしても私の change は独立して残る

## bookmark は保険

- bookmark さえ付いていれば、そのコミットは失われない
- 無理に main にマージする必要はない。独立ブランチで育てて、必要なときに合流すればいい
- `jj abandon` しても bookmark 付きコミットは visible のまま

## immutable コミットの書き換え

trunk() (≒ origin/HEAD) の祖先は immutable としてガードされる。自分の責任で force push も気にしないなら `--ignore-immutable` を付ければ組み替え可能:

```bash
jj rebase -r X --before Y --ignore-immutable
```

## 最終手段: jj op restore

ツリーもワークスペースもぐちゃぐちゃになったら `jj op log -s` で安全な時点を見つけて `jj op restore <op>` で一発復元。これが jj の最強の安全ネット。

```bash
jj op log -s                  # 操作履歴を確認（-s でコンパクト表示）
jj op restore <きれいだった時点>  # 完全復元
```

`-s` なしだと実行コマンドやスナップショットのファイル名が表示されないので全然わからない。基本は `-s` 付きが分かりやすい。

## bookmark 移動と push のハマりどころ

### `--allow-backwards` を安易に使わない

`jj bookmark set main` が `Refusing to move bookmark backwards or sideways` で拒否されたとき、`--allow-backwards` で無理に動かすと **別ブランチのマージを失う**。まず `jj log` で main と @ の祖先関係を確認する。

### main が自分の祖先でない場合（マージが必要）

review@ 等から main にマージされた変更がある場合、自分の @ は main の子孫ではない。このときは:

```bash
jj new @ main              # @ と main をマージした新コミットを作る
jj bookmark set main -r @  # main をマージコミットに移動
jj git push
```

### @git と main がズレている場合

`jj bookmark list` で `@git (behind by ...)` と表示されたら:

```bash
jj git export               # jj 側の bookmark 位置を @git に反映
```

### bookmark conflict（Name is conflicted）

fetch 後に `Error: Name main is conflicted` が出たら、ローカルとリモートで bookmark が別の場所を指している。解消:

```bash
jj bookmark set main -r <正しいリビジョン>
jj git push
```

### push 失敗時の復旧

誤った push をした後のリカバリ:

```bash
jj op log -s                          # 安全だった操作を探す
jj op restore <push前のop-id>          # 復元
# その後、正しい手順で push し直す
```

### "stale info" エラー / tag が jj 側に見えない

git bare + jj workspace 方式のセットアップ直後に起きやすい、fetch refspec 不足が原因の 2 症状。原因・対処コマンドは **jj-workflow skill のトラブルシュート節**（"stale info" エラー / tag が jj 側に見えない）に正本を集約。ここでは重複記載しない。

### リモートブックマーク（ブランチ）の削除

リモートにあるブックマークを削除するには、一度ローカルに track してから delete → push する:

```bash
# リモートブランチを fetch
jj fetch --all-remotes

# 確認
jj bookmark list --all-remotes

# ローカルブックマークとして track
jj bookmark track --remote origin great_feature

# ローカルブックマークを削除
jj bookmark delete great_feature

# 削除済みブックマークを push（リモートから削除される）
jj git push --deleted

# 確認
jj bookmark list --all-remotes
```

track → delete → push の流れがポイント。track せずに直接リモートを消す方法はない。

## fork リポジトリで upstream に追従

fork 元を `upstream` リモートとして登録している場合、upstream の最新に自分の作業を乗せ直す:

```bash
jj git fetch --remote upstream
jj rebase --branch @ --onto main@upstream
```

`--branch @` は @ と main@upstream の共通祖先から先を自動選択するので、自分の作業コミット全体が main@upstream の先頭に移動する。

origin にも反映するなら:

```bash
jj bookmark set main -r main@upstream
jj git push
```

## AI がハマりやすいアンチパターン

### `jj describe` だけ実行して終わる（commit したつもり事故）

`jj describe -m "msg"` は **@ に description を付けるだけ**で空 @ を作らない。これだけで終わると、次の Write/Edit が前回の作業と同じ change に紛れ込んで「いつの間にか巨大 commit」になる。

基本は `jj commit -m "msg"` で「確定 + 空 @ を作る」を一発。`jj describe` 単体は **過去 change の description を書き直したい時に `-r <change>` 付きで使う** ものと割り切る。

jj 公式 README / チュートリアルに `describe` 例が多い (`commit` は git ユーザ向け説明として位置付けが控えめ) のが学習バイアスの原因。それらをそのまま真似ると AI がこの罠にハマる。

### restore / revert を多用する

git の癖で `jj restore` や revert 的操作をしがち。jj では `new` + `rebase` / `split` で組み替えるほうが自然で安全。

### 複数エージェントが同じワークスペースに書き込む

並列エージェントは必ず別ワークスペースで作業させる。別プロセス推奨。同じ working copy を触ると conflict や意図しないスナップショットが発生する。

### マージコミットを急いで作る

独立した作業を無理にマージコミットでまとめない。bookmark で管理し、必要になったら合流。マージが不要になったら `abandon` で消せる。

### git コマンドを使う

jj 管理リポジトリでは git コマンドを使わない。jj が管理する状態と不整合が起きる。
