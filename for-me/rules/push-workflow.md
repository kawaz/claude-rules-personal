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
`gh-monitor:watch-workflow` 起動 hint を echo するのが標準パターン**。
AI はその hint を読んで skill を能動的に起動する (= SHA-pinned mode で commit に
紐づく workflow run を監視、全 run が terminal state に到達したら自動 exit)。

canonical 実装は `kawaz/bump-semver` の justfile:

```make
push: ci check-outdated-translations check-version-bumped
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
    @echo "[hint] gh-monitor:watch-workflow --sha $(bump-semver vcs get commit-id --rev main) --on-success release.yml 'just on-success-release' kawaz/bump-semver"
```

push task に hint echo が無いリポでは、AI が SHA (`git rev-parse HEAD` or jj
`latest(::@ & ~empty())`) を取って `gh-monitor:watch-workflow` skill を手動で
起動する。直接 `gh run watch` / `gh run list` を叩かない。

- 失敗したらその場で対処
- workflow が起動していない場合は理由を調査 (workflow ファイルのエラー /
  そもそも workflow を持たないリポ / `on: push` の paths filter にマッチしない 等)
