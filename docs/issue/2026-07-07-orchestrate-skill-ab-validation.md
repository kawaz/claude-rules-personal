---
title: "orchestrate skill の効果を A/B で実測し、発火・命名・ゲート閾値を調整する"
status: open
category: task
created: 2026-07-07T12:00:00+09:00
last_read:
open_entered: 2026-07-07T12:00:00+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: X の /fable skill POST 由来ギャップ分析 (2026-07-07, claude.ai セッション)
---

# orchestrate skill の効果を A/B で実測し、発火・命名・ゲート閾値を調整する

## 概要

`for-all/skills/orchestrate` (Phase 0-4 オーケストレーションプロトコル) を
導入した。X の /fable skill POST と本リポの rules 群のギャップ分析から、
既存 rules に無い5要素 (3行アンカー / 3値仕分け / リスク順分解 /
4自問ループ / 寄与証拠条文) を核に skill 化したもの。

効果は未実測。empirical-verification に従い、逸話でなく A/B で検証してから
定着 / 調整 / 廃棄を判断する。

## 検証設計 (案)

- **タスクセット**: 実案件から中規模タスクを 3〜5 本選ぶ (bug 調査 /
  複数ファイル変更 / 原因分析レポートの3カテゴリを最低1本ずつ)
- **条件**: skill 有 / 無 × 各 2〜3 run (run 間分散に埋もれる差は差と
  みなさない)
- **評価軸**:
  - 誘導耐性: 「〜が怪しい」という誤誘導を仕込んだタスクで、探索範囲を
    誘導に限定しなかったか
  - 報告の証拠率: 報告中の原因記述のうち寄与証拠付き or 「未確認」明記の
    割合
  - 手戻り回数: 検証遅延起因のやり直し回数
  - コスト: turn 数 / token 消費の増分 (プロトコルのオーバーヘッド計測)

## 確認したい懸念

- **narrated compliance**: Phase の見出しだけ書いて実質スキップする偽装。
  transcript 監査で「3行アンカーの検証方法が実際に Phase 4 で使われたか」
  を突き合わせる
- **発火率**: description ベースの自動発火が中規模タスクで実際に起きるか。
  起きないなら常時ロード側に1行トリガを置くか検討 (ただし
  always-loaded-rules-diet と逆行するので最終手段)
- **過剰プロセス**: 適用ゲートの「軽微編集」境界が実運用で妥当か
- **モデル依存**: 本 skill は「Opus 級メイン時に Fable 級の規律へ寄せる」
  動機で作られた。metacognitive-rule-model-revalidation と同様、モデル
  世代交代時の再検証対象としてマークする

## 命名

`orchestrate` は仮名。プラグインとして公開する場合は命名候補の再考 +
レジストリ / GitHub 競合チェックをセットで行う (ローカル skill の間は
競合問題なし)。

## 受け入れ条件

- [ ] A/B の実測結果が docs/findings/ に記録されている
- [ ] 継続 / 調整 / 廃棄の判断が結果に基づいて下されている
- [ ] narrated compliance の有無が transcript で確認されている
