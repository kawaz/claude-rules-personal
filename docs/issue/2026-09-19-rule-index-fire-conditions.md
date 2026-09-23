---
title: for-all/rules/_index.md の要旨に発火条件 (該当する時 / しない時) を書くと機械判定に使える
status: idea
category: design
created: 2026-09-19T08:12:03+09:00
last_read: 2026-09-23T22:45:59+09:00
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
origin: sandbox-jev
---

# for-all/rules/_index.md の要旨に発火条件 (該当する時 / しない時) を書くと機械判定に使える

## 概要

sandbox-jev リポの実験で、rule の適用判定 (fan-out) を `_index.md` の 1 行要旨だけで行うと誤検知・取りこぼしが出た。要旨を「発火語の羅列」から「発火条件 + 非発火条件」の形へ書き換えると、機械判定の精度が上がる (人間の想起にも効く見込み)。

## 背景

sandbox-jev の実験06 (33 rule を noul で fan-out、criteria は `_index.md` の 1 行要旨をそのまま使用) で以下の問題が見つかった:

- 誤検知: `public-repo-contribution` が「public OSS」の語だけで 0.65 に誤反応
- 取りこぼし: `sanitize-work-identifiers` 0.59、`retreat-is-last-resort` 0.19

続く実験07で、5 個の rule だけ instructions に `fires_when` / `does_not_fire_when` を追加したところ:

- `sanitize-work-identifiers`: 0.59 → 0.94 に改善
- `retreat-is-last-resort`: 0.19 → 0.83 に改善
- `public-repo-contribution` の誤検知: 0.65 → 0.07 / 0.74 → 0.09 に解消

一方 `tooling-tips` は改善 (0.23 → 0.70) したが、関係の薄い場面でも 0.46 → 0.62 / 0.37 → 0.59 と広がった (fires_when の条件「! を含むコマンド」が広すぎた疑い)。

触っていない残り 28 rule はほぼ値が動かず、criteria の変更が局所的であることを確認した。

詳細は sandbox-jev リポの以下:

- `docs/findings/2026-09-18-exp06-rule-fanout.md`
- `docs/findings/2026-09-19-exp07-rule-fanout-criteria.md`

## 提案

1. `_index.md` の各行を「発火語の羅列」から「発火条件 + 非発火条件」へ書き換える (人間の想起にも効く)
2. Jev による rule ロード判定 (禁則系は常時ロード、判断系は fan-out で選別) の可能性

担当: kawaz 裁定待ち。

## 受け入れ条件

- [ ] `fires_when` / `does_not_fire_when` 形式で書き換える rule の範囲を決める
- [ ] `tooling-tips` のような条件過剰広がりを防ぐ書き方の指針を決める
- [ ] Jev のロード判定方式 (常時ロード vs fan-out 選別) の採否を決める

## TODO

<!-- wip 時のみ -->
