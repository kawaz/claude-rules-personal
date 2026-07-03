# ecosystem-audit-and-fixes: kawaz リポ全体のエコシステム監査と即時 fix

- Date: 2026-07-03

## 何をしていたか

kawaz の個人リポ群全体を横断監査し、単リポ作業では見えない構造課題 / 移行漏れ /
参照不整合を洗い出して、即修正できるものはその場で fix、根が深いものは issue 化した。

監査は subagent 3 本の並列調査で実施:

- **rules リポ構造** — `claude-rules-personal` の for-all / for-me / overlay 構成と
  常時ロードサイズ、prose 規約の enforce 状況
- **plugin 系 17 リポ** — marketplace.json / plugins.json の参照整合、rename 後の
  旧名残存、bundle vs 独立リポの区別
- **CLI 系 28 リポ** — release workflow 型、homebrew-tap 同期、未 push 残置、docs 構造

## 構造所見 (3 点)

### 1. 常時ロード rules の肥大

`for-all` 89.6KB + `for-me` 37.4KB、overlay 込みで 1 セッション約 50 ファイルが
常時コンテキストに載る。`rule-writing-guidelines` の「省コンテキスト」原則に対して
肥大傾向。5KB 超 rule が現状 7 件 (`just lint-rules` の warning で可視化)。

### 2. prose 規約が機械 enforce されず、自リポに違反が実在

`push-workflow.md` が「for-all→for-me 越境リンク禁止」等を prose で規定していたが、
機械チェックが無く、**自リポ内に実際の越境リンク違反が存在**した
(`top-tier-model-delegation` → `[[work-principles]]` が for-me を指していた)。
規約を書くだけでは守られない好例。

### 3. リポ引退の規約不在により、移行後始末漏れが同型多発

後継リポで置き換えた / rename した後の後始末に定型手順が無く、同じ型の漏れが複数リポで
再発していた:

- marketplace / plugins.json の旧参照残存 (例: `pr-monitor` 表記)
- rename 後の化石ローカルクローン放置
- 廃止記録 (README の後継明記) なしの事実上不使用化
- 後継リポ言及の不整合
- homebrew-tap のローカル ⇄ GitHub 同期漏れ

## 本日実施した fix

### 本エージェント (claude-rules-personal) の作業

| commit | 内容 |
|---|---|
| `29518648` | `gh-image-fetch` skill + 根拠 findings を追加 (2026-07-01 の残置変更を固定) |
| `fa9da3b6` | `no-excessive-apology`: 質問の捉え方を最重要セクションに昇格 |
| `b5bfbc76` | `work-principles` を for-all へ promote (所見 2 の越境リンク解消) |
| `b5276805` | `plugins.json`: `pr-monitor` → 現行名 `gh-monitor` に更新 (所見 3) |
| `503f2d11` | justfile に `lint-rules` task 追加 + push の gate 化 (所見 2 の機械 enforce) |
| `8d0c0fa6` | `push-workflow.md` の lint 節を `just lint-rules` 参照に置換 (所見 1 の省コンテキスト化) |
| `35fe07b2` | `repo-retirement` + `fleet-audit` runbook を追加 (所見 3 の手順化) |
| `b4218954` | `docs/issue/` 旧形式 5 件を frontmatter/INDEX 正本化 (local-issue:migrate) |

### 並行実施分 (他リポ、詳細は各リポの commit 参照)

- `claude-plugins` の marketplace 参照切替
- `cmux-msg` の後継リポ記述整合
- `homebrew-tap` のローカル同期

## 同日起票の issue 一覧 (タイトルのみ)

### rules リポ (7 件)

1. 常時ロード diet (rules 肥大の削減)
2. sanitize hook 化設計 (業務固有名詞サニタイズの機械化)
3. fleet-audit 自動化 (横断監査の定期実行の仕組み化)
4. repo-retirement 適用対象リストの洗い出し
5. `work-principles` と `top-tier-model-delegation` の統合検討
6. ccmsg・nandakke 優先度メモ
7. メタ認知 rule の世代再検証運用

### 他リポ (6 件)

1. hyoui triage
2. cache-warden triage
3. plugin-jj 去就
4. gh-monitor issue 整理
5. plugin-reference docs 追従
6. mdp テスト・依存整備

## 議論の要点 (判断メモ)

即修正した項目 (residual 固定 / promote / plugins 名更新 / lint / runbook / migrate) は
**issue を起票せず、本 journal + commit 記録で代替**した。`docs-knowledge-flow` の
「単純なコード修正のみ → 記録不要 (CHANGELOG / コミットメッセージで足りる)」に準拠。
issue 化したのは「設計判断を要する / 継続追跡が必要」なものだけ。

## 関連

- `docs/runbooks/fleet-audit.md` — 本監査を定期運用に落とした手順
- `docs/runbooks/repo-retirement.md` — 所見 3 の引退後始末手順
- `for-me/rules/push-workflow.md` — 所見 2 の lint 節 (`just lint-rules`)
