# リリースフロー把握ルール

kawaz リポでは **tag 打ちと GH Release 作成は CI/CD の仕事**。人 (kawaz) もエージェント (Claude) も tag を打たない。

## 自動化の標準ループ

1. `git/jj push` を hook ガードが捕まえて `pkf run push` を強制
2. `pkf run push` の deps で version check が走り、必要なら bump-version を強制 (= `pkf run bump-version` に誘導される)
3. `pkf run bump-version` が VERSION (or `PklProject.version` / `Cargo.toml [package].version` / `package.json $.version`) を更新して commit
4. main に push されると release workflow が VERSION 変更を trigger に起動 (`on: push: branches:[main] + paths:[VERSION]` 等)
5. workflow 内で「既存 tag より大きいか」を semver で検証 (`bump-semver compare gt <version> 'vcs:latest-tag()'`)
6. 検証 OK なら build → `gh release create "v${VERSION}"` で **workflow 自身が tag + GH Release を作成**
7. 後段 job (homebrew tap 更新等) が release artifact を参照

`gh release create` は **tag が無ければ自動で作る**。tag は workflow が打つ、人/エージェントは tag を扱わない。

canonical 実装: `kawaz/bump-semver/.github/workflows/release.yml`。

## リポを触るときに読む観点

新規リポを触る / リリースフローを認識していないリポを触るときは、以下を読んで仕組みを把握:

1. `.github/workflows/*.yml` 全部 (特に release 系の `on:` 句)
2. task runner の `push` task (Taskfile.pkl / justfile / package.json scripts)
3. `pkf run bump-version` 相当の task の有無 + 何の version file を bump するか

## 標準型から外れたリポを発見したら

「`on: push: tags: ...` で **手動 tag push を待つ**」型を見つけたら **仕組みの bug**。kawaz/bump-semver の release.yml をテンプレに書き換える提案を出す。

- 書き換え中は Claude が `git tag` / `jj tag` / `gh release create` を手で叩いて穴埋めしない (= 自動化が完成するまで release を出さない方が筋。緊急なら kawaz に確認)
- 書き換え後は標準ループに乗るので、以降は VERSION bump + main push だけで release される

## 不明な場合

workflow / task runner の挙動が読み取れない場合は **AskUserQuestion で確認**。黙って push しない。

## 関連

- `feedback_tag_release_boundary` (kawaz auto-memory) — tag/release は Claude が打たない方針の原点
