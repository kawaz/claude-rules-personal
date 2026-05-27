---
name: jj-rebase-options-reference
description: jj のリビジョン指定オプション (= `-r` / `-s` (`--source`) / `-b` (`--branch`) / `-f` (`--from`) / `--onto` (`-o`, `-d`) / `--insert-after` (`-A`) / `--insert-before` (`-B`) / `--into` (`-t`, `--to`)) の完全リファレンス (jj v0.38.0)。各オプションが対象指定 (何を) と場所指定 (どこへ) のどちらの軸に属するか、どのコマンドで利用可能か、デフォルト値、複数指定時の挙動、エイリアスの整合性。`jj rebase` / `jj duplicate` / `jj split` / `jj squash` / `jj revert` / `jj new` の配置オプションを使う時、複数コミットを移動するときの挙動を確認したい時、`-r` と `--source` / `--branch` の違いを思い出したい時に使う。
---

# jj リビジョン指定オプション リファレンス (v0.38.0)

## 概要: 2つの軸

jj コマンドのリビジョン指定は大きく2つの軸に分かれる。

1. **対象指定（何を）**: 操作するコミットの選択
2. **場所指定（どこへ）**: コミットの配置先

ほとんどのコマンドは対象指定のみ。場所指定も持つのは rebase, duplicate, split, squash, revert, new の6コマンド。

---

## 対象指定（何を）

### `-r` / 位置引数: 個別コミット指定

ほぼ全コマンド共通。位置引数と `-r` は同一（位置引数の alias が `-r`）。

| コマンド | 単数/複数 | デフォルト | 備考 |
|---|---|---|---|
| abandon | 複数 | `@` | |
| describe | 複数 | `@` | |
| duplicate | 複数 | `@` | |
| edit | 単数 | なし（必須） | @ の移動先。対象は「カレントコミットの向き先」 |
| metaedit | 複数 | `@` | |
| new | 複数 | `@` | 位置引数 = `-r` = `-o`（全て同一）。新コミットの親指定 |
| parallelize | 複数 | なし | |
| show | 単数 | `@` | |
| split | 単数 | `@` | |
| squash | 単数 | `@` | `-o`/`-A`/`-B` と排他 |
| rebase | 複数 | なし | `--source`/`--branch` と排他 |
| revert | 複数 | なし | |
| sign/unsign | 複数 | 設定依存 | |
| bookmark set/create | 単数 | `@` | alias: `--to` |
| bookmark list | 複数 | なし | フィルタ用 |
| tag list | 複数 | なし | フィルタ用 |
| log | 複数 | 設定依存 | フィルタ用 |
| evolog | 複数 | `@` | |
| diff | 複数 | `@` | `--from`/`--to` と使い分け |
| diffedit | 単数 | `@` | `--from`/`--to` と使い分け |
| resolve | 単数 | `@` | |
| fix | なし | — | `--source` のみ |
| simplify-parents | 複数 | 設定依存 | `--source` と併用可 |
| file show/list/chmod/search/annotate | 単数 | `@` | |
| git push | 複数 | なし | bookmark フィルタ用 |
| workspace add | 複数 | なし | 新 WC の親 |

#### edit / new の特殊性

edit と new は `-r` を取るが、他のコマンドとはレイヤーが違う:
- **他のコマンド**: 指定コミット自体を操作する（describe で説明を書く、split で分割する等）
- **edit**: @ をそのコミットに移動する（ワークスペースの切り替え）
- **new**: 指定コミットを親に持つ空コミットを作り、@ をそこに移動する

どちらも「カレントコミット（@）の向き先を変える」操作であり、指定コミット自体への変更ではない。

### `--source` (`-s`): ツリー選択

指定コミット＋全子孫をまとめて選択。

| コマンド | 複数指定 | デフォルト |
|---|---|---|
| rebase | 可 | なし（`--branch` `@` がデフォルト） |
| fix | 可 | 設定依存 |
| simplify-parents | 可 | なし（`-r` と併用可） |

### `--branch` (`-b`): 共通祖先からの自動選択

destination との共通祖先を自動計算し、そこから先を選択。

| コマンド | 複数指定 | デフォルト |
|---|---|---|
| rebase | 可 | `@`（`-r`/`-s` 未指定時のデフォルト） |

rebase 専用。対象が destination によって動的に変わる唯一のモード。

### `--from` (`-f`): 変更の取得元

「このコミットの差分を取り出す」という意味。

| コマンド | 単数/複数 | デフォルト |
|---|---|---|
| squash | 複数 | `@` |
| restore | 単数 | `@` の親（`--into` 未指定時） |
| absorb | 単数 | `@` |
| diff | 単数 | なし |
| diffedit | 単数 | なし |
| interdiff | 単数 | `@` |
| bookmark move | 複数 | なし（現在位置で対象選択） |

### rebase の対象指定まとめ（排他的）

| モード | 対象範囲 | 子の扱い | デフォルト |
|---|---|---|---|
| `-r` | 指定コミットのみ（each） | 子は元親に穴埋め接続 | — |
| `--source` | 指定コミット＋全子孫（ツリー） | 一緒に移動 | — |
| `--branch` | destination との共通祖先から先（自動ツリー） | 一緒に移動 | `@`（何も指定しない時） |

---

## 場所指定（どこへ）

### 配置3兄弟: `--onto` / `--insert-after` / `--insert-before`

コミットのグラフ上の位置を決める。

| オプション | short | エイリアス | 動作 | 既存の子への影響 |
|---|---|---|---|---|
| `--onto` | `-o` | `-d`, `--destination`※ | 指定先の子として配置 | なし |
| `--insert-after` | `-A` | `--after` | 指定先の後に挿入 | 既存の子が挿入末端の子に再接続 |
| `--insert-before` | `-B` | `--before` | 指定先の前に挿入 | 指定先が挿入末端の子に再接続 |

※ `--destination` は rebase 以外（duplicate/split/squash/revert）のみ。rebase は `-d` のみ（hidden alias）。

#### 配置3兄弟を持つコマンド

| コマンド | `--onto` | `-A` | `-B` | 必須 |
|---|---|---|---|---|
| rebase | ○ | ○ | ○ | いずれか1つ以上必須 |
| revert | ○ | ○ | ○ | いずれか1つ以上必須 |
| duplicate | ○ | ○ | ○ | オプショナル（未指定時は既存親を維持） |
| split | ○ | ○ | ○ | オプショナル |
| squash | ○ | ○ | ○ | オプショナル（EXPERIMENTAL） |
| new | — | ○ | ○ | オプショナル。 |

#### 複数指定時の挙動（`-r` で複数コミットを移動する場合）

| 配置オプション | 指定コミット間に親子関係あり | 親子関係なし |
|---|---|---|
| `--onto` | チェーン（直列）で配置 | 並列（兄弟）で配置。既存の子は影響なし |
| `--insert-after` | チェーンで挿入 | 並列で挿入。既存の子がマージコミット化 |
| `--insert-before` | チェーンで挿入 | 並列で挿入。挿入先がマージコミット化 |

### 転送先: `--into` / `--to`

変更内容の反映先（コミット配置ではなく差分の転送）。

| コマンド | プライマリ名 | short | エイリアス | デフォルト |
|---|---|---|---|---|
| squash | `--into` | `-t` | `--to` | `@` |
| restore | `--into` | `-t` | `--to` | なし |
| absorb | `--into` | `-t` | `--to` | `mutable()` |
| diff | `--to` | `-t` | — | なし |
| diffedit | `--to` | `-t` | — | なし |
| interdiff | `--to` | `-t` | — | `@` |
| bookmark move | `--to` | `-t` | — | `@` |
| bookmark set/create | `--to` (alias) | — | `-r` のエイリアス | `@` |

---

## エイリアス一覧

| プライマリ名 | short | エイリアス | 備考 |
|---|---|---|---|
| `--onto` | `-o` | `-d`, `--destination` | `--destination` は rebase 以外のみ |
| `--insert-after` | `-A` | `--after` | |
| `--insert-before` | `-B` | `--before` | |
| `--source` | `-s` | — | |
| `--branch` | `-b` | — | rebase 専用 |
| `--from` | `-f` | — | |
| `--into` | `-t` | `--to` | squash/restore/absorb |
| `--to` | `-t` | — | diff/diffedit/interdiff/bookmark move |
| `--revision(s)` | `-r` | 位置引数の alias | |
