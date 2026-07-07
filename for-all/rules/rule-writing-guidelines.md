# ルール記述ガイドライン

rule / skill を書く・改廃するときの正本。

## 2分類原則: 常時ロード vs skill

書く前に必ずどちらか判定する:

- **常時ロード (`for-*/rules/`)** = **行動制約 (constitution)**。毎ターンの
  判断に効く禁則・自警・評価軸。例: 経験的検証、test 改変禁則、萎縮禁止
- **skill (`for-*/skills/`)** = **手順書**。特定の作業時にだけ必要な手順・
  コマンド・背景解説。例: 越境 push 手順、リリースフロー、watch 運用

判定基準: 「この内容が context に無いターンで事故が起きるか?」— 起きるなら
常時、特定作業の開始時に読めば足りるなら skill。1ファイル内に両方が同居し
そうになったら**分割する** (= 禁則だけ rule に残し、手順を skill へ)。

## 記述原則

1. **具体的**: 手順が決まっている場合はコマンドをそのまま記載
2. **省コンテキスト**: 背景説明は最小限、行動指針を明確に。rule は毎回
   ロードされるので冗長さがそのまま token 浪費になる
3. **リンク規約**: wikilink (`[[名前]]` 記法) は常時ロード同士でのみ使う。
   `for-all/rules/` から `for-me/rules/` への参照は禁止 (overlay 越境で
   dead link 化)。skill への参照は「`<name>` skill 参照」と名前で書く
4. **自己参照禁止**: 「関連」節で自ファイルを参照しない
5. **`.draft-` を rules 配下に置かない** (常時ロードされる)。draft は
   `docs/issue/` へ

3 の越境検査・4・5 と「5KB 超 warning」は claude-rules-personal リポの
`just lint-rules` task が機械検査する (同リポの push の deps で自動実行、
他リポにこの task は無い)。3 の「skill 参照は名前で書く」は目視。「未来予告 / 過去 narrative」([[no-historical-noise]]) だけは
機械判定が難しいので目視で確認する。

## 「該当なし」「やらないこと」明示の優先順位

[[no-historical-noise]] の「除外リストを書くな」と、tdd-and-test-design の
「該当なしを明示する勇気」は文書種別で切り分ける:

- **網羅性の主張が価値を持つ文書** (テスト / 検証記録 / タスクのスコープ
  アンカー): 「該当なし: 理由」「やらないこと」の明示が正 (= 漏れと意図的
  除外を区別するため)
- **恒常参照される文書** (rule / runbook / spec / trigger 定義): 包含側で
  書く ([[no-historical-noise]] が正)

## 例

```markdown
# プロジェクトXのビルド手順

ビルド: `cargo build --release`
チェック: `cargo fmt --check && cargo clippy -- -D warnings`
テスト: `cargo test`
```
