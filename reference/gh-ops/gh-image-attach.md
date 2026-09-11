# GitHub に画像付きで投稿する

`gh` の `--attach` (v2.99.0 以降、2026-09-01 GA) で画像 / 動画を `user-attachments` にアップロードし、issue / PR の本文・コメントに埋め込む。browser 自動化は不要になった (playwright 経路は `--attach` が使えない場面の fallback として `instruction.md` に残す)。

## 使う場面

- issue / PR の **作成 / 本文編集 / コメント**に画像を貼る (`gh issue create|edit|comment`、`gh pr create|edit|comment`)
- 業務リポの撮影手順等で撮ったスクショを GH に貼る

## 前提

- `gh --version` が **2.99.0 以上**。nixpkgs の gh は遅れるので、足りなければ release の zip を取って使う:

```bash
V=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["tag_name"])')
curl -fsSL -o /tmp/gh-latest.zip "https://github.com/cli/cli/releases/download/${V}/gh_${V#v}_macOS_arm64.zip"
mkdir -p /tmp/gh-latest && unzip -qo /tmp/gh-latest.zip -d /tmp/gh-latest
GH=$(find /tmp/gh-latest -type f -name gh -path '*/bin/*' | head -1)   # 以降 $GH で呼ぶ
```

- 認証は通常の gh と同じ (`GH_CONFIG_DIR` / direnv の切替がそのまま効く)。Actions の `GITHUB_TOKEN` では `--attach` が拒否される
- 対象リポへの push 権限が要る (read-only リポは不可)
- 対応拡張子は画像 / 動画の 9 種のみ (PDF / zip / log は不可 → 別手段)

## 手順

1. 本文 Markdown を用意する。画像は **ローカルパスで `![alt](./shot.png)` と書く** (投稿時に `user-attachments` URL へ書き換えられ、本文の alt が保持される)。本文で参照しない `--attach` は末尾に append される
2. 画像ファイルのあるディレクトリで実行する (本文の相対パスと `--attach` のパスを一致させる):

```bash
cd <画像のあるディレクトリ>
$GH issue comment <N> --repo <owner>/<repo> --body-file body.md --attach './shot.png#alt テキスト'
# 複数: --attach ./before.png --attach ./after.png
# 本文編集: $GH issue edit <N> --body-file body.md --attach ./shot.png
# PR も同様: $GH pr comment / pr create / pr edit
```

`#alt` を省くとファイル名が alt になる (本文に既に alt があればそちらが優先)。動画は alt 不可。

3. 投稿結果の本文を API で読んで URL 書き換えを確認する:

```bash
gh api repos/<owner>/<repo>/issues/comments/<comment_id> --jq .body
```

返ってきた `user-attachments` URL は再利用可能 (別投稿で再 upload 不要、URL リテラルを書けば表示される)。

## 実測 (2026-09-11)

gh 2.100.0 / `gh issue comment 3051 --body-file body.md --attach './shot.png#alt'` で、本文の `![Slack キャプチャ](./shot.png)` が `![Slack キャプチャ](https://github.com/user-attachments/assets/<uuid>)` に書き換わり投稿された。所要数秒、対話なし。

## fallback (playwright 経路)

`--attach` が使えない場合 (gh を更新できない / 非対応ファイル種別 / discussion・release への投稿) のみ、`instruction.md` の browser 自動化手順をサブエージェントに委譲する。preflight (`PLAYWRIGHT_MCP_EXTENSION_TOKEN` / 対象 GH にログイン済み Chrome Beta profile / profile 前面化) はメインで解消してから委譲する。

## スコープ外

gif の変換 / 事前リサイズ・圧縮 / マスキング / バッチ投稿 → 呼び出し側で処理。

取得側は reference の `gh-ops/gh-image-fetch`。
