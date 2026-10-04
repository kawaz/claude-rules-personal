# justfile 運用の参照知識

kawaz リポの task runner は `justfile` が canonical。入口は「recipe を書く」「リリースを通す」「push 後を監視する」の 3 つ。

- [recipes](recipes.md) — 標準 recipe の並び、push 順序と mutating lint、just 変数を使わない理由、version bump gate、worktree からの push gate。
  発火語: justfile, just push, recipe, ensure-clean, check-version-bumped, bump-version, just 変数, worktree から push, on-default-branch
- [release-pipeline](release-pipeline.md) — tag / GH Release を手で作らない禁則、初版は 0.x で出し 0.x の間は互換性を考えない、VERSION bump → push → workflow の標準ループ、標準型から外れたリポの直し方。
  発火語: リリース, publish, 初版, 1.0, 0.x, 互換性, 破壊的変更, release.yml, gh release create, git tag, jj tag, リリースが出ない, tag が作られない, VERSION bump
- [push-watch](push-watch.md) — `ccmsg notify --self` からの Monitor 起動、backend 別の SHA 取得、hint echo の残存リポ、起動しない時の切り分け。
  発火語: just watch, Monitor で watch, watch-workflow.sh, push 後の監視, gh-monitor, on-success-release, workflow が起動しない
