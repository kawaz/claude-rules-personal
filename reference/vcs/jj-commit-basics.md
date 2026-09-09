# jj のコミット操作の基本

## 原則: git 脳を捨てる

jj で git のやり方 (restore, revert, reset) を持ち込むとだいたい破綻する。jj はコミットの並べ替え・組み替えが圧倒的に簡単なので、「元に戻す」のではなく「正しい形に組み替える」。

## 覚えるべき 5 コマンド

副作用のない参照系 (st/show/diff/log) は除いて、コミット操作はこの 5 つでほぼ全部できる:

- **`jj commit -m "msg" <files...>`** — 指定ファイルを msg で確定し、子に空 @ を作って前進する (= `jj describe + jj new` の合体、公式 help 明記)。日常の「commit したい」はこれ一発。**パスなしの `jj commit -m "msg"` は禁則** (= マルチセッション運用で他セッションが @ に追加した未認識ファイルを巻き込む事故源、後述の「パス指定なしで他セッション変更を巻き込む」参照)。git の `git commit -m "msg" <files...>` と同じ感覚で使える
- **`jj new`** — 名無しの編集可能な空コミットを生やす。jj では add や commit は不要 (ワークスペースの変更は全て自動コミット)。`jj new` で空コミットに移動すれば、さっきまでのコミットとワークスペースが切り離されてカジュアルに保護される。`commit` を使わず手動で「描いて→新空 change へ」したい時や、特定 revision の子として空 change を生やしたい時に使う
- **`jj rebase`** — コミットを移動・挿入する
- **`jj split`** — コミットを分割する (commit との差は後述の使い分け節)
- **`jj edit`** — カレントワークスペースを別コミットに切り替える (git switch に近い)

なお `jj describe -m "msg"` 単体は **過去 change の description を後から書き直す時 (`-r <change>`) にだけ使う**。@ に describe しても空 @ は進まないので「commit したつもり」事故になる (後述)。

## jj edit — 気兼ねなくコミット間を行き来

`jj edit X` でワークスペースの中身が X の状態に完全に切り替わる。

- 編集中のファイルは? → jj はあらゆる jj コマンド実行時 (`jj st` や `jj --help` すら) にワークスペースの変更を自動 snapshot する。`jj edit` 等でワークスペース切り替えが必要な場面でも同様に保護される
- git の stash のようなコンフリクトも起きない。元のコミットに `jj edit` すればすぐ元の状態に戻れる
- 複数コミット間を気兼ねなく行き来できるのが jj の強み
- デフォルトでは 1MB 以上のファイルは自動 snapshot 対象外だが、config で変更可能。対象外ファイルがあれば jj が Warning/Hint で教えてくれるので、最初から特別気にする必要はない

## `jj commit` と `jj split` の使い分け

シンプルな用途では両者の動作はほぼ同じだが、`commit --help` に明示された 4 つの差がある:

1. **interactive デフォルト**: commit=no (全選択) / split=yes (diff editor)
2. **`-r` の有無**: commit は @ 専用 / split は任意 revision に効く (= 過去 change の分割可)
3. **bookmark の前進**: split (without `-o`/`-A`/`-B`) は @ (= remaining 側) に bookmark を前進させる / commit は前進させない
4. **`-o`/`-A`/`-B` 配置オプション**: split のみ (selected を別位置に挿入できる)

公式 help 引用:

> When called without path arguments or `--interactive`, `jj commit` is equivalent to `jj describe` followed by `jj new`.

= path 引数なしは `jj describe + jj new` の合体。ただし **マルチセッション運用ではパスなしは禁則** (= 他セッションが @ に追加した未認識ファイルを巻き込む)。常に `jj commit -m "msg" <paths>` でパス指定する。

実用上の選び方:

| やりたいこと | 選ぶコマンド |
|---|---|
| @ の中身を path 指定で commit (= 日常) | `jj commit -m "msg" <paths>` |
| bookmark を末端に追随させながら部分 commit | `jj split -m "msg" <paths>` |
| 過去 change を後から分割 (`-r <change>`) | `jj split` 一択 |
| selected を別位置に挿入 (`-o`/`-A`/`-B`) | `jj split` 一択 |

シンプルな日常 commit は commit、bookmark を進めたい / 位置を選びたい / 過去を分割したい時だけ split、というのが棲み分けの目安。

## ユーザーが「コミット」と言った場合

1. 適切な関心事単位でコミットを分割する (chore/feat/refactor/docs 等)
2. 末端 change から順に `jj commit -m "msg" <files...>` でパス指定して確定 (@ も自動で空に進む)
3. 最後に @ が空 change のまま (= 次の作業の入れ物として開いている) であることを確認
4. @ に他セッションが追加した未 commit ファイルが残っていれば、放置せず読む (= 別 commit で固定するか、削除するか判断)

## pre-commit フック未対応

jj は Git の pre-commit フックを実行しない。push 前に手動で lint/format を確認するか、`jj fix` を使用する。

## パス指定なしで他セッション変更を巻き込む

並列 Claude セッション / 別 workspace 運用では、自分が認識していない @ への追加 (例: 他セッションが起票した docs/issue/<file>.md) が混入しうる。パスなしの `jj commit -m "msg"` は @ の全変更を確定するので、そういうファイルも同じ commit に巻き込まれる (= ノイズ commit / 意味不明 commit)。

逆方向の事故もある: 自分が作業中のファイルが、他セッションがパスなし `jj commit` / `jj split` を打った瞬間に巻き込まれる。

予防: **常に `jj commit -m "msg" <files...>` でパス指定** する。`jj split` も同様。docs/issue/ のような疎結合領域はパス指定で並列に進めても干渉しない。

push 直前は `jj status` で @ に他セッション追加ファイルが居残っていないか確認し、残っていれば**放置せず**読む (= 別 commit で固定するか、削除するか判断)。詳細は `for-me/rules/push-workflow.md`。

## `jj describe` だけ実行して終わる (commit したつもり事故)

`jj describe -m "msg"` は **@ に description を付けるだけ**で空 @ を作らない。これだけで終わると、次の Write/Edit が前回の作業と同じ change に紛れ込んで「いつの間にか巨大 commit」になる。

基本は `jj commit -m "msg"` で「確定 + 空 @ を作る」を一発。`jj describe` 単体は **過去 change の description を書き直したい時に `-r <change>` 付きで使う** ものと割り切る。

jj 公式 README / チュートリアルに `describe` 例が多い (`commit` は git ユーザ向け説明として位置付けが控えめ) のが学習バイアスの原因。それらをそのまま真似ると AI がこの罠にハマる。
