---
name: app-file-placement
description: アプリのファイル置き場 (設定 / データ / 状態 / キャッシュ / socket・pid) を決める時に読む。XDG Base Directory の使い分け、env フォールバックの 3 段規約、macOS で XDG_RUNTIME_DIR が無い時の代替を扱う。
---

# アプリのファイル置き場 リファレンス

新しいファイルを吐くコードを書く前に、まず「これはどのカテゴリか」を決める。
正本は XDG Base Directory Specification v0.8 (2021-05)。

## 5 カテゴリの判断軸

| カテゴリ | env (default) | 判断軸 | 例 |
|---|---|---|---|
| config | `XDG_CONFIG_HOME` (`~/.config`) | **人が手で編集する宣言的な設定**。アプリが勝手に書き換えないもの | `config.json`, 許可 origin リスト, プロファイル定義 |
| data | `XDG_DATA_HOME` (`~/.local/share`) | **失うと取り返せない**ユーザ資産。再生成不能 | 蓄積ログ本体, ユーザが作った文書, エクスポート/dump 出力 |
| state | `XDG_STATE_HOME` (`~/.local/state`) | 再起動をまたいで**残ってほしいが、失っても不便なだけ**。data ほど重要でも可搬でもない | 実行ログ, コマンド履歴, 最近使ったもの, 前回のウィンドウ配置, undo 履歴, pid/lock/sock |
| cache | `XDG_CACHE_HOME` (`~/.cache`) | **消えても再生成できる**。いつ消されても正しく動く必要がある | ダウンロード済みアーティファクト, 変換結果, index |
| runtime | `XDG_RUNTIME_DIR` (既定値なし) | **ログインセッションに寿命が縛られる** file object | unix socket, named pipe, pid/lock |

spec の原文どおりの要点:

- state の例として spec 自身が挙げるのは "actions history (logs, history, recently used files, …)" と
  "current state of the application that can be reused on a restart (view, layout, open files, undo history, …)"。
  **「ログと履歴は state」** が公式の線引き。
- cache は "user-specific non-essential data files"。**non-essential** が判定語。
- 検索パス系 (`XDG_DATA_DIRS` 既定 `/usr/local/share/:/usr/share/`、`XDG_CONFIG_DIRS` 既定 `/etc/xdg`) は
  「システム側にも同名の設定/データが置かれうる」アプリだけが要る。単一ユーザ向け CLI では通常不要。
  先頭が最優先で、`XDG_CONFIG_HOME` は `XDG_CONFIG_DIRS` の全てに優先する。
- **これらの env に入る値は絶対パス必須**。相対パスが入っていたら invalid として無視する
  (= `${XDG_STATE_HOME}` を無検証で使わず、相対なら default にフォールバックする)。

## フォールバックは 3 段で書く

```
${APP_X_DIR:-${XDG_X_HOME:-$HOME/デフォルト}/appname}
```

1. **アプリ個別 env** (`CCMSG_STATE_DIR` 等) — テストや一時的な隔離で丸ごと差し替えるための直接指定。
   ここには appname を**足さない** (指定された場所そのものを使う)。
2. **XDG env** — 指定があればその下に `appname/` を掘る。
3. **spec 既定値** — `$HOME/.config` 等。

実例 (kawaz/ccmsg `packages/protocol/src/paths.ts`):

```ts
export function resolveStateDir(env = process.env): string {
  if (env.CCMSG_STATE_DIR) return env.CCMSG_STATE_DIR;
  const base = env.XDG_STATE_HOME || path.join(os.homedir(), ".local", "state");
  return path.join(base, "ccmsg");
}
```

同型の `resolveConfigDir` / `resolveDataDir` を並べ、`resolvePaths()` が個々のファイル名まで
解決して返す。**パス組み立てをアプリ全体で 1 箇所に集約する**のが要点 (各所で `path.join` すると
必ずズレる)。ファイルごとの「なぜこのカテゴリか」はその型のコメントに 1〜2 行で残す。

## macOS の runtime: `XDG_RUNTIME_DIR` は無い

実測 (macOS 15, 2026-08-31): `XDG_RUNTIME_DIR` は**未設定**。systemd の pam モジュールが
設定するものなので、Linux 以外では期待できない。spec も「未設定なら同等の代替ディレクトリを
使い warning を出せ」としか言っていないので、代替は自前で決める。

**代替: `${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/{appname}-{uid}`**

```sh
runtime_base="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
runtime_dir="$runtime_base/myapp-$(id -u)"
mkdir -p "$runtime_dir" && chmod 700 "$runtime_dir"
```

根拠 (同環境で実測):

- macOS の `TMPDIR` は **per-user** (`confstr(_CS_DARWIN_USER_TEMP_DIR)` 由来、
  `getconf DARWIN_USER_TEMP_DIR` で同値が取れる)。実測値
  `/var/folders/dh/.../T/`、`ls -ld` は `drwx------ kawaz staff` = 既に 0700 の自分専用。
  つまり macOS では `TMPDIR` 自体が XDG_RUNTIME_DIR の要件をほぼ満たす。
- **`-{uid}` を付ける理由**: `TMPDIR` が per-user でない環境 (Linux の多くは `/tmp`、
  コンテナ、`TMPDIR` 未設定でのフォールバック `/tmp`) では全ユーザ共有になる。
  uid 込みの名前にしておけば、他ユーザが先に `myapp/` を作って居座る乗っ取りを避けられる。
  ユーザ名でなく **uid** を使うのは、ユーザ名に path 不正文字が入りうるため。
- **`chmod 700` は自分で行う** (spec: "Its Unix access mode MUST be 0700")。
  親が 0700 でも、そこを当てにしない。
- spec は「reboot / 完全ログアウトで消えて**よい**」と定めている。だから
  runtime に置くのは**消えても再取得できるもの限定** (socket, pid, lock)。
  「再起動後もこの情報が要る」ものは state。

### unix socket の path 長制限

`sun_path` は macOS で **104 bytes** (`sys/un.h` で実測)、Linux で 108。
macOS の `TMPDIR` は `/var/folders/xx/<28文字>/T/` と長いので、
`$TMPDIR/myapp-501/daemon.sock` でこの上限に迫る。socket を置くときは
**組み立てた絶対パスの長さを検査**し、超えるなら `/tmp/{appname}-{uid}/` に退避する。

## 迷いやすい判例

| 対象 | 置き場 | 理由 |
|---|---|---|
| `config.json` (人が編集) | config | 宣言的設定。**アプリが起動時に自動生成して書き戻すもの**でも、人が編集する前提なら config |
| 許可リスト・プロファイル定義 | config | 同上。「消えたらユーザが書き直す」性質 |
| API token / 認証情報 | 専用扱い | 平文で config に置かない。OS keychain / secret manager 経由。やむなく file なら 0600 で state か専用 dir |
| unix socket / pid / lock | runtime (無ければ state) | セッション寿命。**state に置く判断も可** (ccmsg は `daemon.sock`/`pid`/`lock` を state に置いている — 単一マシン常駐 daemon で TMPDIR の掃除に消されたくないため。どちらを選んでも良いが、選んだ理由をコメントに残す) |
| 実行ログ (`daemon.log`) | state | spec が "logs" を state の例に明記 |
| コマンド履歴 | state | 同上 ("history") |
| 蓄積されるメッセージ・ルーム等の本体 | data | 失うとユーザの情報が消える |
| `dump` / `export` の出力 | data | パスを人に渡して後で読み返す前提 = 失ってはいけない |
| 「前回接続していたセッション一覧」 | state | 再起動をまたぐ必要はあるが、失っても不便なだけ ("recently used" と同カテゴリ) |
| ダウンロードキャッシュ・変換結果 | cache | 消えても再生成可 |
| DB / index (再構築に数時間) | data か cache | **再構築可能でも、コストが許容できないなら data**。「消されても正しく動く」だけでは cache の条件を満たさない |

**代表的な誤配置**: `config.json` を data に置く。「アプリが JSON を書き込んでいる」ことを根拠に
data だと判断してしまう罠 (実例: ccmsg。config へ移設して解消)。
判断軸は**誰が書き換える前提か**であって、書き込みの有無ではない。

## 置き場を変えるとき (移行)

パスを変えたら、旧パスからの自動移行を入れる。定石:

1. 解決した新パスに対象が**無く**、旧パスに**ある**ときだけ発動する
2. `rename(2)` で移動を試み、cross-device なら copy + unlink にフォールバック
3. 移動したことを 1 行 stderr に出す (黙って動かすとユーザが探せなくなる)
4. cache カテゴリは移行しない (再生成させる方が安い)

移行コードは「発動条件を満たさなければ何もしない」ので恒久的に残して構わないが、
条件判定を毎起動の同期 I/O でやらないよう、既に新パスがある場合の early return を先に置く。

## 関連

- `docs-structure` skill — リポ内の docs/ 配置 (本 skill は実行時ファイルが対象)
