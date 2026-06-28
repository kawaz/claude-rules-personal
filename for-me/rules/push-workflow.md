# Push ワークフロー

## commit (= 固定) → push の順

push の前提は固定された commit。**自分が修正したファイルだけを `<files...>`
でパス指定して固定する**。パスなしの `jj commit -m "msg"` / `git commit -am` /
`git add .` は **他セッション (= 別 workspace / 別 Claude) の未認識変更を
巻き込む事故源** (双方向: 自分が巻き込む / 自分が巻き込まれる)。

- **jj リポ**: `jj commit -m "msg" <files...>` 必須。`jj split -m "msg" <files...>` も同様。
  `jj describe` 単体は @ にラベルを貼るだけ (= 固定ではない)。詳細は [[jj-tips]] skill。
- **git リポ**: `git commit -m "msg" <files...>` 必須。`-a` / `git add .` は避ける。

### 例外 (= パス指定なし OK)

@ の全ファイルが自セッション生成かつ他セッション接触なしと確認済みの時だけ。
通常は判断コストの方が高いので **常にパス指定** が安全。

## push 直前: @ に他セッションのファイルが居残っていないか確認

`jj status` (or `git status`) で @ の中身を確認する。他セッションが追加した
ファイルが `<files...>` 指定から漏れて @ に残っていたら、**放置せず読む**:

- コミットすべき内容なら別 commit で固定 (= パス指定で)
- 残す価値がない / 既に対応済みなら削除

「自分のファイルじゃないからほっとく」は不可。古いファイルを未 commit のまま
@ に放置する理由はない。

## rules リポ固有: commit 前のメタ規約 lint

`claude-rules-personal` 等 rule ファイルを触るリポでは、commit 前に以下を確認する。
内容生成に集中すると **リポ固有の構造規約を取りこぼす** ため、機械的にチェックする
(= 単発生成のメタ盲点対策、`[[self-written-rule-blind-spots]]` 観点):

- **リンク方向**: `for-all/rules/*.md` 内の `[[name]]` リンクが `for-me/rules/` 側を指していないか (overlay 越境で dead link 化)
- **未来予告 / 過去 narrative**: `[[no-historical-noise]]` 違反 — `> Note: 将来 X を検討` / `以前は X だったが` / バージョン番号付き注釈 (`v0.X.Y で確認`) を残していないか
- **自己参照**: ファイル末尾「関連」セクションでそのファイル自身を `[[self]]` で参照していないか
- **常時ロードサイズ**: 単一 rule ファイルが 5KB を超えたら、`[[rule-writing-guidelines]]` の「省コンテキスト」原則に照らして分割 / reference 化 / 詳細外出しを検討
- **`.draft-` prefix の rule 配置**: `for-me/rules/` 配下に `.draft-*.md` を置かない (常時ロードされる)。draft は `docs/issue/` へ

新規 rule 追加 / 既存 rule 修正の commit 前に 1 度通す。簡易検査:

```bash
# 越境リンク (for-all → for-me)
rg -l '\[\[' for-all/rules/ | while read f; do
  rg -o '\[\[([^\]]+)\]\]' -r '$1' "$f" | while read name; do
    [ -f "for-me/rules/${name}.md" ] && echo "越境: $f → for-me/rules/${name}.md"
  done
done

# 自己参照
for f in for-all/rules/*.md for-me/rules/*.md; do
  base=$(basename "$f" .md)
  rg -q "\[\[$base\]\]" "$f" && echo "自己参照: $f"
done

# .draft- 配置
ls for-{all,me}/rules/.draft-*.md 2>/dev/null && echo "draft が rules 配下に存在"

# 大きすぎる rule (5KB 超)
find for-{all,me}/rules/ -name '*.md' -size +5k
```

## push 経路

`jj git push` / `git push` を直接実行しない。リポ側の push task (justfile 等) を使う。
直接 push しても push-guard プラグインの hook がブロックし、正規経路に誘導する。

## push 後は workflow run を watch する

push の正規経路はリポの push task (justfile 等)。**push task は実行末尾で
`cmux-msg notify --self` で AI に Monitor 起動指示を流すのが canonical**。
AI は subscribe stream で能動受信して `just watch` を Monitor で起動する。

理由 (= 旧 echo hint からの移行):

- `@echo "[hint] ..."` 経路は AI が hint を読み飛ばしたり引数を勝手に
  arrange する事故源 (= cache-warden で実例観測、claude-cmux-msg
  DR-0017/0018 の動機)
- `cmux-msg notify --self` は subscribe stream に text 同梱で即届く、
  AI rule (= 「`Monitor で 'just <task>' を起動して` が届いたら task 名
  そのまま Monitor で起動」) で誤解釈の余地なし
- watch 引数 (sha / repo / on-success action) を **`just watch` task に
  集約** = push 時の毎回 echo が短くなる、AI は task 名コピペだけで起動可

canonical 実装は `kawaz/bump-semver` の justfile (v0.43.0+):

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

`watch-workflow.sh` は kawaz の `gh-monitor` plugin が提供。**PATH 通る前提**
(= plugin install 時の慣習で latest version の `scripts/` を PATH に追加)。

### 旧 hint echo パターンが残ってるリポ

`@echo "[hint] gh-monitor:watch-workflow --sha ..."` をまだ持っているリポは
canonical 同期で notify --self + just watch に書き換える。AI が hint echo を
見つけたら、その場で直すか issue 起票するか判断。

### push task に notify も hint も無いリポ

AI が SHA (`git rev-parse HEAD` or jj `latest(::@ & ~empty())`) を取って
`gh-monitor:watch-workflow` skill を手動で起動する。直接 `gh run watch` /
`gh run list` を叩かない。

### 失敗時 / 起動しない時

- 失敗したらその場で対処
- workflow が起動していない場合は理由を調査 (workflow ファイルのエラー /
  そもそも workflow を持たないリポ / `on: push` の paths filter にマッチしない 等)
