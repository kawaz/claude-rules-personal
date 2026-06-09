---
name: gh-image-attach
description: GitHub の issue / PR / discussion / release などのコメント・本文に **画像付き Markdown を投稿**する。`playwright-cli` + Chrome Beta token attach で GH の markdown editor を直接操作し、`drop --path` で `user-attachments` CDN にアップロード → 自動挿入された URL を `{{label}}` プレースホルダで本文に埋め込み → submit する。**`gh` CLI には画像添付の公式手段が無いため、画像を含むコメント/本文投稿はこのスキル経由が必須**。撮影スキル (`antenna-staging-e2e` 等) で作った画像をそのまま GH に貼る用途を想定。`PLAYWRIGHT_MCP_EXTENSION_TOKEN` 設定済み + 対象 GH の Chrome Beta profile (ログイン済) 起動中が前提。
---

# gh-image-attach

GitHub Web UI を `playwright-cli` で操作して **画像を user-attachments にアップロード → markdown に URL を埋め込み → コメント/本文投稿** までを一本道で実施するスキル。

## 1. 使うべき場面

- issue / PR / discussion / release の **コメント新規投稿** に画像を貼りたい
- 既存コメントを **編集** して画像を追加したい
- issue / PR / discussion 本文の **編集** に画像を追加したい
- 撮影スキル (`antenna-staging-e2e` 等) で取得したスクショを GH に貼る

`gh` CLI には画像添付の公式手段が無い。`user-attachments` upload は内部 endpoint で公開 API なし。**Web UI を playwright で叩く本スキルが唯一の実用経路**。

## 2. 起動前提条件 (必ず確認)

| 前提 | 確認方法 |
|------|---------|
| `PLAYWRIGHT_MCP_EXTENSION_TOKEN` env 設定済み | `echo $PLAYWRIGHT_MCP_EXTENSION_TOKEN` |
| 対象 GH org にログイン済みの Chrome Beta profile が起動中 | `pgrep -af 'Chrome Beta'` |
| 対象 profile が OS フォアグラウンド | attach 確立瞬間に Welcome タブが active 化する。kawaz が不在なら **`say`** で profile を前面化するよう依頼 |

ヘッドレス profile が無い / 拡張機能がブロックされている場合は `playwright-cli-chrome-beta-multi-profile` ルール末尾の代替経路 (`open --browser=chrome-beta --persistent --profile=...`) を参照。

## 3. CLI 契約 (このスキルへの入力)

呼び出し側 (Claude or kawaz) が以下を指定する:

| 引数 | 必須 | 説明 |
|------|------|------|
| `--url <url>` | yes | 投稿先の GH URL。コメント新規なら issue/PR/discussion の thread URL、編集なら `#issuecomment-NNN` 等のアンカー付き URL、本文編集なら issue/PR/discussion 本体 URL |
| `--image <path>[:<label>]` | yes (1+) | アップロードする画像。`<label>` 省略時は `{{label}}` 置換しないモード (末尾 append)。複数指定可 |
| `--body-file <path>` | no | Markdown 本文。`{{label}}` プレースホルダがあれば URL に置換。省略時は **画像 URL の `<img>` タグを順次 append したものを本文にする** |
| `--textarea <css>` | no | textarea 自動検出を上書き (デバッグ / 編集モード明示指定) |

呼び出し例:

```text
/personal-gh-image-attach \
  --url https://github.com/owner/repo/pull/123 \
  --image /tmp/before.png:before \
  --image /tmp/after-sp.png:after-sp \
  --image /tmp/after-pc.png:after-pc \
  --body-file /tmp/comment.md
```

`/tmp/comment.md`:

```markdown
動作確認結果。

| | Before | After |
|---|---|---|
| SP | ![before]({{before}}) | <img width="375" src="{{after-sp}}"> |

<details><summary>PC</summary><img src="{{after-pc}}"></details>
```

## 4. 実行フロー (一本道、止めない)

```
1. session 名決定: AB_SESSION="gh-image-attach-<repo>-<ts>" (kawaz の慣習に揃える)
2. attach: playwright-cli -s=$AB_SESSION attach --extension=chrome-beta
3. tab-new <url>: 対象 URL を開く
4. snapshot 取って textarea 確定 (§5 自動検出 eval)
5. drop --path で全画像を 1 ショット投入 (§6)
6. polling eval で「placeholder 消滅 + URL 件数一致」を待つ (§7、最大 60s)
7. URL 配列を取得 → body-file の {{label}} 置換 or 末尾 append (§8)
8. fill で textarea を完全書き換え (§9)
9. submit ボタン自動検出 → click (§10)
10. 投稿確認 (§11) — 失敗時は snapshot で原因観測
11. (optional) tab-close でゴミタブ掃除
```

**「止めるモード」は無い**。失敗したら Claude が次ターンで snapshot を見て対応 (edit で再投稿 / 別ファイルで再 drop / エラー読み取り)。

## 5. textarea 自動検出 (固定セレクタ禁止)

GH の markdown editor は文脈ごとに `name` / `id` が異なる:

| 文脈 | name | id pattern |
|------|------|-----------|
| 新規 issue body | `issue[body]` | `issue_body` |
| 新規 PR body | `pull_request[body]` | `pull_request_body` |
| 新規コメント (issue/PR/discussion) | `comment[body]` | `new_comment_field` |
| コメント編集 | `issue_comment[body]` | `issuecomment-{id}-body` |
| issue 本文編集 | `issue[body]` | `issue-{id}-body` |
| PR レビュー本文 | `pull_request_review[body]` | `pull_request_review_body` |
| PR レビューコメント (inline) | `pull_request_review_comment[body]` | `new_inline_comment_*` |
| Discussion 新規/編集 | `discussion[body]` | `discussion_body` |
| Release | `release[body]` | `release_body` |

固定セレクタは使わず、以下のヒューリスティック (優先順) を `eval` で実行して target を決める:

```js
// playwright-cli eval-page で実行、`window.__GH_IMG_TARGET` に保持
(() => {
  const userSelector = USER_SELECTOR;  // --textarea 引数。なければ null
  function find() {
    if (userSelector) {
      const el = document.querySelector(userSelector);
      if (el?.matches?.('textarea')) return el;
    }
    if (document.activeElement?.matches?.('textarea')) return document.activeElement;
    const visible = [...document.querySelectorAll('textarea')]
      .filter(t => t.offsetParent !== null && /body$|body\]$/.test(t.name || '') && !t.readOnly);
    if (visible.length === 1) return visible[0];
    const editing = visible.find(t => /^(issuecomment|comment|review|issue-\d|pull_request_review)-/.test(t.id));
    if (editing) return editing;
    return visible[0] || null;
  }
  const ta = find();
  if (!ta) throw new Error('no textarea found');
  window.__GH_IMG_TARGET = ta;
  ta.scrollIntoView({block: 'center'});
  ta.focus();
  return {id: ta.id, name: ta.name, tag: ta.tagName};
})()
```

編集モード起動が必要な場合 (`#issuecomment-NNN` URL でも textarea がまだ表示されてない) は、先に Edit ボタンを `snapshot` → `click` してから本 eval を回す。

## 6. drop --path で全画像 1 ショット投入

textarea が確定したら ref を取って drop:

```bash
playwright-cli -s=$AB_SESSION snapshot
# snapshot 結果から textarea の ref (例: e42) を読む
playwright-cli -s=$AB_SESSION drop @e42 \
  --path=/tmp/before.png \
  --path=/tmp/after-sp.png \
  --path=/tmp/after-pc.png
```

drop した順 = URL 配列の順番。

- 1 ショット内で複数 `--path` を **必ず順番通り**に並べる (--image 引数の順序と一致させる)
- ファイルが存在しない場合は drop 前にチェックして即エラー return (空の URL で fill しても害は無いが、polling timeout になるので無駄)

## 7. polling 待ち (中核 eval)

drop 完了後、placeholder 消滅 + URL 件数一致を `setInterval` で polling (`250ms` 間隔、`60s` timeout):

```js
// playwright-cli eval-page で実行、await 可
await new Promise((resolve, reject) => {
  const ta = window.__GH_IMG_TARGET;
  const EXPECTED = N;  // drop した画像枚数
  const URL_RE = /https:\/\/github\.com\/user-attachments\/assets\/[a-f0-9-]+/g;
  const PEND_RE = /\(Uploading [^)]*\)|attachments-spinner/;
  const t0 = Date.now();
  const iv = setInterval(() => {
    const v = ta.value;
    const urls = [...new Set(v.match(URL_RE) || [])];
    if (!PEND_RE.test(v) && urls.length >= EXPECTED) {
      clearInterval(iv);
      resolve({elapsed_ms: Date.now() - t0, urls, value: v});
    } else if (Date.now() - t0 > 60_000) {
      clearInterval(iv);
      reject(new Error(`timeout urls=${urls.length}/${EXPECTED} value=${v.slice(0,200)}`));
    }
  }, 250);
});
```

- 完了時 `urls` の **配列順序 = drop した順序**
- `new Set` で重複除去 (placeholder と URL が二重に並ぶ過渡期間がありうるため)
- `EXPECTED` 未達 / placeholder 残存のまま 60s 経過 → reject、snapshot で textarea 内容を確認して再 drop

## 8. URL → body 埋め込み

`--image <path>:<label>` で label が付与されている画像については、`--body-file` 内の `{{label}}` を URL で置換:

```text
--image /tmp/before.png:before
--image /tmp/after-sp.png:after-sp

# body-file 内
![before]({{before}})
<img width="375" src="{{after-sp}}">
```

label が無い画像 (= `:` 区切り無し) の URL は、`--body-file` の末尾に `<img src="<url>">` で順次 append。

`--body-file` 自体省略時:

```markdown
<img src="<url1>">
<img src="<url2>">
```

を本文にする (label 無しと同等)。

## 9. fill で textarea 完全書き換え

embedded markdown が確定したら playwright `fill` で textarea を上書き:

```bash
playwright-cli -s=$AB_SESSION fill @e42 "$(cat /tmp/comment-embedded.md)"
```

- React state が同期される (playwright fill が input event を発火、実証済み)
- embedded body は一時ファイルに書き出してから `fill "$(<file)"` が安全 (shell quoting 事故を避ける)

## 10. submit ボタン自動検出

submit ボタン名も文脈で変わる:

| 文脈 | ボタン名 |
|------|----------|
| 新規コメント (issue/PR/discussion) | Comment |
| コメント編集 | Update comment |
| 新規 issue | Submit new issue |
| issue 本文編集 | Update comment |
| PR 本文編集 | Update comment |
| Discussion 新規 | Comment |
| Release | Publish release / Save draft |

`eval` で `textarea.closest('form')` 内から submit ボタンを探す:

```js
(() => {
  const ta = window.__GH_IMG_TARGET;
  const form = ta.closest('form');
  if (!form) throw new Error('no form');
  const buttons = [...form.querySelectorAll('button[type=submit]:not([disabled])')]
    .filter(b => b.offsetParent !== null);
  if (!buttons.length) throw new Error('no visible submit');
  if (buttons.length === 1) {
    buttons[0].scrollIntoView({block: 'center'});
    return {label: buttons[0].textContent.trim(), id: buttons[0].id};
  }
  const primary = buttons.find(b => /comment|update|submit|publish|create|save/i.test(
    b.textContent + ' ' + (b.getAttribute('aria-label') || '')
  )) || buttons[buttons.length - 1];
  primary.scrollIntoView({block: 'center'});
  primary.setAttribute('data-gh-img-submit', '1');
  return {label: primary.textContent.trim(), id: primary.id};
})()
```

click は snapshot 取り直して ref で `click @eN`、または `eval` で `document.querySelector('[data-gh-img-submit]').click()` を直接実行。

## 11. 投稿確認

submit click 後、`gh` CLI で投稿が成立したか裏取りする:

```bash
# 新規コメントの場合 (URL から issue/PR 番号を抽出)
gh issue view N --repo owner/repo --json comments \
  | jq -r '.comments[-1].body' \
  | grep -F 'user-attachments/assets'  # URL が含まれていれば成功

# コメント編集の場合 (#issuecomment-NNN)
gh api repos/owner/repo/issues/comments/NNN --jq .body | grep -F 'user-attachments'

# issue 本文編集
gh issue view N --repo owner/repo --json body --jq .body | grep -F 'user-attachments'
```

成功時は投稿/編集された URL を呼び出し側に返す。失敗時 (form が閉じてない、エラーメッセージ表示) は snapshot を残して呼び出し側に通知。

## 12. 失敗時の挙動 (止めない、AI が観測して動く)

| 失敗 | AI が次ターンで打つ手 |
|------|---------------------|
| polling timeout (画像が URL に変わらない) | snapshot で textarea 内容確認、再 drop or 別ファイルで再試行 |
| submit click 後に form がまだ open | snapshot でエラーメッセージ読む (ログイン切れ / textarea 空 / size 超過) |
| 投稿成功したが URL 埋め込みが意図と違う | edit モードで `--url <#issuecomment-NNN>` で再実行 (= スキル re-entrant) |
| upload 失敗 (CDN エラー) | snapshot 確認 → 画像リサイズ / 圧縮して再 drop |

スキル本体には retry ロジックを持たせない。Claude が次ターンで判断する方が柔軟。

## 13. 後始末

```bash
# Playwright "タブグループ" 内の作業タブを全部閉じる
playwright-cli -s=$AB_SESSION tab-close <タブインデックス>
# (Welcome connect.html も同様に閉じてグループ消滅 → セッション自然終了でよい)
```

`tab-close` で掃除しないとブラウザにゴミタブが残る。

## 14. URL の永続性 (再利用可能)

upload 後の `https://github.com/user-attachments/assets/<uuid>` URL は **時間軸を超えて再利用可能** (実証済: 2026-06-09 06:01 取得 SP URL を 07:17 編集で再利用成功)。

- 一度 upload した URL は、別コメント / 別 issue / 編集再投稿で **再 upload せず本文に書くだけで画像表示される**
- 「ちょっとだけ本文を書き換えたい」「別 PR で同じスクショを使い回したい」場合、本スキルを呼ぶ必要なく `gh issue edit` / `gh pr comment --edit-last` 等で URL リテラルを書き換えるだけで済む

## 15. 関連スキル / ルール

- **撮影源**: `personal-agent-browser-session-isolation` (session 命名規約) / `personal-playwright-cli-chrome-beta-multi-profile` (Chrome Beta token attach 経路) / 各業務 overlay の `antenna-staging-e2e` 等
- **session 命名**: `<タスク種別>-<issue/PR番号>-<担当>` (本スキルは `gh-image-attach-<repo>-<ts>` で慣習化)
- **越境作業時**: `claude-config-dir-isolation` 準拠でサブシェル化 + 対象環境の Chrome profile を使用

## 16. スコープ外 (out of scope)

- gif / 動画 (.mp4 等) — GH は対応するが本スキル v1 は画像のみ
- 画像の事前リサイズ / 圧縮 — 呼び出し側で処理してから渡す
- マスキング (機微情報黒塗り等) — 撮影スキル側で対応
- 既存コメント編集時の差分マージ — 常に完全書き換え
- バッチ投稿 (複数 PR/issue にまとめて) — 呼び出し側でループ
