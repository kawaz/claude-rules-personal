---
name: pre-clear
description: /clear の前にセッション状態を XDG_CACHE_HOME へ保存する (ゼロコンテキスト読者向けの自己完結ブートストラップ)
---

# pre-clear — /clear 前のセッション状態保存

`/clear` でセッションを捨てる前に、次セッションがゼロコンテキストから立ち上がるための
状態ファイルを書く。compact と違い**要約が一切残らない**前提なので、自己完結で書く。

## 0. 前提チェック (書く前に判定)

/clear は「区切り」でのみ行う。以下が汚れているなら、先に片付けるか /compact 側に倒す:

- 未コミット / 未 push の変更 (`jj status` / `git status`) — 残すなら理由と場所を明記
- 走行中の worker・background task — 完了を待つか、状態を直列化しきれないなら compact
- 進行中のユーザとの議論 (未決の論点) — 状態ファイルに論点として書けるなら clear 可

## 1. 保存先と命名

```
dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude-session-state/<project-slug>/
```

- `<project-slug>` = **リポジトリのディレクトリ名そのまま** (例: `kuu` / `kuu.mbt` / `kuu-cli` は
  それぞれ別ディレクトリ)。短縮・統合しない — 名前が前方一致する姉妹リポ群 (kuu 系等) で
  「別リポのセッションが隣の state を自分のものと誤認してロードする」事故の予防。
  複数リポを統括するセッション (例: spec + 実装の共進化) は **cwd のリポ**の slug に置き、
  他リポの状態は本文 (§2 Current Phase) に書く
- 状態本文は `<YYYYMMDD-HHMM>.md` に書く (immutable、履歴として残す)
- **`latest.md` は本文を持たないポインタファイル**。`repo:` は管轄リポの絶対パス
  (ロード側の照合キー):

```
repo: /абс/path/to/repos/github.com/<owner>/<repo>
state: <YYYYMMDD-HHMM>.md
loaded_by:
```

- cache 置きは意図的: 消えても journal / メモリ / VCS 履歴から復元可能な**運用状態のみ**を書く。
  永続知識 (設計判断・教訓) は journal / DR / メモリへ — ここに退避しない

### ロード側プロトコル (多重ロード防止 + 継続作業指示の即実行)

1. `latest.md` を読み、まず **`repo:` と自分の cwd を照合**する — cwd が `repo:` 配下で
   なければ**別プロジェクトのハンドオフ**なので読まなかったことにして通常立ち上げ
   (姉妹リポの state を誤って引き継ぐのが最悪の事故)。`repo:` フィールドが無い旧形式は
   状態本文の §2 Current Phase のリポ名で同じ照合をする
2. **cwd 照合 OK かつ `loaded_by:` が空なら**: `state:` の実体を Read し、直後に
   `loaded_by:` へ 1 行追記 (`  - <ISO時刻> <自分の session-id>`)。以後このハンドオフは
   自分のもの
3. **他セッションの記録が既にあるなら**: このハンドオフは**その系列に消費済み**なので
   自分のハンドオフとして採用しない (その系列はクラッシュしても `claude --continue` で
   同一セッションとして続くため、状態はそちらが正)。journal / メモリ / リポの実機確認から
   通常どおり立ち上がる
4. **`loaded_by:` 追記後の分岐**:
   - **§継続作業指示 (§10 Recovery Notes 内) があれば即実行**: kawaz の追加確認を
     待たず、暗黙 approve として扱って作業に入る (前セッションが「次はこれをやれ」
     と明示している以上、それが最新のユーザ意図)。並行で Monitor / subscribe 等の
     再起動もそこで済ませる
   - **なければ**: 次アクション候補の優先度を提示して kawaz 判断待ち

> Why: ハンドオフは「1 つの後継セッション」宛て。多重ロードすると 2 系列が同じ状態から
> 分岐して同一 ws を取り合う。クラッシュ復旧は --continue の領分であり、状態ファイルの
> 更新頻度で守るものではない。

## 2. 内容 — 10 セクション (compact-plus 由来) + clear 固有の力点

```
1. Active Plan          — 大目標と現在地 (1 段落)
2. Current Phase        — 各リポの head (コミット hash)・push/CI 状態・未コミットの有無
3. TaskList Summary     — 完了 / 残タスク
4. Session Decisions    — ユーザ裁定・設計確定を原文の要点で (DR/issue への参照付き)
5. Constraints/Blockers — 禁則 (安全制約は特に)・gate・運用ルール
6. Worker Topology      — ★clear 固有: ハンドルは失効するので「再 spawn 手順」として書く
                          (agent 定義名・使い分けの実績・委譲プロンプトの型)
7. Skills Invoked       — 使った skill と、その中で得た運用知見 (罠・定石)
8. Editing Files        — 主要ファイルと設計正本の所在
9. Failed Attempts      — 試して駄目だった事と理由 (再発防止。要約が無いので特に厚く)
10. Recovery Notes      — ★clear 固有: 一次資料を読む順序 (立ち上げの最短経路)、
                          Monitor/subscribe の再起動要否、各 workspace の @ 位置。
                          **§継続作業指示 (即実行対象、暗黙 approve) を必ず明示的
                          小節として立てる** — 「次セッションで即やる作業がある」
                          「無いから候補提示」のどちらかを断定する形で書く
                          (ロード側プロトコル §1 Step 4 の分岐がここで判定される)
```

文体はゼロコンテキストの初見読者向け (略語・セッション内の造語を持ち込まない)。

## 3. 発見経路の確保

新セッションが自力で辿り着けるよう、**プロジェクトメモリに latest.md へのポインタ**が
あることを確認する (無ければ 1 行追加: 「セッション開始時に
`~/.cache/claude-session-state/<slug>/latest.md` があれば読む」)。

## 4. 完了報告

保存パスを提示し「/clear どうぞ」と伝える。/clear 自体はユーザ操作。**§10 Recovery
Notes 内の §継続作業指示に何を書いたか (or 書かなかったか) を報告に含める** — 次
セッションが立ち上げ後に即実行する内容として kawaz が事前に把握できるよう。

## 関連

- `pre-compact` skill — compact 前提の保存 (力点が逆: 要約の補正レイヤ)
- 由来: compact-plus プラグイン (github.com/u-ichi/compact-plus) の 10 セクション構成
