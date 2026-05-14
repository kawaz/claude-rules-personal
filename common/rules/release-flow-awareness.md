# リリースフロー把握ルール

release が絡む作業の前に、対象リポジトリの **GitHub Actions workflow** と **タスクランナー設定** (Taskfile.pkl / justfile / Makefile / package.json scripts 等) を読み、リリース全体がどう自動化されているかを把握する。

## kawaz の標準運用

**tag 打ちと GH Release 作成は CI/CD の仕事**。人間 (kawaz) もエージェント (Claude) も tag を打たない。

標準フロー (kawaz/bump-semver の release.yml が canonical):

1. ローカル: VERSION (or `PklProject.version` / `Cargo.toml [package].version` 等) を bump して main に push
2. release workflow が **VERSION ファイルの変更を trigger** に起動 (`on: push: branches: [main] + paths: [VERSION]` 等)
3. workflow 内で「既存 tag より大きいか」を semver で検証 (e.g. `bump-semver compare gt VERSION 'vcs:latest-tag()'`)
4. 検証 OK なら build → `gh release create "v${VERSION}"` で **release.yml job 自身が tag + GH Release を作成**
5. 後段の job (homebrew tap 更新等) は完成した release artifact を参照

`gh release create` は実行時点で **tag が無ければ自動で作る**。これが kawaz パターンの肝。

## 適用タイミング

以下のいずれかに該当する commit を作る前 / push する前:

- VERSION ファイル / `PklProject.version` / `Cargo.toml [package].version` / `package.json $.version` を bump
- tag を伴う作業
- `release` 系 task / workflow を起動しうる操作

## 必須確認手順

1. `.github/workflows/*.yml` を全て読む。特に release 系 workflow の `on:` 句
2. task runner の `push` task を読む (= `pkf run push` / `just push` で何が起こるか)
3. release workflow が「VERSION push trigger → 自動 tag + release」型 (= kawaz 標準) になっているか確認

## release.yml が標準型でなかった場合

「`on: push: tags: ...` で **手動 tag push 待ち**」型のリポを発見したら、**それは仕組みの bug**。

対応:
- 該当リポの release.yml を kawaz/bump-semver の release.yml をテンプレに書き換えることを提案
- 書き換え (= main push trigger + 自動 tag) をしてから VERSION bump を進めると、自動でリリースされる
- 一時的に旧 trigger のまま release が必要な場合は kawaz に確認 (AskUserQuestion)。Claude が独断で `git tag` / `jj tag` を打たない (release が自動で出てこないのは仕組みの欠陥であって、手動 tag で穴埋めしない)

## 不明な場合

workflow の挙動を予測できない / 自動化が複雑な場合は **AskUserQuestion で確認**。push を黙って実行しない。

## canonical 実装

- `kawaz/bump-semver/.github/workflows/release.yml` — `on: push: branches:[main] + paths:[VERSION]` → check-version → build (matrix OS/arch) → release (`gh release create` で tag 自動作成) → update-homebrew
- 同等のパターンを Pkl package / Rust crate / npm package 等に応用するときは、check-version 部分の version 取得ロジック (Cargo.toml / package.json / PklProject) と build artifact だけ差し替えれば良い

## 関連

- `feedback_tag_release_boundary` (kawaz auto-memory) — tag/release は Claude が打たない方針の原点
