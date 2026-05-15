# setup.sh で skills/ も配置できるように拡張する

## 背景

`setup.sh` は現状 `for-all/rules/`, `for-me/rules/`, `for-others/rules/` のみを
`$TARGET/rules/` 配下にシンボリックリンクで配置する。

claude-rules-emeradaco 等のオーバーレイで slash command 用のスキルを
`for-me/skills/<slug>/SKILL.md` に置きたいケースが出てきたが、setup.sh は
これを認識しないため手動 `ln -s` が必要。

## 課題

- `for-*/skills/` を新設しても自動配置されない
- 各オーバーレイで個別に対応すると重複・差異が出る

## 対応案

`setup.sh` を rules と同じパターンで skills も対応させる。

```
$TARGET/skills/for-all-from-<name>     → <repo>/for-all/skills
$TARGET/skills/for-me-from-<self>      → <self>/for-me/skills
$TARGET/skills/for-others-from-<name>  → <repo>/for-others/skills
```

Claude Code がユーザースキルを `$TARGET/skills/<...>/SKILL.md` 形式で再帰検出するか
要確認 (現状の `~/.claude-emeradaco/skills/<slug>/SKILL.md` は直置きパターン)。
ネストするとロードされない場合はフラット配置 (`$TARGET/skills/<slug>` → 各リポの
`for-*/skills/<slug>`) に変更する。

## 優先度

低。今は手動 `ln -s` で十分。複数オーバーレイで skills 配置が増えてきたら着手。

## 関連

- 初出: emeradaco `for-me/skills/emeradaco-fix-prep/` を手動配置した 2026-05-14
