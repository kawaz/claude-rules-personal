# gh-image-attach 手順書 (サブエージェント用)

このファイルは **gh-image-attach スキルのサブエージェント**が読む詳細手順書。
メインの `SKILL.md` から spawn され、下記 INPUT を受け取り、browser 自動化
(attach → drop → poll → fill → submit → 確認) を **失敗時の観測リトライ込み**で
完遂し、OUTPUT だけを返す。メインとの対話 (AskUserQuestion 等) はできない前提で、
止まらず最後までやり切ること。

## INPUT (spawn 時にメインから渡される)

```
url: <投稿先 GH URL>
images:
1 <path>[:<label>]
2 <path>[:<label>]
  :
body-file: <path or "(none)">
textarea: <css selector or "(auto)">
```

- `<label>` 付き画像 = body 内 `{{label}}` を URL 置換する対象
- `<label>` 無し画像 = 本文末尾に `<img src="URL">` で順次 append
- `body-file` が `(none)` = 全画像を `<img src="URL">` 羅列した本文を生成

## OUTPUT (メインに返す唯一の成果物)

成功時:
```
OUTPUT:
posted: <投稿/編集された URL (例: .../pull/123#issuecomment-456)>
1 <label> <user-attachments URL>
2 <label> <user-attachments URL>
  :
```

失敗時:
```
OUTPUT:
failed: <観測した状態 + メインに依頼したい次の一手>
(取得済みなら) user-attachments URL も列挙して返す (再利用のため捨てない)
```

> user-attachments URL は **時間軸を超えて再利用可能** (§URL 永続性)。途中まで
> upload が通っていれば、失敗時でも URL を返せばメインが `gh ... --edit` 等で使える。

---

## 0. eval の実行形式 (重要・前回ハマった)

`playwright-cli eval` に **`--file` オプションは無い** (`Unknown option` になる)。
巨大 JS は一時ファイルに書き、`cat` でシェル展開して **1 引数**として渡す:

```bash
# NG: playwright-cli eval --file=/tmp/x.js   ← 存在しないオプション
# OK:
cat > /tmp/gh-find.js <<'JS'
( ... JS 本体 ... )
JS
playwright-cli -s="$AB" eval "$(cat /tmp/gh-find.js)"
```

`--filename` は別物 (結果出力先指定) なので混同しない。
最初に `echo "$PLAYWRIGHT_MCP_EXTENSION_TOKEN"` で env を確認し、空なら即 `failed:` 返す。

## 1. session 名決定 (socket path 上限に注意・前回ハマった)

`playwright-cli` の session は Unix domain socket
(`/var/folders/.../T/pw-xxx/cli/<hash>-<name>.sock`) を作る。macOS の socket path
上限 (~104 chars) を超えると `EINVAL: invalid argument ... .sock` で attach 失敗する。

- **session 名は短く (~10 chars 以内)**。`gh-image-attach-<repo>-<ts>` 形式は超過する。
- 推奨: `AB="ghimg<repo略>"` (例: `ghimg2350`)。repo 略称 + PR/issue 番号程度。

```bash
AB="ghimg<短い識別子>"   # 例: ghimg2350
```

## 2. attach

```bash
playwright-cli -s="$AB" attach --extension=chrome-beta
```

attach 瞬間に Welcome タブが active 化する (仕様)。preflight はメインが済ませている前提。
失敗 (EINVAL / token 不正 / profile 不在) なら `failed:` でメインに返す。

## 3. 対象 URL を開く

```bash
playwright-cli -s="$AB" tab-new "<url>"
```

編集モード (`#issuecomment-NNN` 等) で textarea がまだ無い場合は、先に snapshot →
Edit ボタンを click してから §4 に進む。

## 4. textarea 自動検出 (固定セレクタ禁止、新旧 UI 両対応)

GH の markdown editor は文脈・UI 世代で `name`/`id`/構造が違う。

**旧 UI** (`<form>` ベース、name 属性で識別):

| 文脈 | name | id pattern |
|------|------|-----------|
| 新規 issue body | `issue[body]` | `issue_body` |
| 新規 PR body | `pull_request[body]` | `pull_request_body` |
| 新規コメント | `comment[body]` | `new_comment_field` |
| コメント編集 | `issue_comment[body]` | `issuecomment-{id}-body` |
| issue 本文編集 | `issue[body]` | `issue-{id}-body` |
| PR レビュー本文 | `pull_request_review[body]` | `pull_request_review_body` |
| PR レビューコメント | `pull_request_review_comment[body]` | `new_inline_comment_*` |
| Discussion 新規/編集 | `discussion[body]` | `discussion_body` |
| Release | `release[body]` | `release_body` |

**新 UI** (React 化、2026-06 時点で issue/PR コメント新規 UI が切替済):
- `name=""`、`id="_r_9i_"` 等の React 動的 ID
- `<form>` でなく `<div data-testid="comment-composer">` 等でラップ
- `placeholder="Use Markdown to format your comment"` で識別可

固定セレクタは使わず、新旧両対応ヒューリスティック (優先順) を eval で実行。
**submit 後に React が textarea を再生成するため、本 eval は drop 直前と URL 抽出時の
双方で毎回呼び直す** (キャッシュ参照は無効化されうる):

```js
// USER_SELECTOR は textarea 引数。(auto) なら null に置換
(() => {
  const userSelector = USER_SELECTOR;
  function find() {
    if (userSelector) {
      const el = document.querySelector(userSelector);
      if (el?.matches?.('textarea')) return el;
    }
    if (document.activeElement?.matches?.('textarea')) return document.activeElement;
    const candidates = [...document.querySelectorAll('textarea')]
      .filter(t => t.offsetParent !== null && !t.readOnly);
    let v = candidates.filter(t => {
      const wrap = t.closest('[data-testid]');
      const tid = wrap?.dataset?.testid || '';
      return /composer|comment-body|issue-body|pull_request_body|discussion/i.test(tid);
    });
    if (v.length === 1) return v[0];
    v = candidates.filter(t => /body$|body\]$/.test(t.name || ''));
    if (v.length === 1) return v[0];
    const editing = candidates.find(t => /^(issuecomment|comment|review|issue-\d|pull_request_review)-/.test(t.id));
    if (editing) return editing;
    const md = candidates.find(t => /markdown/i.test(t.placeholder || ''));
    if (md) return md;
    return candidates[0] || null;
  }
  const ta = find();
  if (!ta) throw new Error('no textarea found');
  window.__GH_IMG_TARGET = ta;
  ta.scrollIntoView({block: 'center'});
  ta.focus();
  return {id: ta.id, name: ta.name, tag: ta.tagName, placeholder: ta.placeholder};
})()
```

## 5. drop --path で全画像 1 ショット投入

textarea 確定後 snapshot で ref を取って drop。drop target は **textarea 自身**
(新旧 UI とも実証)。

**snapshot から textarea ref を拾うコツ (前回ハマった・出力が 3000+ ref で巨大)**:
コンテナの accessible name で絞ると一発:

```bash
playwright-cli -s="$AB" snapshot | grep -A 50 'form "Add a comment"'      # 旧 UI
playwright-cli -s="$AB" snapshot | grep -A 30 'data-testid="comment-composer"'  # 新 UI
```

```bash
# ref はそのまま渡す (eN を eN として、@ プレフィックス不要)
playwright-cli -s="$AB" drop e524 \
  --path=/tmp/before.png \
  --path=/tmp/after-sp.png \
  --path=/tmp/after-pc.png
```

- 1 ショット内で複数 `--path` を **必ず INPUT の images 順**に並べる (drop 順 = URL 順)
- ファイル不在は drop 前にチェックして即 `failed:` 返す
- **新 UI 注意**: drop で挿入される文字列は markdown `![](URL)` ではなく HTML
  `<img width=".." height=".." alt="Image" src="URL">`。URL 抽出 (§6) はどちらでも
  引っかかるが、`{{label}}` 置換のため **URL リストだけ取得して body を完全書き換え**
  する方針が安定 (= §7/§8 と整合)

## 6. polling 待ち (中核 eval)

drop 完了後、placeholder 消滅 + URL 件数一致を `setInterval` で polling
(250ms 間隔、60s timeout)。**polling 開始前に composer から textarea を再取得**
(`__GH_IMG_TARGET` が古い参照を握る事故を防ぐ):

```js
await new Promise((resolve, reject) => {
  const composer = document.querySelector('[data-testid=comment-composer]');
  const ta = composer?.querySelector('textarea') || window.__GH_IMG_TARGET;
  window.__GH_IMG_TARGET = ta;
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
- `new Set` で重複除去 (placeholder と URL が二重に並ぶ過渡期間があるため)
- timeout したら `__GH_IMG_TARGET` の古い参照を最初に疑い、
  `document.querySelector('[data-testid=comment-composer] textarea')` で取り直して再 polling
- **より堅牢な label↔URL 対応 (任意)**: drop 挿入文字列の `<img alt="...">` には
  ファイル名が入る。配列順だけに頼らず、`v.match(/<img[^>]*alt="([^"]+)"[^>]*src="([^"]+)"/g)`
  で alt→URL の map を作ると順序ズレに強い。新 UI でも `<img alt="...">` 形式で挿入される

## 7. URL → body 埋め込み

`<label>` 付き画像は body-file 内 `{{label}}` を URL 置換:

```text
# images: /tmp/before.png:before, /tmp/after-sp.png:after-sp
# body-file 内:
![before]({{before}})
<img width="375" src="{{after-sp}}">
```

`<label>` 無し画像の URL は body 末尾に `<img src="<url>">` を順次 append。
`body-file` が `(none)` の場合は:

```markdown
<img src="<url1>">
<img src="<url2>">
```

を本文にする。

## 8. fill で textarea 完全書き換え (React state 同期必須)

playwright `fill` だけでは新 UI の React state が更新されないことがある。
**native value setter 経由で `input` event を dispatch する eval が確実**:

```js
(() => {
  const composer = document.querySelector('[data-testid=comment-composer]');
  const ta = composer?.querySelector('textarea') || window.__GH_IMG_TARGET;
  const body = BODY_STRING;  // §7 で組み立てた本文
  const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
  setter.call(ta, body);
  ta.dispatchEvent(new Event('input', {bubbles: true}));
  return {len: ta.value.length};
})()
```

- これで submit ボタンが enabled になる (React state 同期)
- 本文は一時ファイルに書き出してから JS 文字列リテラルに埋め込む (shell quoting 事故回避)

## 9. submit ボタン自動検出 (新旧 UI 両対応 + 危険ボタン除外 + wait)

submit ボタン名は文脈で変わる:

| 文脈 | ボタン名 |
|------|----------|
| 新規コメント | Comment |
| コメント編集 | Update comment |
| 新規 issue | Submit new issue |
| issue/PR 本文編集 | Update comment |
| Discussion 新規 | Comment |
| Release | Publish release / Save draft |
| PR レビュー | Submit review |

### 設計原則 (前回事故からの learning — 重要)

「close/delete/cancel 系ボタンを絶対に踏まない」「期待ボタンが disabled なら fallback で
他ボタンを選ばず wait」が**最優先**。前回 (2026-06-11 PR#2388) は React state 同期遅延で
`Comment` が一瞬 disabled だった隙に、fallback の `submits[submits.length-1]` が拾った
**`Close with comment`** をクリックして PR を勝手に CLOSED にしてしまった。

3 つのガード:

1. **REJECT_RE: 破壊系/離脱系を絶対除外** (allBtns 構築時点で除く。disabled でも見えなくする)
   - `close, delete, cancel, discard, reset, dismiss, reject, remove, unsubscribe, lock, transfer, convert, archive` を含む textContent / aria-label を持つボタンは候補から消す
   - 特に `Close with comment` / `Close pull request` / `Close issue` は本スキルの目的から外れ、誤クリックの副作用が極めて大きい

2. **SUBMIT_RE: 完全一致の許可リスト**で primary を選ぶ (部分一致禁止)
   - 部分一致 ("comment" を含むなら何でも) にすると `Close with comment` が引っかかる → 完全一致
   - `comment, update comment, submit new issue, create, publish, save draft, update, submit review, reply, post comment, add a comment` 等

3. **disabled は wait、fallback は禁止**
   - primary 名一致したボタンが disabled なら、最大 ~5s (250ms × 20 回) poll で enable 待ち
   - wait timeout でも見つからなければ **fallback せず throw** (= 失敗として返す)
   - 「分からなければ最後の submit-type を選ぶ」式の fallback は **完全に廃止** (これが事故の原因)

### 実装 (eval 内で wait + click まで完結)

```js
(async () => {
  const composer = document.querySelector('[data-testid=comment-composer]')
                   || window.__GH_IMG_TARGET.closest('form, [data-testid$="composer"], [data-testid$="-form"]')
                   || window.__GH_IMG_TARGET.closest('[data-testid]');
  if (!composer) throw new Error('no container');

  // (1) 危険ボタン除外 + 可視性のみで候補集合を作る (disabled は除外しない=wait 対象)
  const REJECT_RE = /\b(close|delete|cancel|discard|reset|dismiss|reject|remove|unsubscribe|lock|transfer|convert|archive)\b/i;
  function listCandidates() {
    return [...composer.querySelectorAll('button')]
      .filter(b => b.offsetParent !== null)
      .filter(b => {
        const label = (b.textContent + ' ' + (b.getAttribute('aria-label') || '')).trim();
        return !REJECT_RE.test(label);
      });
  }

  // (2) 許可リスト完全一致で primary を探す (部分一致禁止)
  const SUBMIT_RE = /^(comment|update\s+comment|submit\s+new\s+issue|create|publish(\s+release)?|save\s+draft|update|submit\s+review|reply|post\s+comment|add\s+a\s+comment|approve|request\s+changes)$/i;
  function findPrimary() {
    const cands = listCandidates();
    return cands.find(b => SUBMIT_RE.test(b.textContent.trim().replace(/\s+/g, ' ')));
  }

  // (3) primary が見つかるまで・enable されるまで wait (最大 ~5s)
  const DEADLINE = Date.now() + 5000;
  let primary = null;
  while (Date.now() < DEADLINE) {
    primary = findPrimary();
    if (primary && !primary.disabled) break;
    await new Promise(r => setTimeout(r, 250));
  }

  // (4) wait してもダメなら fallback せず throw (close を絶対踏まないため)
  if (!primary) {
    const cands = listCandidates();
    throw new Error(`no submit button matching allowlist. candidates=${cands.map(b => b.textContent.trim()).join(' | ')}`);
  }
  if (primary.disabled) {
    throw new Error(`primary submit "${primary.textContent.trim()}" stayed disabled after wait. textarea may not be React-synced. re-run §8.`);
  }

  // (5) 念のため最終 sanity check: 選ばれたボタンが REJECT_RE に当たっていないか
  const label = (primary.textContent + ' ' + (primary.getAttribute('aria-label') || '')).trim();
  if (REJECT_RE.test(label)) {
    throw new Error(`SAFETY: rejected button "${label}" was about to be clicked. aborting.`);
  }

  primary.scrollIntoView({block: 'center'});
  primary.click();
  return {clicked: primary.textContent.trim(), type: primary.type};
})()
```

### 副作用が出た時のリカバリ

万一 close 系を踏んでしまった場合:
- PR/Issue close: `gh pr reopen N --repo owner/repo` / `gh issue reopen N --repo owner/repo`
- これは **メインに `failed:` で返して** メイン側で実行する (サブエージェントの autonomous
  state change は classifier に弾かれる)
- OUTPUT に `posted:` も併記する (コメント自体は投稿されている可能性が高い。URL を捨てない)

### click 前提条件 (これも前回事故の原因の一部)

- §8 で **native setter + input event** による fill が完了している (= React state 同期済)
- §8 完了から §9 までに僅かでも React 再 render の時間があると安全 (§9 の wait ループが
  吸収するので明示 sleep は不要だが、間隔をあけられるなら 250ms 程度待ってもよい)

> **eval 内で直接 click** する理由: snapshot で ref を取って playwright-cli click すると、
> その間に React 再生成が走って ref が無効化される事故があった。eval 内なら DOM 参照を
> 直接握ったまま click できる。

## 10. 投稿確認

`gh` CLI で投稿成立を裏取り:

```bash
# 新規コメント (URL から番号抽出)
gh issue view N --repo owner/repo --json comments \
  | jq -r '.comments[-1].body' | grep -F 'user-attachments/assets'
# コメント編集
gh api repos/owner/repo/issues/comments/NNN --jq .body | grep -F 'user-attachments'
# issue 本文編集
gh issue view N --repo owner/repo --json body --jq .body | grep -F 'user-attachments'
```

成立を確認したら OUTPUT (`posted:` + URL 列) を組んで返す。

## 11. 失敗時の挙動 (止めない、自分で観測リトライ)

メインに丸投げせず、**サブエージェント内で観測 → 再試行**を回す。
バウンドした試行 (各 2〜3 回程度) で復帰できなければ `failed:` で返す:

| 失敗 | 打つ手 |
|------|--------|
| polling timeout | snapshot で textarea 内容確認、`__GH_IMG_TARGET` 再取得 → 再 drop |
| submit 後 form が open のまま | snapshot でエラー読む (ログイン切れ / textarea 空 / size 超過) |
| URL 埋め込みが意図と違う | §7 を組み直して §8 から再実行 |
| upload 失敗 (CDN エラー) | snapshot 確認、画像が壊れていれば `failed:` で返す (リサイズはメイン責務) |

ログイン切れ・profile 前面化要求など **対話が要る失敗は `failed:` でメインに返す**
(サブエージェントは say/AskUserQuestion を打てないため)。

## 12. 後始末

```bash
playwright-cli -s="$AB" tab-close <タブインデックス>
# Welcome connect.html も閉じてグループ消滅 → セッション自然終了でよい
```

掃除しないとブラウザにゴミタブが残る。

## URL の永続性 (再利用可能・実証済)

upload 後の `https://github.com/user-attachments/assets/<uuid>` は **時間軸を超えて
再利用可能** (2026-06-09 06:01 取得 → 07:17 編集で再利用成功)。一度 upload した URL は
別コメント/別 issue/編集再投稿で **再 upload せず本文に書くだけで表示される**。
だから OUTPUT で URL を必ず返す (メインがあとで `gh ... edit` で使い回せる)。

## 検証履歴 (動作確認済みの中核事実)

| 検証 | 文脈 | UI 世代 | 結果 |
|------|------|--------|------|
| 2026-06-09: PR コメント編集再投稿 | `#issuecomment-NNN` | 旧 UI (form) | drop 2 画像 → URL 抽出 → `{{label}}` embed → submit 全 PASS。URL 時間軸永続も実証 |
| 2026-06-10: 新規コメント | issue 新規コメント | 新 UI (comment-composer / React) | drop 2 画像 → URL 抽出 → native setter で fill → submit PASS |
| 2026-06-11: PR#2388 新規コメント | PR 新規コメント (kawaz123) | 新 UI | drop 3 画像 → URL 抽出 → fill 完了 (len=1574)、しかし submit 検出ロジックの fallback (allBtns 末尾 submit-type 選択) が **「Close with comment」を踏んで PR を CLOSED** にする副作用。コメント自体は正常投稿。`gh pr reopen 2388` で復旧 → §9 を全面書き換え (close 系除外 + 完全一致 allowlist + disabled wait + fallback 廃止) |

新 UI 適応の要点: ①textarea 検出に testid/placeholder を追加 ②再生成対策で
drop/poll/fill/submit 直前に再取得 ③fill は native setter+input event ④submit は
**REJECT_RE で close/delete/cancel を除外 + SUBMIT_RE 完全一致の allowlist + disabled なら
wait + fallback 廃止** (= 2026-06-11 PR#2388 事故からの learning)。
