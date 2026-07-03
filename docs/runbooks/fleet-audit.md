# Runbook: 全リポ横断の定期監査

- Last Updated: 2026-07-03

## 適用ケース

kawaz の全ローカルリポ (`~/.local/share/repos/github.com/kawaz/*` + `kawaz123/*`) を
横断して、単リポ作業では見えない **移行漏れ / 参照不整合 / 残置** をまとめて検出する。

**頻度目安: 週次〜隔週**。監査自体の自動化 (定期実行の仕組み化) は別 issue で検討中
(`docs/issue/` の fleet-audit 自動化 issue を参照)。それまでは本 runbook を手動で回す。

## 前提

- `gh` CLI が kawaz / kawaz123 両 owner で認証済み (`GH_CONFIG_DIR` の面切替に注意)
- `rg` / `jj` / `just` / `bump-semver` が PATH 上にある

## チェックリスト

1. **rules リポの lint**
   ```bash
   (cd ~/.local/share/repos/github.com/kawaz/claude-rules-personal/main && just lint-rules)
   ```
   fatal (越境リンク / 自己参照 / `.draft-` 配置) が出たら即修正。5KB 超 warning は
   常時ロード肥大の検討材料として蓄積を観察

2. **各リポ docs/issue の鮮度と旧形式検出**
   ```bash
   # 旧形式 (frontmatter 不在 / INDEX 未登録) の一括検出は migrate、状況確認は list
   # local-issue plugin: /local-issue:list (放置日数降順) / /local-issue:migrate (正本化)
   for d in ~/.local/share/repos/github.com/kawaz/*/main; do
     ls "$d/docs/issue"/*.md >/dev/null 2>&1 && echo "$d に issue あり"
   done
   ```
   放置が長い / 旧形式が残るリポは `local-issue:migrate` で正本化

3. **marketplace / plugins.json の参照整合**
   ```bash
   # 旧プラグイン名 (rename 前の名前) が残っていないか横断 grep
   rg -n '{旧プラグイン名の候補}' ~/.local/share/repos/github.com/kawaz/*/main/.claude-plugin/marketplace.json \
      ~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/for-all/plugins.json
   ```
   確認軸: バンドル配布 vs 独立リポ配布の区別、marketplace 名 = plugin 名の実体
   (各リポの `.claude-plugin/plugin.json` の `name` が正本)

4. **homebrew-tap ローカル vs GitHub の同期**
   ```bash
   (cd ~/.local/share/repos/github.com/kawaz/homebrew-tap/main && \
     git fetch origin && git status -sb && git log --oneline origin/HEAD..HEAD)
   ```
   ローカルに未 push の formula 変更が溜まっていないか、GitHub 側と差分がないか確認

5. **各リポの release workflow 型 (旧 tag-push 待ち型の検出)**
   ```bash
   # on: push: tags: を待つ旧型は「仕組みの bug」(release-flow-awareness rule)
   rg -l -A3 'on:\s*\n?.*push' ~/.local/share/repos/github.com/kawaz/*/main/.github/workflows/release.yml 2>/dev/null
   rg -n 'tags:' ~/.local/share/repos/github.com/kawaz/*/main/.github/workflows/*.yml 2>/dev/null
   ```
   `on: push: tags:` で手動 tag push を待つ型を見つけたら bump-semver の release.yml
   テンプレへ書き換え提案 (= VERSION bump + main push で自動 release される標準ループ)

6. **未 push commit / 未 describe working copy の残置検出**
   ```bash
   for d in ~/.local/share/repos/github.com/kawaz/*/main; do
     (cd "$d" && jj log -r '@ | remote_bookmarks()..@' --no-pager 2>/dev/null \
       | rg -q 'no description|remote_bookmarks' && echo "要確認: $d")
   done
   ```
   未 describe の working copy や未 push commit が居残っていたら、読んで固定 or 破棄

7. **ローカルクローンと GitHub 実体の突合**
   ```bash
   # rename リダイレクト / archived を検出 (origin の実体と名前がズレていないか)
   for d in ~/.local/share/repos/github.com/kawaz/*/; do
     name=$(basename "$d")
     gh repo view "kawaz/$name" --json name,isArchived,nameWithOwner 2>/dev/null \
       | rg -q "\"name\":\"$name\"" || echo "要確認 (rename/archived/不在?): $name"
   done
   ```
   rename リダイレクトで実体名が変わっているクローン、archived 済みリポを洗い出す
   (= `docs/runbooks/repo-retirement.md` の後始末対象)

8. **open issue の偏在**
   ```bash
   for d in ~/.local/share/repos/github.com/kawaz/*/main; do
     n=$(ls "$d/docs/issue"/*.md 2>/dev/null | grep -v INDEX | wc -l | tr -d ' ')
     [ "${n:-0}" -gt 10 ] && echo "triage フラグ ($n 件): $d"
   done
   ```
   目安 **10 件超** で triage フラグ。溜まっているリポは close / 昇華で棚卸し

## 失敗時の切り分け

| 症状 | 原因 | 対処 |
|---|---|---|
| `gh repo view` が全リポで空 | 面 (GH_CONFIG_DIR) がズレて認証先が違う | kawaz / kawaz123 の面を確認して再実行 |
| lint-rules が fatal | rule 構造規約違反 | `docs/runbooks` ではなく該当 rule を修正 |
| workflow grep が誤検出 | `on: push` に paths filter が付いた正常型 | release.yml を目視して tag 待ちか VERSION 起動か判別 |

## 関連

- `docs/runbooks/repo-retirement.md` — 引退リポの後始末手順 (手順 7 の受け皿)
- `for-all/rules/release-flow-awareness.md` — release workflow の標準型 (手順 5)
- `for-me/rules/push-workflow.md` — 未 push 残置の扱い (手順 6)
