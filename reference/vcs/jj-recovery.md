# jj の復旧と bookmark / push のハマりどころ

## bookmark は保険

- bookmark さえ付いていれば、そのコミットは失われない
- 無理に main にマージする必要はない。独立ブランチで育てて、必要なときに合流すればいい
- `jj abandon` しても bookmark 付きコミットは visible のまま

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

### main が自分の祖先でない場合 (マージが必要)

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

### bookmark conflict (Name is conflicted)

fetch 後に `Error: Name main is conflicted` が出たら、ローカルとリモートで bookmark が別の場所を指している。解消:

```bash
jj bookmark set main -r <正しいリビジョン>
jj git push
```

IDE の git fetch が原因で bookmark conflict が発生した場合も、`jj git fetch` で解消する。

### push 失敗時の復旧

誤った push をした後のリカバリ:

```bash
jj op log -s                          # 安全だった操作を探す
jj op restore <push前のop-id>          # 復元
# その後、正しい手順で push し直す
```

### "stale info" エラー / tag が jj 側に見えない

git bare + jj workspace 方式のセットアップ直後に起きやすい、fetch refspec 不足が原因の 2 症状。原因・対処コマンドは reference の `vcs/jj-bare-workspace-setup` のトラブルシューティング節が正本。

### リモートブックマーク (ブランチ) の削除

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
