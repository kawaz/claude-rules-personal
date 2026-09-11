# ルール記述ガイドライン

rule / skill / 参照知識 (reference / memory / privacy) を**編集・新設・改廃する時は、先に reference の `rules-authoring` を読む** (常時ロード / skill / 参照知識の判定、索引の書式、reference の構成と分割、rule や skill を reference へ降ろす手順)。

## 禁則 (読まずに踏むと事故る)

- **`.draft-` を rules 配下に置かない** (常時ロードされる)。draft は `docs/issue/` へ
- **`for-all/rules/` から `for-me/rules/` を wikilink で参照しない** (overlay 越境で dead link 化)
- **自己参照しない** (「関連」節で自ファイルを指さない)
- **本文と索引は同じ変更で更新する** (参照知識の `_index.md` も、rules のフェーズ別 index も)
- **行長を揃える改行をしない** ([[no-hard-wrap]])

これらと「5KB 超 rule」「常時ロード合計の予算」は `just lint-rules` が機械検査する (claude-rules-personal リポと各 overlay リポの push の deps で自動実行)。

## 「該当なし」「やらないこと」明示の優先順位

[[no-historical-noise]] の「除外リストを書くな」と、reference の `testing/test-coverage-checklist` の「該当なしを明示する勇気」は文書種別で切り分ける:

- **網羅性の主張が価値を持つ文書** (テスト / 検証記録 / タスクのスコープアンカー): 「該当なし: 理由」「やらないこと」の明示が正 (= 漏れと意図的除外を区別するため)
- **恒常参照される文書** (rule / runbook / spec / trigger 定義): 包含側で書く ([[no-historical-noise]] が正)
