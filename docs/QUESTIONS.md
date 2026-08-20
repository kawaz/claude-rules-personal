# 裁定・確認待ち一覧 (ユーザ用)

## 運用規約

<details>
<summary>ゼロコンテキストエージェント向け（本セクションは消さない）</summary>

- 裁定/確認待ち項目を 1項目=1ラベル=1セクション で記載
- ラベル形式: XX-Q1（XX は 2-3 文字、バッチやセッション内で一意、Qn単独の使い回し禁止、長期一意性は不要)
- 依頼形式: 「👺XX-Q1 の裁定お願いします」（参照用途ではラベルに👺を付けない。誤陽性がユーザのハイライト/アラームを汚す）
- チャット提示と同一ターンで本ファイルに記録 + path 指定 commit (push はリリース窓に同乗)
- 裁定が下りたら該当セクションを即削除し、内容は正規の記録先 (DR / issue / journal / close_reason) へ反映。本ファイルは常に「現在待ち」だけを持つ
- 参照は[]()で提示（リポ内は相対、リポ外はフルパス）
- 初版質問/依頼は長文で書かない（ユーザが説明を求めらたら本ファイルに説明を追加し、チャットで👺ラベルで再依頼）
- **選択肢・確認項目は `- [ ] a: …` 形式（チェックボックス + ラベル）で書く**。
  Q / C で記法を分けない。回答は「チェックを付ける」でも「XX-Q1a」と言葉で返すでも通る
  （複数まとめてチェックし「チェックしたよ」の一言で済ませる運用を想定）

</details>

## 裁定待ち

### ER-Q1: `emerada` (末尾 co 無し) 系の識別子も emrd に寄せるか

`emeradaco` → `emrd` の一貫作業とは別に、**`emerada` を冠した稼働中インフラ**が残っている。
一斉に変えないと認証切替 (ssh 鍵 / gh トークン) が壊れるので、まとめて裁定してほしい。

対象:

| 種別 | 実体 |
|---|---|
| ssh agent socket | `~/.ssh/agent-emerada.sock` (+ `.cw` / `.aw` variant) |
| ssh 設定 | `~/.ssh/config` の `IdentityAgent` / `ControlPath mux-emerada-%C` |
| gh 設定 | `~/.config/gh-emerada` (GH_CONFIG_DIR)、`.dotfiles/.gitignore` |
| git 設定 | `.dotfiles/config/git/config-user-emerada.gitconfig` |
| warden 設定 | cache-warden / authsock-warden の config.toml |
| ルール文書 | emrd リポ `for-me/rules/git-workflow-emerada.md`, `playwright-cli-emerada-profile.md` |

- [ ] a: 全部 emrd に寄せる (実ファイル・ソケット名まで一括。取りこぼすと認証が切り替わらないので慎重に)
- [ ] b: 文書・ルールのファイル名だけ emrd に寄せ、実インフラ名 (sock / config dir) は据え置き
- [ ] c: 今回は据え置き (`emerada` はサニタイズ対象語ではないので急がない)

### ER-Q2: 残骸 `~/.claude-emeradaco` を削除してよいか

実体は `~/.claude-emrd` (2.3G) に移行済み。旧パスは 8KB (`.claude.json` + `backups/`、2026-08-19 作成)
の空同然の残骸。参照していた `.dotfiles/config/idea-storage/config.ts` (gitignore 対象のローカル設定) は
`~/.claude-emrd` に修正済み。

- [ ] a: 削除してよい
- [ ] b: 残す (中身を確認したい)

### ER-Q3: `.dotfiles/config/cliproxyapi/config-emeradaco.yml` の扱い

dotfiles で **他セッションが現在編集中** (未コミット) のため今回は触っていない。
リネーム対象だが、衝突を避けるため担当を決めたい。

- [ ] a: 他セッションの作業が landed してから、こちらでリネームする
- [ ] b: 編集中のセッションに任せる (ccmsg で依頼)
- [ ] c: 今は据え置き

### ER-Q5: 手置き agent 2 件が setup.sh をブロックしている

`~/.claude-personal/agents/` に regular file で置かれた 2 件のせいで `setup.sh` が
「legacy *.md files exist」で停止し、**overlay リネーム後の symlink 張り替え
(`for-*-from-emeradaco` → `for-*-from-emrd`) が実行できない**。

対象: `sonnet5-worker-xhigh.md` / `codex-luna-reviewer-xhigh.md`
(いずれも description に「kawaz 明示指示 (2026-08-16, kuu 値カプセル設計のレビュー) で
臨時作成。常用しない」とある)

なお現状の symlink は互換 symlink (`claude-rules-emeradaco` → `claude-rules-emrd`) 経由で
解決できているため、**今すぐ壊れてはいない**。setup.sh を回すまで旧名のまま残るだけ。

- [ ] a: 2 件とも削除してよい (臨時作成・常用しない方針のため)
- [ ] b: claude-rules-personal の管理下 (plugin の agent 定義) に移してから削除
- [ ] c: 残す (setup.sh 側の legacy 判定を見直す)

## 確認待ち
