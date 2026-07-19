---
name: playwright-cli-chrome-beta-multi-profile
description: playwright-cli を業務用 Chrome Beta の複数プロファイルで attach して自動化する時に読む。共通セットアップ・token 取得・セッション運用・トラブルシュートを扱う。各業務 overlay の `playwright-cli-<env>-profile` から参照される共通手順。playwright-cli を使わない作業では不要。
---

# playwright-cli × Chrome Beta マルチプロファイル運用

playwright-cli (`@playwright/cli`) で **業務用 Chrome Beta の複数プロファイルを使い分け** ながら自動化する手順。
**Playwright Extension + `PLAYWRIGHT_MCP_EXTENSION_TOKEN`** 経路を採用 (業務 Chrome の cookie / ログイン状態 / 拡張機能をそのまま使える)。

## 前提

- Chrome Beta (Chrome 144 以降)
- playwright-cli (`@playwright/cli` v0.1.13+)
  - インストール: `bun i -g @playwright/cli` または `npm i -g @playwright/cli@latest`

## セットアップ (各プロファイルで初回 1 回)

### 1. Chrome 拡張機能をインストール

業務 Chrome Beta の対象プロファイルで Chrome Web Store を開いて Playwright Extension (Microsoft 公式) をインストール:

```
https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm
```

拡張機能は Chrome プロファイル単位のため、**使いたいプロファイルそれぞれでインストール** が必要。

### 2. token を取得

拡張機能の status ページを開く:

```
chrome-extension://mmlmfjhmonkocbjadbfplnigmagldckm/status.html
```

表示される `PLAYWRIGHT_MCP_EXTENSION_TOKEN=<value>` の値を控える。

token の特性:
- **プロファイル固有** (= プロファイルごとに別の値)
- **永続** (Chrome 再起動後も同じ値を使い続けられる)
- status.html の **リフレッシュボタンを押すと再生成** される (= 旧 token は無効化)。誤って漏らした場合の rotate 手段として使う

> **token は秘密情報**。これを知る = そのプロファイルの Chrome を完全に制御可能 (cookie 抽出、ログイン状態の悪用、画面操作)。コミット対象ファイル・公開ログ・チャット履歴に値を残さない。1Password 等の保管庫に置くか、gitignore された `.envrc` で direnv 経由に限定する。

### 3. attach

```bash
export PLAYWRIGHT_MCP_EXTENSION_TOKEN='<value>'
playwright-cli -s=<session-name> attach --extension=chrome-beta
```

成功時:
- 業務 Chrome 内に Playwright Extension の "Welcome" タブ (connect.html) が新規で開く
- 拡張機能 UI に `connected` 表示 (cosmetic bug で `"unknown" connected.` と出る場合あり、機能影響なし)
- `playwright-cli list` で `status: open, browser-type: chrome-beta (attached)`

## 日常運用

### attach 確立後の操作

`-s=<session-name>` プレフィックスで操作。業務 Chrome の cookie / 拡張機能 / セッション継承:

```bash
playwright-cli -s=<sn> tab-new https://example.com/   # 操作したいページは新規タブで開く
playwright-cli -s=<sn> snapshot
playwright-cli -s=<sn> click e15
playwright-cli -s=<sn> requests                       # ネットワーク観測
playwright-cli -s=<sn> request-body 5
```

既存タブ (kawaz が日常使いしているタブ) は `tab-list` に出てこない別管理。playwright で触りたいページは `tab-new` で開く。

### バックグラウンド実行 (ユーザの作業を邪魔しない)

playwright-cli が操作するタブは **バックグラウンドのままでよい**。Playwright が操作対象ページを `visible` / `focused` とエミュレートするため、ユーザの実画面 (フォーカス中のタブ/ウィンドウ/アプリ) は奪われず、かつバックグラウンドタブのタイマースロットリングも回避される。

例外は **attach 確立の瞬間**: Playwright Extension が接続タブ (connect.html) を `active: true`・ウィンドウを `focused: true` にするのがハードコードされており (`background.mjs`)、抑制オプションは無い。接続確立時に 1 回だけ画面が前面化する (= 接続をユーザに気づかせる意図的設計)。以降の通常操作はフォーカスを奪わない。

→ ユーザが別作業中に裏で自動化を走らせる用途には使えるが、**自動化「開始」の瞬間だけは画面が 1 回奪われる**前提で設計する (開始タイミングを選ぶ等)。`tab-new` での新規タブも同様に手前に出る。

### セッション命名 (複数プロファイル並列)

`<タスク種別>-<issue/PR番号>-<担当>` 形式 (例: `survey-1234-kawazu`, `fix-1234-kawazu`)。
複数 Claude エージェントが同一ホストで default session を共有して操作競合 / snapshot ref 破棄 / Cookie リセットを起こす事故を防ぐため、`-s=<name>` を必ず明示する。

並列運用例 (環境変数 = プロファイルごとに別 token):

```bash
PLAYWRIGHT_MCP_EXTENSION_TOKEN=$TOKEN_A playwright-cli -s=task-A attach --extension=chrome-beta
PLAYWRIGHT_MCP_EXTENSION_TOKEN=$TOKEN_B playwright-cli -s=task-B attach --extension=chrome-beta
```

token + 拡張機能が紐づくプロファイルが、繋がる先を決定する。

### close とタブの後始末

```bash
playwright-cli -s=<sn> close      # 1 セッション
playwright-cli close-all          # 全セッション
playwright-cli kill-all           # daemon 含め強制終了
```

**`--extension` 経路では `close` してもタブは閉じない** — Chrome の "Playwright" タブグループが解散されるだけで、開いたタブ (`tab-new` で開いたもの + connect.html) はグループ無しの状態で残る。

同様に、**別 ID で新規セッションを attach して旧セッションが切断される場合も**、旧グループは解散されるだけで旧タブはグループ無しで残る (新セッションは新 Welcome だけの新グループを作る)。`close` でも新規 attach でも、旧タブのゴミは残る。

→ 大量のタブを開くフローでは、**セッション終了前に `tab-close` で開いたタブを掃除する**。でないとユーザのブラウザにゴミタブが散らばる。connect.html (Welcome) タブも残るが、attach 切断後は無効ページなので一緒に閉じてよい。

### タブグループによる可視範囲制御

`--extension` 経路で playwright が見える/操作できるのは **Chrome の "Playwright" タブグループに属するタブのみ**。

- `tab-new` で開いたタブは自動でグループに入る
- ユーザが手動で**別のタブをグループにドラッグ参加させると、それも playwright の管理対象になる** (= 既存の閲覧中ページを選択的に playwright に見せられる)
- グループ外のタブは `tab-list` に出ず、操作もできない
- 逆にタブをグループから外せば playwright の管理対象から外れる

## トラブルシューティング

### connect.html (Welcome) タブとセッションの寿命

attach 時に開く connect.html (Welcome) タブは **"Playwright" タブグループのアンカー**。

- グループに他のタブがあれば connect.html を閉じてもセッションは**継続**する
- グループ内のタブが 0 になるとグループが消滅し、セッションが**切断**される (Chrome のタブグループ最低 1 タブ仕様)
- → セッションを保つにはグループ内に最低 1 タブを維持する。切断されたら再 attach で復旧
- セッションをきれいに終わらせたいときは「全タブを `tab-close` → 最後の 1 タブを閉じた時点でグループ消滅・セッション終了」。ゴミタブも残らない

### "Allow remote debugging" チェックボックスとの関係

`chrome://inspect/#remote-debugging` の「Allow remote debugging for this browser instance」は **別経路** (`attach --cdp=chrome-beta` 用)。本ルートでは不要なので **OFF が望ましい** (攻撃面を増やさない)。

### Playwright Extension がインストールできない (拡張機能ポリシー)

業務 Workspace の組織ポリシーで拡張機能インストールがブロックされている場合は、**別経路 (`open --browser=chrome-beta --persistent --profile=<path>`)** を使う:

```bash
mkdir -p /var/tmp/pwcli-profiles/<name>
playwright-cli -s=<name> open --browser=chrome-beta \
  --persistent --profile=/var/tmp/pwcli-profiles/<name> \
  --headed <url>
```

ただし業務 Chrome の cookie / 拡張機能 / テーマは引き継げないので、各サービスへの初回ログインからやり直しになる。

## 関連

- 各 overlay の `playwright-cli-*-profile.md` — 各業務プロファイルの token 保管・固有運用
