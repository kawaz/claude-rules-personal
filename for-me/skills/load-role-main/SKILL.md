---
name: load-role-main
description: 統括メイン (main role) が最初に invoke するローダースキル。統括として動く AI が必須の全 skill を Skill tool で連続 invoke する指示を持つ。role-based-skill-loading ルールから呼ばれる。
---

# load-role-main — 統括メインが必須の skill を連続 invoke

**使い方**: 統括メイン (main role) として動く AI は、セッション開始時にこの skill を Skill tool で invoke する ([[role-based-skill-loading]] ルール参照)。以下の必須 skill を Skill tool で**順次 invoke** すること。1 個ずつ Skill tool で invoke = 統括の動作に必要な全知識が context に載る。

## 統括メインの必須 skill 一覧 (必ず invoke)

以下を Skill tool で 1 個ずつ **必ず全て invoke**:

1. **`role-main-context`** — 統括メインの 4 責務 + 失敗パターンと立て直しの型 (kawaz mid=8/mid=44 由来)
2. **`personal-worker-fleet`** — worker 選定の第一原則 (タスク難易度で選ぶ、テンプレ禁則)
3. **`personal-orchestrate`** — 中〜大規模タスクのオーケストレーション (Phase 0-4)
4. **`personal-docs-structure` — docs 起票の構造化 (finding / spec / DR / QUESTIONS.md)

## 補足

- Skill tool は 1 invoke で 1 skill = 複数 skill 個数分の invoke が要る (本 loader 呼び出しで自動連鎖はしない、AI が指示履行で順次 invoke する)
- Claude Code 標準に「Skill 内から別 Skill を自動ロード」機構は無い (2026-07-20 時点) ため、本 loader は AI の指示履行に依存

## 関連

- [[role-based-skill-loading]] — role 判定と loader invoke の常駐ルール
- [[role-main-context]] — 統括メインの役割本体 (この loader が invoke する 1 個目)
