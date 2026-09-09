# CLI の daemon / service サブコマンド体系

出典: kawaz 発言 (ccmsg room r285 mid 27, 2026-09-09) を起こしたもの。仕様は ccmsg v2 で確定待ち。

## 目的

起動済み daemon の status 確認や再起動が、設定ファイルの場所を知らないと行えないのは面倒。ゼロ知識の状態から `<tool> daemon status` / `<tool> daemon restart` だけで到達できるようにするのがこの体系の狙い。単位は **1 instance = 1 unit**、`<tool> — one instance per <unit>` と表現する。kawaz 製 CLI (ccmsg v2 / hyoui / cache-warden / llm-gateway 等) に共通適用する。

## USAGE / 出力規約

```
<tool> <command> [subcommand] [options] [--] [args...]
```

- 引数なし / `--help` はテキストの help。それ以外の出力は **JSON または JSONL**
- エラーも JSON。stderr に出し、exit≠0
- **子を持つレベル**と**必須引数のあるコマンド**は、引数なしで help
- **省略可能な引数だけのコマンド**は、引数なしで実行

```
COMMANDS
  daemon      instance (= 1 <unit>) のプロセス操作
  service     OS への常駐登録 (launchd / systemd --user)。監督者を登録する
  ...         ツール固有のコマンド
```

## `<tool> daemon`

| サブコマンド | 説明 |
|---|---|
| `run [unit]` | この unit の instance を foreground で起動する (未指定の場合はデフォルト) |
| `supervise` | foreground の監督者: 登録された instance を子として起動し、落ちたら上げる |
| `add <unit>` | 登録する |
| `remove <unit>` | 登録を外す |
| `list` | → `[{id, unit, running, pid}]` |
| `start <unit> \| --all` | 登録 instance を detached で起動する |
| `stop <unit> \| --all` | 停止を要求する (対象プロセスの停止を待つかはツールの要件次第) |
| `restart <unit> \| --all` | stop → start |
| `status [<unit>] \| --all` | → `[{id, unit, running, pid, version, ...}]` |
| `log [<unit>] \| --all` | instance のログ |

## `<tool> service`

| サブコマンド | 説明 |
|---|---|
| `register` / `unregister` | 監督者 (`<tool> daemon supervise`) を launchd / systemd に登録する |
| `start` / `stop` | 監督者の起動 / 停止 |
| `status` | → `{registered, running, pid, service: {OS 側の loaded, running, pid, last_exit}, instances: [...]}` |
| `log [--follow]` | 監督者と OS 側のログ |

## 共通オプション

| オプション | 説明 |
|---|---|
| `--all` | 登録 instance 全部を対象にする |
| `--follow` | log で追従する |
| `--help` | そのレベルの help |

## unit の定義

unit = **登録の単位**で、案件ドメインが決める (dir / config ファイル / id など)。

## 署名済み launcher の構成 (検討)

ドメイン要件によっては、launchd に登録する **署名済み launcher** を別途用意してそれを登録し、launcher は `<tool> daemon supervise` の起動と死活監視に徹する形も検討する。FDA 要求などがバージョンアップ毎に発生するのを回避するための構成。

## 改定候補: start / stop を supervise への操作にする (r285 mid 32〜34、検討中)

上の `<tool> daemon` 表は起票時点の形。その後 kawaz が次の変更を提案している
(「どう思う?」段階、確定は ccmsg v2 待ち):

- `daemon start / stop` (status / restart も同様) は **起動中の supervise に対する操作**
  にする方が収まりが良い。`add` した unit を起動するトリガーが `start` になる
- supervise が未起動なら `status` / `stop` は**エラー終了でよい**
- 手元で instance を単体起動するのは `run` で足りる。supervise が子を上げるのも
  `run` を起動するだけ

## 採用側で決まった補足 (llm-gateway)

体系本体ではなく、採用側ツールで個別に決まった事項:

- unit の設定に `binary_path` を持つ (既定は自分自身)
- restart 戦略や優先順位はツール固有
- 既存の `status` 系コマンドとの語彙衝突は `upstream status` 等に寄せる
- unit の既定値は「登録が 1 つならそれ、複数なら名前か `--all` を要求」

## 関連

- [[cli-design-preferences]] — CLI 設計の好み (サブコマンド構成・`--help` 表示・オプション・補完)
