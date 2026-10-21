# justfile 運用の参照知識

kawaz リポの task runner は `justfile` が canonical。入口は「recipe を書く」「リリースを通す」「push 後を監視する」の 3 つ。

- [recipes](recipes.md) — 標準 recipe の並び、push 順序と mutating lint、just 変数を避ける理由、push の gate。
  justfile, just push, recipe, ensure-clean, check-version-bumped, bump-version, just 変数, worktree から push, on-default-branch
- [release-pipeline](release-pipeline.md) — tag / Release を手で作らない禁則、0.x の方針、VERSION bump からの標準ループ。
  リリース, publish, 初版, 1.0, 0.x, 互換性, 破壊的変更, release.yml, gh release create, git tag, jj tag, リリースが出ない, tag が作られない, VERSION bump
- [push-watch](push-watch.md) — `ccmsg notify --self` からの Monitor 起動、SHA の取得、起動しない時の切り分け。
  just watch, Monitor で watch, watch-workflow.sh, push 後の監視, gh-monitor, on-success-release, workflow が起動しない
