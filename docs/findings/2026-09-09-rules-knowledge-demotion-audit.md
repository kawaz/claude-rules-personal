# 常時ロード rule の knowledge 降格候補の精査 (2026-09-09)

`for-all/rules/*.md` と `for-me/rules/*.md` を全件通読し、「行動制約 (常時に残す)」「参照知識 (knowledge へ降格)」「手順書 skill 向き」に節単位で仕分けた結果。読み取りのみで、rule ファイルは編集していない。

## 判明した事実

- 常時ロードの現状合計は **81,999 bytes** (予算 81,920 を 79 bytes 超過)。
- **降格候補は 14 件**。内訳は knowledge 降格 11 件、単純削除 3 件。**手順書 skill へ移すべきものは無かった** (rule 内に実行資源 = スクリプト・テンプレ・付属ファイルを伴う手順は残っていない)。
- 14 件を全て実施した場合の削減は、降格・削除で **−15,600 bytes**、rule 側に残す誘導文案で **+1,700 bytes**、差し引き **−13,900 bytes**。降格後の常時ロードは **約 68,100 bytes** (予算に対し 17% の余裕)。
- 判断が割れる**境界例は 6 件**: `tooling-tips` の direnv 節、`notification-tips` の 1Password 節、`llm-gateway-cache-keepalive` 全体、`_index.md` 全体、`secret-hygiene` の原則節、`cli-design-preferences` 全体。
- 降格とは別軸で、**public リポへの業務固有名詞の混入が 2 箇所**ある (`for-me/rules/git-repo-management.md`、`for-all/rules/kawaz-identity.md`)。このリポは `gh repo view` で `PUBLIC` と確認済み。
- 既存 rule に**古いバージョン注釈と 3 分類化前の記述**が残っている (`for-me/rules/role-based-skill-loading.md`)。

## 実用的な示唆 / ベストプラクティス

- 降格の可否は「その内容が context に無いターンで事故が起きるか」だけでは足りず、**事故の重大度 (可逆か / 認証境界を越えるか)** と、**発火語がそのターンに必ず現れるか**の 2 軸を併せて見ると判定が安定する。発火語が目の前にある種類の知識 (エラー文字列、`op://`、`--help`) は降格しやすく、通知のように文脈なく飛んでくるものは残す側に倒れる。
- 禁則を 1 行残して詳細を降格する形が最も安全。「正しい形」だけ常時に置き、「なぜ他が駄目か」を knowledge へ送ると、実行時の判断は完結したまま bytes が落ちる。
- 各 rule に「対極」節を書き足していく運用 (`self-written-rule-blind-spots` の適用) は正しいが、そのぶん常時ロードが肥大する。対極の実演を rule 内で繰り返すより、対極そのものを 1 本の rule に集約する方が総量では有利。
- `_index.md` のような索引は、索引対象が全て常時ロードされている状況では二重掲載になる。索引の価値は「フェーズ別の地図」であって内容の再掲ではないので、地図としての価値を残すか bytes を取るかは設計判断として明示的に決めるべき。

## 検証の詳細

### 仕分け表

| rule ファイル | 節 | 判定 | bytes | 理由 |
|---|---|---|---|---|
| tooling-tips.md | `## Bash: 別ディレクトリ…` の Good/Bad コード例 + Why の実測 narrative | knowledge 降格 (1 行の正しい形は残す) | 2209 → 残 ~300 | 事故る形の列挙と実測日付は「なぜそうか」の説明で、実行時に要るのは正しい形 1 行だけ |
| tooling-tips.md | `!` エスケープ / hyperfine | knowledge 降格 | 257 | 遭遇した時に読めば足りる小技 |
| secret-hygiene.md | `## 原則` | 残す | 707 | 「AI が値を直接触らない」は行動制約そのもの |
| secret-hygiene.md | `## 使い方` + `## 2 段の確認 & 実行` | knowledge 降格 | 1233 | op run の具体コマンドと 2 段運用は secret を扱うと決めた後の手順 |
| secret-hygiene.md | `## 機微キーワード` | 残す | 439 | 発火語そのもの。降格すると「読むべきだ」と気づけない |
| secret-hygiene.md | `## ユーザが直接 credential を…` | 残す | 419 | 「勝手に rotate / revoke しない」は禁則 |
| notification-tips.md | `say` のカタカナ変換表 | knowledge 降格 | 958 → 残 ~120 | 表は say を呼ぶ瞬間にしか要らない |
| notification-tips.md | 1Password エラー時の対応 | 境界 (推し: 残す) | 831 | 不在推定時の振る舞い分岐は行動制約寄り |
| claude-config-dir-isolation.md | `## 禁則` | 残す | 862 | mkdir / symlink 禁止は毎ターン効く禁則 |
| claude-config-dir-isolation.md | `## 越境作業` | 一部 knowledge 降格 | 695 → 残 ~250 | 基本形は tooling-tips と重複。ここは skill への誘導だけでよい |
| llm-gateway-cache-keepalive.md | 本体 (通知形式 + How to apply) | 境界 (推し: 残す) | 1108 | 通知が届いたターンに knowledge を読む余裕が無い |
| llm-gateway-cache-keepalive.md | `## Why` (事故の経緯) | 単純削除 | 337 | no-historical-noise の history narrative に該当 |
| cli-design-preferences.md | 全体 | 境界 (推し: knowledge 降格) | 2422 → 残 ~150 | CLI を設計するターンにだけ要る好みのカタログ |
| kawaz-identity.md | 正式表記表 + 用途別表記表 | knowledge 降格 | 1305 → 残 ~180 | 対外文書を書く場面は稀。禁則 (推測で書かない) だけ常時に残す |
| research-documentation.md | ファイル構成 + 記録委譲ワークフロー | knowledge 降格 | 1657 → 残 ~150 | テンプレとプロンプト例は記録を始める時の手順 |
| research-documentation.md | `## 原則` | 残す | 380 | 「context でなくファイルに残す」「委譲する」は行動制約 |
| work-principles.md | `### サブエージェントとの入出力` | 圧縮 | 611 → 残 ~200 | transcript を読む事故は重大なので禁則 1 行は必ず残す |
| work-principles.md | その他 | 残す | 2488 | 委譲判断は毎ターン効く |
| empirical-verification.md | `## 観測道具を使う` の道具リスト | knowledge 降格 | 429 → 残 ~120 | 「観測してから解釈する」が制約、道具名は調べればよい |
| no-excessive-apology.md | reaction template コードブロック | 単純削除 | 200 | 本文の How to apply と重複 |
| rule-writing-guidelines.md | `## 例` (cargo のビルド手順例) | 単純削除 | 189 | 記述原則 1 の説明として弱く、実質ノイズ |
| _index.md | 全体 | 境界 (推し: knowledge 降格) | 4198 → 残 0 | 全 rule が既に常時ロード済みなので索引は二重掲載 |
| for-me/role-based-skill-loading.md | 命名規約 + invoke 例 + 強制力の注記 | knowledge 降格 | 1529 → 残 ~150 | 「role 判定 → load-role-{name} を invoke」だけが行動制約 |
| for-me/role-based-skill-loading.md | `## 常駐ルール最小化の方針` | 単純削除 | 315 | rule-writing-guidelines の 3分類原則と重複、かつ 2 分類のまま古い |
| for-me/dogfooding-feedback-upstream.md | `## 部外者として起票するときの姿勢` | 半分降格 | 1218 → 残 ~350 | 「断定しない / 該当性を確認してから起票」は制約、具体例は手順 |
| for-me/push-workflow.md | 全体 | 残す | 1939 | パス指定禁則は commit のたびに効く |
| for-me/git-repo-management.md | 全体 | 残す | 552 | 短く、新規リポ作成時の公開設定は事故ると不可逆 |

### 降格対象なしと判定した rule

以下は全て純粋な行動制約で、節単位でも降格できる部分が無い: design-priority / design-thinking / default-convergence-guard / synthesis-temptation-guard / no-historical-noise / interface-wording / report-and-decomposition-form / retreat-is-last-resort / self-written-rule-blind-spots / design-impl-bidirectional-check / spec-careful-reading / document-design-rationale / sanitize-local-paths / sanitize-work-identifiers / public-repo-contribution / no-hard-wrap / discussion-style / feedback-evaluation / sloppy-ai-patterns。

### 降格候補ごとの詳細

#### 1. tooling-tips.md の direnv 節 (2209 bytes)

rule に残す文案:

> ## Bash: 別ディレクトリでのコマンド実行
>
> `(cd /path/to/dir && direnv exec . command args...)` の形にする。`cd` だけ / `direnv exec` だけの片方では事故る (env が乗らない / cwd が別リポのまま)。`git -C dir` も同じ理由で避ける。direnv 未 allow のディレクトリでは指示を仰ぐ (勝手に `direnv allow` しない)。落ちる罠の実測は knowledge の `direnv-exec-cwd` を読む。

- slug 案: `direnv-exec-cwd`
- 発火語: direnv exec, 別ディレクトリでコマンド実行, cd したのに .envrc が効かない, SSH_AUTH_SOCK が切り替わらない, git -C, direnv allow
- 事故リスク: **低〜中**。正しい形 1 行が常時に残るので、実行時に間違った形を書く事故は防げる。降格されるのは「なぜ間違いか」の説明と実測日付。ただし認証境界の越境事故が過去に実際に起きているため、残す 1 行の文言は弱めないこと。

#### 2. secret-hygiene.md の使い方 + 2 段節 (1233 bytes)

rule に残す文案:

> op run 経由の具体手順 (env-file の書き方、`--no-masking` を付ける / 付けない 2 段運用) は knowledge の `op-run-secret-injection` を読む。

- slug 案: `op-run-secret-injection`
- 発火語: op run, 1Password CLI, op://, --no-masking, env-file, secret を env に注入
- 事故リスク: **低**。禁則側 (`$()` 直展開しない / AI が値を直接ハンドリングしない / 機微キーワード一覧) が常時に残れば、「secret を扱う」と気づく能力は失われない。

#### 3. notification-tips.md の say カタカナ表 (958 bytes)

rule に残す文案:

> `say` に頭字語・略語をそのまま渡すと誤読される (`OTP` → 「おっとぴー」)。カタカナに変換してから渡す。変換表は knowledge の `say-katakana` を読む。

- slug 案: `say-katakana`
- 発火語: say, 音声通知, 読み上げ, 頭字語のカタカナ化
- 事故リスク: **低**。禁則 (カタカナ化する) が残れば表を見なくても自力で変換でき、表は精度を上げるだけ。

#### 4. cli-design-preferences.md 全体 (2422 bytes)

rule に残す文案:

> # CLI 設計の好み
>
> CLI (サブコマンド構成 / `--help` の節構成 / bool フラグ / 引数位置 / completion) を設計・変更する時は knowledge の `cli-design-preferences` を読む。実装・`--help`・completion の 3 者は常に同時に追従させる。

- slug 案: `cli-design-preferences`
- 発火語: CLI 設計, サブコマンド, --help, オプション, bool フラグ, completion, 引数パーサ
- 事故リスク: **中**。境界例として下記に両論を記載。

#### 5. kawaz-identity.md の表 2 つ (1305 bytes)

rule に残す文案:

> 対外文書 (メール・PR・公的書類) で本人名を表記する時、**推測で漢字・ローマ字を書かない**。正本の表記は knowledge の `kawaz-identity` を読む。不明なら本人に確認。

- slug 案: `kawaz-identity`
- 発火語: 署名, 対外メール, 実名表記, 差出人名, ローマ字表記
- 事故リスク: **低**。「推測で書かない」の禁則が残るので書く直前に必ず読みに行く。誤記リストは「書かない」側の列挙で、no-historical-noise の除外リスト禁止にも触れるため降格が素直。

#### 6. research-documentation.md のファイル構成 + ワークフロー (1657 bytes)

rule に残す文案:

> 調査・検証の結果は context でなく `docs/findings/` 等にファイルとして残す。記録はバックグラウンドのサブエージェントに委譲し、会話をブロックしない。ファイル構成テンプレ・委譲プロンプトの型は knowledge の `findings-recording` を読む。

- slug 案: `findings-recording`
- 発火語: findings, 調査結果を記録, 検証記録, docs/findings, 記録委譲
- 事故リスク: **低**。

#### 7. claude-config-dir-isolation.md の越境節 (695 bytes)

rule に残す文案:

> ## 越境作業
>
> 別環境のリポを触る指示が来たら `(cd <対象リポ> && direnv exec . <command>)` を基本形にする ([[tooling-tips]] が正本)。rules は全環境に注入されるが memory は越境しない。**push / commit signing を伴う越境**は認証が 2 経路あり、`cross-env-ssh-signing` skill に従う。

- 降格分は tooling-tips 側の knowledge エントリに吸収 (新規エントリ不要)。
- 事故リスク: **低**。重複解消なので情報は失われない。

#### 8. work-principles.md のサブエージェント入出力 (611 bytes)

rule に残す文案:

> ### サブエージェントとの入出力
>
> **`Full transcript available at:` / `output_file:` のファイルは絶対に読まない** (全会話履歴の JSONL でメインの context が溢れる)。結果は `<task-notification>` の `<result>` に全文入っているのでそれを使う。

- 降格分 (なぜ溢れるかの説明) は knowledge に送らず、上記への圧縮で足りる。
- 事故リスク: **低**。禁則が太字で残る。

#### 9. empirical-verification.md の観測道具リスト (429 bytes)

rule に残す文案:

> 推測ベースの「たぶんこう動く」を禁止し、プロセス / 端末 / ネットワークの観測道具で実体を見る (道具の一覧は knowledge の `observation-tools`)。

- slug 案: `observation-tools`
- 発火語: 観測道具, strace, dtrace, lsof, tcpdump, tmux capture-pane, 実機で確認したい
- 事故リスク: **低**。価値も低いので「降格せず削るだけ」でも成立する (道具名は自力で出せる)。

#### 10. role-based-skill-loading.md の命名規約 + invoke 例 + 強制力 (1529 bytes)

rule に残す文案:

> ### 3. `load-role-{name}` を Skill tool で invoke
>
> 判定した role の `load-role-{name}` を invoke し、その本文に列挙された skill を順次 invoke する (自動ロード機構は無いので AI の履行に依存)。role skill / loader の命名規約は knowledge の `role-skill-naming` を読む。

- slug 案: `role-skill-naming`
- 発火語: role skill を追加, load-role-, role-main-, ローダースキルの命名
- 事故リスク: **低**。命名規約が要るのは role skill を新設する時だけ。

#### 11. dogfooding-feedback-upstream.md の部外者姿勢節 (1218 bytes)

rule に残す文案:

> ## 部外者として起票するときの姿勢
>
> 利用側は対象ツールの責務を把握していない前提で、**フラグ + 一次資料の提示に留める** (具体的な diff やコードを書いて渡さない)。断定せず「裏取りしてから採否を決めて」と明記し、起票前に対象コードを読んで該当性を確認する。

- 降格分は具体例の解説のみ。knowledge エントリは不要で、圧縮で足りる。
- 事故リスク: **低**。

#### 12〜14. 単純削除 3 件

`llm-gateway-cache-keepalive.md` の Why (337)、`no-excessive-apology.md` の template コードブロック (200)、`rule-writing-guidelines.md` の cargo 例 (189)。いずれも本文と重複するか history narrative で、失われる情報がない。

### 境界例の両論

**tooling-tips の direnv 節** — 推しは降格 (正しい形 1 行が残れば実行時の判断は完結する)。反対の根拠: この rule が防いでいるのは「認証境界を越えた push」という不可逆事故で、`feedback-evaluation` の「止めるべきケース」に該当する重大度。Bad 例が context にある状態と無い状態で、誤った形を書く確率は同じではない。重大度で倒すなら現状維持もあり得る。

**notification-tips の 1Password 節** — 推しは残す。「不在推定時は問い返さず音声通知だけで push をスキップして続行」はエラーが起きたターンで即座に効く行動分岐で、そこで knowledge を読みに行く発想が出るとは限らない。反対の根拠: 完全に「1Password エラーに遭遇した時にだけ要る手順」で、発火語 (エラー文字列) が極めて明確。エラーが目の前にある状態なら引ける、と見るなら降格可 (831 bytes)。

**llm-gateway-cache-keepalive 全体** — 推しは残す。通知は文脈のないタイミングで飛んでくる上、期待される応答が「nonce を 1 行返すだけ、ツール呼び出しも不要」なので、knowledge を Read する時点でその期待に反する。反対の根拠: 通知文自体が自己説明を含むため、rule を「keepalive ping は正規の自動通知、nonce を 1 行で返す」の 2 行 (約 200 bytes) まで削れば実質同じ効果で 900 bytes 浮く。これは降格ではなく圧縮なので、残す判断と両立する。

**_index.md 全体 (4198 bytes)** — 推しは knowledge 降格。全 rule が既に常時ロードされている以上、rule 名 + 1 行要旨の索引は二重掲載で、索引が実際に要るのは rule を追加・削除して index を更新する時だけ。反対の根拠: `_index` はフェーズ別の地図で、「いま設計フェーズだからこの 4 本を意識する」という多重所属の見取り図は個別 rule の本文からは復元できない。降格すると rule 群が平坦な 30 ファイルの山に戻る。単独で削減見込みの 30% を占めるため、判断待ちにすべき最大の項目。

**secret-hygiene の原則節 (707 bytes)** — 推しは残す。反対の根拠: 「op run のマスク挙動の説明」は知識であって制約ではなく、制約は「`$()` で展開しない」の 1 行だけ。厳密に仕分ければ 500 bytes ほど降格できる。

**cli-design-preferences 全体** — 推しは降格。反対の根拠: この rule は「無自覚なデフォルトに流れない」ための好みの表明で、`default-convergence-guard` と同じ性質を持つ。CLI を書き始める時に好みの存在を思い出せるかは常時ロードされているかに依存する。発火語が明確なので降格側に倒したが、`default-convergence-guard` を常時に置いているのと整合しないという指摘は成立する。

### 降格以外の指摘

**public リポへの業務固有名詞の混入 (要対処)。** このリポは `gh repo view --json visibility` で `PUBLIC`。`for-me/rules/git-repo-management.md` の owner 表に業務先の社名のカタカナ表記が、`for-all/rules/kawaz-identity.md` の GitHub 行に業務専用アカウント名が入っている。どちらも overlay 側の identifiers に列挙されている語で、`sanitize-work-identifiers` の「public リポに入る一切」に該当するため、「業務用 GitHub アカウント」等への一般化が要る。bytes 削減とは別軸の指摘。

**重複。** (a) 越境の基本形が `tooling-tips` と `claude-config-dir-isolation` の両方にある (後者は正本を断りつつ形自体を再掲している)。(b) `role-based-skill-loading` の「常駐ルール最小化の方針」が `rule-writing-guidelines` の 3分類原則と重複し、しかも 2 分類のまま古い (参照知識の層が無い)。(c) `work-principles` の委譲 tier 説明は `worker-fleet` skill と重複するが、skill 参照が明示済みで許容範囲。

**古い記述。** `role-based-skill-loading` に `(v1)`、`(2026-07-20 時点)`、`(kawaz mid=45)` のバージョン・日付注釈があり、`no-historical-noise` の「バージョン番号付き注釈」に該当する。同ファイルの role 表の worker / reviewer 行が「(現状無し)」なのも、同 rule の除外リスト禁止に触れる。

**無駄に長い箇所 (hard-wrap 以外)。** `discussion-style` の「議論を引き延ばさない (= 対極)」節と `feedback-evaluation` の「後戻りコストが膨らむ前の再判断」は、どちらも `self-written-rule-blind-spots` の適用例を各 rule 内で再実演していて、合わせて 1,200 bytes ほど。内容は正しいので削減提案はしないが、対極節を各 rule に書き足す運用は今後も肥大を生む。

### 残存 bytes の見積

| 前提 | 残存 bytes |
|---|---|
| 現状 | 81,999 |
| 14 件を全て実施 | 約 68,100 |
| `_index.md` の降格のみ見送り | 約 72,300 |

いずれも予算 81,920 を下回る。
