# リリースフロー (禁則)

> **適用前提**: リリース成果物を持つプロジェクトのみ。リリース不要な
> プロジェクトでは `release.yml` 不在を bug と判定しない / 「リリースが
> 完成しない」報告をしない / push 後の watch で release workflow を期待しない。

kawaz リポでは **tag 打ちと GH Release 作成は CI/CD の仕事**:

- 人 (kawaz) もエージェント (Claude) も **`git tag` / `jj tag` を打たない**
- **`gh release create` を手で叩かない** (workflow 自身が tag + Release を作る)
- release は VERSION 系ファイルの bump + main への push だけで出る
  (標準ループ・新規リポで読む観点・非標準リポの書き換え提案は
  `release-flow` skill 参照)
- workflow / push task の挙動が読み取れない場合は **AskUserQuestion で確認**、
  黙って push しない

## 関連

- `feedback_tag_release_boundary` (kawaz auto-memory) — tag/release は Claude が打たない方針の原点
