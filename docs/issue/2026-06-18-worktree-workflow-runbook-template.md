# worktree/workspace 経由作業の runbook テンプレを docs-structure に追加

## 背景

Claude Code の background job では `EnterWorktree` (= 内部的に jj 環境では jj-workspace、git 環境では git worktree) が必須化された (= 並列 job の事故防止)。これに伴い、AI session が:

- worktree 内で編集 → commit → main 統合 → push という手順を毎回踏む
- jj/git の差異を AI 側の知識で吸収している
- 「直近 commit の後追い修正」「divergent からの統合」など多発するシナリオで毎回判断コストを払っている

claude-plugin-reference v0.2.17 で実際にこの手順を 1 回踏んで知見が固まった (一次資料):
https://github.com/kawaz/claude-plugin-reference/blob/main/docs/journal/2026-06-18-worktree-promote-and-marker-lockfile.md

詰まり所のサマリ:

1. WC 切り替え時 (= `jj edit <other>`) に Read ツールのファイル状態がクリアされる挙動
2. `jj edit` した後の元 change への戻り方 / WC 切り替え時のファイル消失感
3. divergent (= 共通祖先から複数 line 分岐) からの統合判断 (= rebase 対象の選び方)
4. `bump-semver vcs is clean` が jj 環境では「@ に変更があれば dirty」と判定する挙動 (= `jj new` で空 change を上に作る必要)
5. `jj-bookmark-auto-advance` の挙動と bookmark 移動の関係
6. CI workflow が無いリポでの push 後検証フロー (= `claude plugin marketplace update` + `claude plugin update` + `/reload-plugins` の組み合わせ)

## スコープ

含む:
1. `templates/runbooks/worktree-workflow.md` の新設 (= kawaz リポ共通テンプレ)
2. `docs-structure` skill での参照リンク追加
3. 既存リポ (claude-plugin-reference / bump-semver / その他 canonical 準拠リポ) への migration ガイド

含まない (= 別 issue):
- `bump-semver vcs` 拡張 (関連 issue: `kawaz/bump-semver/docs/issue/2026-06-18-vcs-worktree-promote-support.md`) — 本 runbook で参照する側
- justfile の `push` task 冒頭ゲート追加 (= bump-semver vcs 拡張完了後、`docs-structure` の justfile 標準テンプレを更新)
- jj-worktree plugin (or Claude Code 本体) への bookmark 自動セット提案 (= 別 issue 候補)

## runbook の概略

```markdown
# worktree/workspace 経由作業の runbook

## 想定状況
Claude Code の background job で EnterWorktree が必須化されたケース。
親 workspace と並列で worktree 内で作業を進め、最後に main に合流させて push する。

## 基本フロー
1. EnterWorktree でファイル isolation を確保
2. worktree 内で編集 + jj commit (= ファイル指定で固定、push-workflow rule に従う)
3. `just push` を試す
4. justfile の hint が出たら従って `just sync` → `just promote` → `just push`

## hint が出る理由
`bump-semver vcs is worktree` が true を返すと、`just push` 冒頭ゲートが
exit 1 + echo hint で誘導する (= jj/git 差異を vcs 抽象化に隠蔽済み)。

## 直近 commit を後追い修正したい時のパターン
- 別 workspace で進んでいる直近 commit (= まだ main 未進行) を取り消し / 改変したい場合
- `jj edit <change>` で WC を切り替え → 編集 → `jj edit @-` で戻る
- 自分の change を `jj rebase -d <target>` で乗せ直す
- divergent の場合は `jj rebase -s <root-change> -d main` で line ごと持ち上げる

## CI workflow 無しリポでの push 後検証
- `just push` の `on-success-release` で `claude plugin marketplace update`
  + `claude plugin update` が自動実行される (= cache が新版に更新)
- 後は `/reload-plugins` + skill invoke で実機確認

## 詰まり所 / 教訓
(journal の知見をテンプレ化)
```

## 該当性の確認

- claude-plugin-reference v0.2.17 で実際に 1 回踏んで全工程が動いた = 手順は実証済み
- docs-structure skill (本リポ) は kawaz リポ群の docs/ 標準を供給しているので、ここに置けば自動的に全リポへ展開可能
- bump-semver vcs 拡張 (関連 issue) と組み合わせることで「jj/git 依存を justfile に隠蔽 + runbook で AI を誘導」の二段構えになる

## 実装方針は当事者判断に委ねる

具体的な構成 / 表記 / 既存 docs-structure テンプレ群との一貫性は本リポの設計思想に従う。本 issue は **必要性のフラグ + 一次資料 (= 実践 journal) の提示** に留める。

## blocked-by

`kawaz/bump-semver/docs/issue/2026-06-18-vcs-worktree-promote-support.md` の実装完了後に着手するのが筋 (= runbook で vcs 新サブコマンドを参照するため)。
