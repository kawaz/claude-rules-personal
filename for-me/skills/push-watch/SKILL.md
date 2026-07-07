---
name: push-watch
description: kawaz リポで push した後の CI / Release workflow 監視運用の手順書。push task 末尾の `cmux-msg notify --self` 通知を受けて `just watch` を Monitor で起動する canonical フロー、watch-workflow.sh (gh-monitor plugin) の引数構成、`--on-success` での release 後続アクション、旧 `@echo "[hint] ..."` パターンが残るリポの移行書き換え、notify も hint も無いリポで SHA を取って手動 watch する手順を扱う。push 後に workflow を見届ける場面、push task を新規リポに整備する場面、hint echo を見つけた場面で使う。
---

# push 後の workflow watch 運用

push の正規経路はリポの push task (justfile 等)。**push task は実行末尾で
`cmux-msg notify --self` により AI に Monitor 起動指示を流すのが canonical**。
AI は subscribe stream で能動受信して `just watch` を Monitor で起動する。

理由 (= 旧 echo hint からの移行):

- `@echo "[hint] ..."` 経路は AI が hint を読み飛ばしたり引数を勝手に
  arrange する事故源 (= cache-warden で実例観測、claude-cmux-msg
  DR-0017/0018 の動機)
- `cmux-msg notify --self` は subscribe stream に text 同梱で即届く、
  AI 側は task 名コピペだけで起動でき誤解釈の余地なし
- watch 引数 (sha / repo / on-success action) を `just watch` task に集約

canonical 実装は `kawaz/bump-semver` の justfile:

```make
push: ci check-outdated-translations check-version-bumped
    bump-semver vcs push --branch "$(bump-semver vcs get default-branch)" --jj-bookmark-auto-advance
    cmux-msg notify --self --text "Monitor で 'just watch' を起動して" 2>/dev/null || true

watch:
    watch-workflow.sh --sha $(bump-semver vcs get commit-id --rev "$(bump-semver vcs get default-branch)") --on-success release.yml 'just on-success-release' kawaz/bump-semver
```

AI 側のアクション:

1. push 後、subscribe stream で `"text":"Monitor で 'just watch' を起動して"`
   が届いたら、**Monitor ツール**で `just watch` を `persistent=true` で起動
2. `watch-workflow.sh` が CI / Release を SHA-pinned で監視、全 check が
   terminal state に到達したら自動 exit
3. `--on-success release.yml 'just on-success-release'` 経由で `[ACTION:...]`
   event が emit されたら、AI は `just on-success-release` を実行
   (= homebrew tap pull + brew upgrade で v 反映)

`watch-workflow.sh` は kawaz の `gh-monitor` plugin が提供。PATH 通る前提
(= plugin install 時の慣習で latest version の `scripts/` を PATH に追加)。

## 旧 hint echo パターンが残ってるリポ

`@echo "[hint] gh-monitor:watch-workflow --sha ..."` をまだ持っているリポは
canonical 同期で notify --self + just watch に書き換える。AI が hint echo を
見つけたら、その場で直すか issue 起票するか判断。

## push task に notify も hint も無いリポ

AI が SHA を取って `gh-monitor:watch-workflow` skill を手動で起動する。
SHA は backend で使い分ける:

- **git**: `git rev-parse HEAD`
- **jj**: `jj log -r 'heads((::@-) & (~empty() | merges()))' --no-graph -T commit_id`
  = `@` を除いた最新の固定「実体」コミット。`@-` 起点で未コミット working copy を
  避け、`| merges()` で jj の空マージ ("merges without user modifications") を救済し、
  timestamp でなく topology で選ぶため `heads()`。素朴な `latest(::@ & ~empty())` は
  存在しない SHA を pin して watch が no-match-timeout まで無駄常駐する事故になる。

直接 `gh run watch` / `gh run list` を叩かない。

## 失敗時 / 起動しない時

- 失敗したらその場で対処
- workflow が起動していない場合は理由を調査 (workflow ファイルのエラー /
  そもそも workflow を持たないリポ / `on: push` の paths filter にマッチしない 等)
