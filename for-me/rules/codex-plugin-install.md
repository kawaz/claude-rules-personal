# Codex plugin (openai/codex-plugin-cc) のインストール

Claude Code に **OpenAI 公式 codex plugin** を入れる手順。`plan-review-with-codex.md` で前提とする。

## 導入手順 (= 新環境 / 再現用)

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

`/codex:setup` が `ready: true` を返せば導入完了。`loggedIn: false` なら ChatGPT 認証案内に従う (= `codex login` を `!codex login` で session 内実行)。

## review gate (任意)

stop 時に直近 diff を codex に通す「review gate」を有効化する場合:

```
/codex:setup --enable-review-gate
```

挙動: stop 前に同期 blocking で codex review が走る。長時間 task で毎回走ると体感悪化するので、合わなければ:

```
/codex:setup --disable-review-gate
```

で戻す。

## auth 境界 (= 業務 vs 個人)

`/codex:setup` の `auth.detail` に「どの ChatGPT アカウントで login 中か」が出る。

- 個人プロジェクトでは個人 ChatGPT を使うのが原則
- 業務面 (`~/.claude-emeradaco` 等) では業務 ChatGPT を使う
- **逆方向 (= 個人作業で業務認証経由)** は許容判断 (= 個人 OSS の作業情報が業務 codex ログに残るのは公開情報なので非対称評価で許容)
- **業務作業で個人認証経由は禁止** (= 業務機密が個人面に流出するリスク)

切り替えが必要なら `codex logout` → `codex login`。

## 提供される主な slash command

| command | 用途 |
|---|---|
| `/codex:setup` | 動作確認 / review gate 切替 |
| `/codex:review` | local git changes に対する code review (= 瑣末フィルタ済 contract 組込み) |
| `/codex:adversarial-review` | 設計判断・アプローチを挑戦するレビュー (= focus text 渡せる) |
| `/codex:rescue` | 任意 doc / 任意 task の investigation / fix / follow-up |
| `/codex:status` | 実行中 codex task の status |
| `/codex:result` | 完了 task の結果取得 |
| `/codex:cancel` | task キャンセル |

各 command は `--wait` (foreground 同期) / `--background` (Claude background task) で実行モード制御可能。

## jj 環境での注意

codex plugin の review 系 command は **git 経路で diff を取る**。`.jj` 管理リポでも `.git/` への jj git export が走っていれば動作する。

problem 起きた場合の fallback:
- `jj git export` で git view を強制更新
- それでも駄目なら `/codex:rescue --wait <path>` で path 直接指定経路に切り替え

## 関連

- [[plan-review-with-codex]] — codex を使った plan / 設計 doc レビュー運用
- 公式 repo: https://github.com/openai/codex-plugin-cc
