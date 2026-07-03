# Runbook: リポ引退チェックリスト

- Last Updated: 2026-07-03

## 適用ケース

リポを **後継リポで置き換えた** / **開発終了を決めた** / **rename した** とき。
放置すると監査で繰り返し観測される「移行後の後始末漏れ」(= marketplace の旧参照残存、
rename 後の化石ローカルクローン、廃止記録なしの事実上不使用化) を防ぐ。

**docs 先行で実装を断念したリポ (実装ゼロ) にも同じチェックリストを適用する** (=
README に「着手せず廃止」と後継 / 代替を明記して archive)。

## 前提

- `gh` CLI が対象リポ owner (kawaz / kawaz123) で認証済み
- ローカルクローンパス規約: `${XDG_DATA_HOME:-$HOME/.local/share}/repos/{host}/{owner}/{repo}/`

## チェックリスト

1. **README 冒頭に後継と理由を明記**
   - canonical 例: `kawaz/authsock-filter` の README 冒頭
     `> **This project is no longer maintained. Successor: authsock-warden**`
   - 「なぜ引退するか」と「代替として何を使うか」を 1-2 行で書く。読者が旧リポに
     辿り着いても即座に後継へ誘導される状態にする

2. **GitHub で archive**
   ```bash
   gh repo archive {owner}/{repo}
   ```
   期待結果: リポが read-only 化。以降 push / issue 作成が不可になり「生きている」
   と誤認されなくなる (= 破壊操作ではない、いつでも unarchive 可)

3. **参照元の一括更新** (= 旧名で grep して洗い出す)
   ```bash
   # ローカルの全 kawaz リポを旧リポ名 / 旧プラグイン名で横断 grep
   rg -l '{旧リポ名}|{旧プラグイン名}' ~/.local/share/repos/github.com/kawaz/*/main
   ```
   更新対象の代表:
   - `for-all/plugins.json` (claude-rules-personal) の marketplace / plugin 参照
   - 各 plugin リポの `.claude-plugin/marketplace.json`
   - `kawaz/homebrew-tap` の formula (旧 tap 名 / URL)
   - 他リポの `docs/` / README 内の旧名言及

4. **ローカルクローンの整理**
   - 引退リポの化石クローンを放置しない。使わないと分かった時点で作業ツリーを畳む
   - rename 済みなら旧名ディレクトリが残っていないか確認
     ```bash
     ls -d ~/.local/share/repos/github.com/kawaz/{旧リポ名} 2>/dev/null && echo "化石クローンあり"
     ```

5. **未 push commit・未整理 issue の確認と後継への移送**
   ```bash
   # 未 push の変更が残っていないか (jj / git)
   jj log -r 'remote_bookmarks()..@' 2>/dev/null || git log --branches --not --remotes --oneline
   # 未整理の local issue
   ls docs/issue/*.md 2>/dev/null
   ```
   後継リポで生きる知見 (未解決 issue / DR / findings) は **後継リポへ移送してから**
   archive する (archive 後は書き込めない)

6. **rename の場合は設定ファイル内の旧名参照も更新**
   - GitHub の rename は旧 URL を自動リダイレクトするが、ローカル設定 / manifest の
     旧名は自動追従しない
   - `.jj/repo/store` や `git remote -v` の origin URL、CI secrets の参照名、
     homebrew-tap の source URL を新名に揃える

## 失敗時の切り分け

| 症状 | 原因 | 対処 |
|---|---|---|
| archive 後に「知見を移送し忘れた」と気づいた | 手順 5 を飛ばした | `gh repo unarchive` で一時解除 → 移送 → 再 archive |
| 他リポの CI が旧プラグイン名で install 失敗 | 手順 3 の参照更新漏れ | 旧名で全リポ grep し直して更新 |
| `command not found` が後で発生 (brew 配布物) | homebrew-tap / dotfiles の旧名残存 | tap formula と dotfiles の brews list を新名に更新 |

## 関連

- `docs/runbooks/fleet-audit.md` — 引退漏れを定期検出する横断監査
- `for-all/rules/dogfooding-feedback-upstream.md` — 後継リポへの知見還元スタンス
