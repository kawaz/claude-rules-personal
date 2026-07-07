---
name: release-flow
description: kawaz リポのリリース自動化フローの手順書。VERSION bump → main push → release workflow が semver 検証して `gh release create` で tag + GH Release を作る標準ループの全体像、新規リポ / 未知リポを触るときに読むべき観点 (.github/workflows の on: 句、push task、bump-version task)、`on: push: tags:` で手動 tag を待つ非標準型を見つけたときの kawaz/bump-semver release.yml テンプレへの書き換え提案手順を扱う。リリースフローの整備・調査・修正、release が出ない原因調査、release workflow の新規セットアップの場面で使う。禁則 (tag を打たない等) は release-flow-awareness rule が正。
---

# リリースフロー標準ループ

kawaz リポでは tag 打ちと GH Release 作成は CI/CD の仕事。人もエージェントも
tag を打たない (禁則の正本は release-flow-awareness rule)。

## 自動化の標準ループ

1. `git/jj push` を hook ガードが捕まえてリポの push task に誘導する
2. push task は deps で version check を回し、必要なら bump-version task を強制
3. bump-version task が VERSION (or `PklProject.version` / `Cargo.toml
   [package].version` / `package.json $.version`) を更新して commit
4. main に push されると release workflow が VERSION 変更を trigger に起動
   (`on: push: branches:[main] + paths:[VERSION]` 等)
5. workflow 内で「既存 tag より大きいか」を semver で検証
6. 検証 OK なら build → `gh release create "v${VERSION}"` で **workflow 自身が
   tag + GH Release を作成** (`gh release create` は tag が無ければ自動で作る)
7. 後段 job (homebrew tap 更新等) が release artifact を参照

canonical 実装: `kawaz/bump-semver/.github/workflows/release.yml`。

## リポを触るときに読む観点

新規リポ / リリースフローを認識していないリポを触るときは以下を読んで把握:

1. `.github/workflows/*.yml` 全部 (特に release 系の `on:` 句)
2. task runner の `push` task (Taskfile.pkl / justfile / package.json scripts)
3. bump-version task の有無 + 何の version file を bump するか

## 標準型から外れたリポを発見したら

「`on: push: tags: ...` で **手動 tag push を待つ**」型を見つけたら仕組みの
bug。kawaz/bump-semver の release.yml をテンプレに書き換える提案を出す。

- 書き換え中は Claude が `git tag` / `jj tag` / `gh release create` を手で
  叩いて穴埋めしない (= 自動化が完成するまで release を出さない方が筋。
  緊急なら kawaz に確認)
- 書き換え後は標準ループに乗るので、以降は VERSION bump + main push だけで
  release される
