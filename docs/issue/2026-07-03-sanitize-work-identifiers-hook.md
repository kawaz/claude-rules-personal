---
title: "業務固有名詞サニタイズの機械判定 hook 化 (claude-sanitize-guard) 設計案"
status: idea
category: design
created: 2026-07-03T14:06:03+09:00
last_read:
open_entered:
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: "エコシステム横断監査 (2026-07-03)"
---

# 業務固有名詞サニタイズの機械判定 hook 化 (claude-sanitize-guard) 設計案

## 概要

`[[sanitize-work-identifiers]]` (for-all/rules) による業務固有名詞の流出防止が、
現状 **AI (Claude) の注意力頼み** になっている。各 overlay の `identifiers-*.md`
に単語リストは定義済みだが、それを実際に守るかどうかは都度の prose rule 遵守に
委ねられており、これがエコシステム全体で **最弱リンク** になっている。

これを hook 化し、単語境界マッチだけでも機械判定に落とす新規 plugin の設計案。

## 背景

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内で 3 subagent を
起動して claude-rules-personal / 各 overlay の rule 群を横断調査) 由来。監査中に
「sanitize 系ルールは prose 頼みで、実際に破っても機械的に検知されない」という
構造的弱点が観測された。

## 設計案

### 対象 hook

**PreToolUse hook** (Write / Edit / commit 系 Bash コマンド) で、書き込み内容を
突合する。

### 判定ロジック

- `CLAUDE_CONFIG_DIR` 配下に各 overlay から注入された `identifiers-*.md` を
  パースし、単語リストを抽出
- 書き込み対象内容 (Write/Edit の新規内容、commit 系 Bash の diff 相当) と
  **単語境界マッチ**で突合
- **単語境界マッチのみ**を機械判定の対象とする。文脈判定が必要なカテゴリ
  (`identifiers-*.md` の「業務カテゴリ」セクション、例: 金融業務関連、学校教育関連等)
  は機械では判定不能なため、引き続き prose rule (各 `identifiers-*.md` の判断例)
  側に委ねる

### 検出時の挙動

**block ではなく warn + 確認誘導**。理由: `identifiers-*.md` 自身が明記する通り、
一般名詞との衝突 (例: "party" が集まり/パーティーの意味で使われるケース) があり、
機械的単語マッチには誤検知が避けられない。block だと誤検知時に正当な作業が
止まってしまうため、warn 止まりが妥当という仮説。

### 構成テンプレ

`claude-bash-safety` (1-hook plugin) の構成を参考にする (= 新規 plugin の
ディレクトリ構造・hook 登録・設定ファイル読み込みパターン)。

### 新規リポ名案

`claude-sanitize-guard` (kawaz 個人 OSS、`kawaz/claude-sanitize-guard` を想定)。

## 受け入れ条件

- [ ] kawaz の設計レビューを経て実装可否・設計詳細が確定する
- [ ] (実装する場合) `identifiers-*.md` の単語リストパース + 単語境界マッチが
      各 overlay (personal / emeradaco / zunsystem / syun) で動作する
- [ ] (実装する場合) 誤検知時の warn 表示が「なぜ引っかかったか」を明示し、
      確認誘導 (続行 / 修正) が機能する

## TODO

- [ ] kawaz に設計レビューを依頼 (実装着手前必須)
