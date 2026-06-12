---
name: gh-image-attach
description: GitHub の issue / PR / discussion / release などのコメント・本文に **画像付き Markdown を投稿**する。`playwright-cli` + Chrome Beta token attach で GH の markdown editor を直接操作し、`drop --path` で `user-attachments` CDN にアップロード → 自動挿入された URL を `{{label}}` プレースホルダで本文に埋め込み → submit する。**`gh` CLI には画像添付の公式手段が無いため、画像を含むコメント/本文投稿はこのスキル経由が必須**。撮影スキル (`antenna-staging-e2e` 等) で作った画像をそのまま GH に貼る用途を想定。`PLAYWRIGHT_MCP_EXTENSION_TOKEN` 設定済み + 対象 GH の Chrome Beta profile (ログイン済) 起動中が前提。
---

# gh-image-attach

GitHub Web UI を `playwright-cli` で操作し、画像を `user-attachments` にアップロード →
markdown に URL 埋め込み → コメント/本文投稿するスキル。

**重い手順 (browser 自動化 + 巨大 snapshot 処理 + 新旧 UI eval) はサブエージェントに
隔離**し、メインコンテキストを汚さない。メインがやるのは「preflight 確認」と「INPUT を
組んで spawn」「OUTPUT を受け取る」だけ。

## 使う場面

- issue / PR / discussion / release の **コメント新規投稿 / 編集**に画像を貼る
- issue / PR / discussion **本文の編集**に画像を追加
- 撮影スキル (`antenna-staging-e2e` 等) のスクショを GH に貼る

`gh` CLI に画像添付の公式手段は無い。`user-attachments` upload は内部 endpoint で公開
API なし。**Web UI を playwright で叩く本スキルが唯一の実用経路**。

## INPUT 契約 (呼び出し側が決める)

| 項目 | 必須 | 説明 |
|------|------|------|
| url | yes | 投稿先 GH URL。新規=thread URL、編集=`#issuecomment-NNN` 等、本文編集=本体 URL |
| images | yes (1+) | `path[:label]` のリスト。label 付きは body の `{{label}}` を URL 置換、無印は末尾 append |
| body-file | no | Markdown 本文。`{{label}}` を URL 置換。省略時は `<img>` を順次 append した本文を生成 |
| textarea | no | textarea セレクタ上書き (デバッグ / 編集モード明示) |

## preflight (メインが委譲前に確認 — 対話が要るのはここだけ)

サブエージェントは `say` / AskUserQuestion を打てない。対話が要る前提条件は**メインで解消**してから委譲する:

1. `echo "$PLAYWRIGHT_MCP_EXTENSION_TOKEN"` が空でない (env 継承される)
2. 対象 GH にログイン済みの Chrome Beta profile が起動中 (`pgrep -af 'Chrome Beta'`)
3. attach 瞬間に profile が前面化する。kawaz 不在で profile が背面なら `say` で前面化依頼 (→ `say-command-katakana`)

満たせなければメインで解消 (必要なら AskUserQuestion)。満たせたら委譲する。
ヘッドレス profile が無い / 拡張ブロック時は `playwright-cli-chrome-beta-multi-profile` 末尾の代替経路を参照。

## 委譲 (heavy 手順はサブエージェントに閉じる)

preflight OK なら **サブエージェントを spawn** し、手順書のパスと INPUT を渡す。
サブエージェントへの prompt には **必ず `CLAUDE_SKILL_DIR` を絶対パスで渡す**
(= サブエージェント側では template 展開されないため、メインが組み立てる時点で
embed する。→ `skill-template-vars-transitivity` ルール):

> CLAUDE_SKILL_DIR=${CLAUDE_SKILL_DIR}
>
> 上記 SKILL_DIR 配下の `instruction.md` に従って処理してください。
>
> INPUT:
> ```
> url: <url>
> images:
> 1 <path>[:<label>]
> 2 <path>[:<label>]
> body-file: <path or "(none)">
> textarea: <css or "(auto)">
> ```

サブエージェントは手順書通り attach → drop → poll → fill → submit → 確認 を
**失敗時の観測リトライ込み**で完遂し、以下 OUTPUT だけ返す:

```
OUTPUT:
posted: <投稿/編集された URL>        (失敗時は failed: <観測した状態 + メインへの依頼>)
1 <label> <user-attachments URL>
2 <label> <user-attachments URL>
```

返ってきた `user-attachments` URL は **時間軸を超えて再利用可能**。別投稿で再 upload
不要、`gh ... edit` 等で URL リテラルを書くだけで表示される。失敗が `failed:` で
返ったら、対話 (ログイン切れ / profile 前面化等) をメインで解消して再委譲する。

## 安全側ガード (サブエージェント側で実装済)

submit ボタン検出は **3 段ガード**で破壊系/離脱系の誤クリックを構造的に防止する
(2026-06-11 PR#2388 事故からの learning。詳細は `instruction.md` §9):

1. **REJECT_RE**: `close, delete, cancel, discard, dismiss, reset, reject, remove,
   unsubscribe, lock, transfer, convert, archive` を含むボタンを候補から除外
2. **SUBMIT_RE**: `Comment / Update comment / Submit new issue / Create / Publish /
   Save draft / Submit review` 等の **完全一致 allowlist** で primary を選ぶ
3. **disabled wait + fallback 禁止**: 期待ボタンが disabled なら最大 ~5s wait。
   見つからなければ fallback で他ボタンを選ばず明示エラー = `failed:` で返す

万一サブエージェントが投稿後に副作用 (`Close with comment` の誤踏み等) を観測したら、
**コメント自体は成功している可能性が高い** ので `posted:` + 副作用注記で返す。
メインは `gh pr reopen N` 等で復旧した上で、user-attachments URL を捨てない。

## スコープ外

gif / 動画 / 事前リサイズ・圧縮 / マスキング / 差分マージ / バッチ投稿 → 呼び出し側で処理。

## 関連スキル / ルール

- **撮影源 / attach 経路**: `personal-agent-browser-session-isolation` (session 命名) / `personal-playwright-cli-chrome-beta-multi-profile` (Chrome Beta token attach) / 各業務 overlay の `antenna-staging-e2e` 等
- **越境作業時**: `claude-config-dir-isolation` 準拠でサブシェル化 + 対象環境の Chrome profile を使用
- **詳細手順**: 同ディレクトリ `instruction.md` (サブエージェントが読む)
