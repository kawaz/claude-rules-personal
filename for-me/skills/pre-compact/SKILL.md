---
name: pre-compact
description: compaction (自動/手動) の前にセッション状態を XDG_CACHE_HOME へ保存する (要約が落とすものの保険レイヤ)
---

# pre-compact — compaction 前のセッション状態保存

コンテキスト圧縮が迫った (または `/compact` する) 前に、状態ファイルを書く。
clear と違い**不完全な自動要約が付いてくる**前提なので、役割は「要約の補正レイヤ」 —
要約器が落とす・歪めるものに力点を置く。走行中の作業があっても使える (むしろその時用)。

## 1. 保存先と命名

`pre-clear` skill §1 と同一 (タイムスタンプ実体 + `latest.md` ポインタ + loaded_by マーク。
プロトコルの正本はそちら)。

## 2. 内容 — 10 セクション (pre-clear と同じ骨格) + compact 固有の力点

セクション構成は `pre-clear` skill §2 の 10 項と同一。compact では以下に厚く倒す:

- **要約器が落とす精密情報の保険**:
  - 正確な識別子: コミット hash・ファイルパス・数値 (テスト数、台帳件数)・msg id
  - ユーザ裁定の**原文の要点** (要約の言い換えで意味が滑るのを防ぐ)
  - **安全制約・禁則** (例: 特定モデルの使用禁止) — 要約で消えると事故る筆頭
  - Failed Attempts (要約は成功物語に圧縮しがち)
- **生きたハンドルの現在状態** (clear と逆でランタイムは生き残る):
  - worker が「どの ws で・何を持っていて・次の一手は何か」「未処理の指示があるか」
  - 走行中 Monitor / background task の一覧と、何を待っているか
  - 未コミット変更の所在と、誰がコミットする約束か
- Worker Topology は**ハンドル前提**で書いてよい (SendMessage 宛先はそのまま有効)

## 3. compaction 後の最初のターンで

自動注入は無いので、**compaction 直後の最初のターンで latest.md 経由で状態を Read し直す**
(summary に言及が残るとは限らない — 状態ファイル側が正、summary は補助)。同一セッション内の
再読なので loaded_by 追記は不要 (自分の session-id が既にあればそのまま)。

## 関連

- `pre-clear` skill — clear 前提の保存 (自己完結ブートストラップ側)。10 セクション定義の正本もそちら
- 由来: compact-plus プラグイン (github.com/u-ichi/compact-plus)
