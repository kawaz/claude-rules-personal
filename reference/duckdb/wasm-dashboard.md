# DuckDB-WASM のダッシュボード (artifacts に置いて Parquet をブラウザで集計する)

[data-lake](data-lake.md) の形で溜めた Parquet を、サーバ側に集計のプロセスを置かずに、ブラウザの中の DuckDB-WASM で読んで画面にする形。置き場と配信は reference の `artifacts/workspace` (artifacts workspace と caddy-app-proxy) に乗る。

## 構成

```
<repo>/main/dashboard/            # ソース (版管理する)
  package.json  build.ts  index.html  src/*.ts
<repo>/artifacts/dashboard/       # 成果物 (版管理しない)。https://artifacts-<owner>-<repo>.<host>.tmpspace.net/dashboard/
  index.html  app.js  styles.css
  data/scans   -> <data_dir>/scans     # 記録の層への symlink (層ごとに張る)
  data/daily   -> <data_dir>/daily
  data/monthly -> <data_dir>/monthly
```

- ソースは main で書いて版管理し、ビルドの成果物だけを artifacts に置く。置く処理は justfile のレシピにする (型検査・lint・テスト・ビルド・配置を 1 本で)
- 成果物の置き換えでは、前の成果物のうち今回無いものを消すが、**`data/` は対象にしない**。ビルドが `data/` を作ったら止める (symlink を上書きしないため)。`index.html` は最後に置く (新しい `index.html` が古い `app.js` を読む間を作らない)
- 成果物の URL は `app.js?v=<hash>` の形でキャッシュを切る (reference の `webui-structure`)

## data は symlink で配信する

artifacts の運用は「中に symlink を置かない (file_server が追って配信してしまう)」だが、ダッシュボードの data は**記録を配信すること自体が目的**なので、意図して symlink を置く (写しを作ると写し直しの仕組みが要り、実体とずれる)。

- つなぐのは記録の層 (`scans` / `daily` / `monthly`) だけ。データディレクトリ全体をつなぐと、ロックファイル・移行前の DB・書き出し先まで配信される
- まだ無い層 (`monthly` は月をまたぐまで無い) は、先の無い symlink のままでよい (一覧が 404 になるのを空として扱う)
- caddy の file_server は symlink の先も 200 で返し、Range にも 206 で答える。CORS を許した別サブドメインは要らない

## 読むファイルの一覧

DuckDB-WASM は HTTP 越しに glob (`*.parquet`) ができないので、読むファイルの一覧を別に作って 1 つずつ登録する。

- caddy の file_server のディレクトリに `Accept: application/json` で GET すると、`[{"name","size","url","mod_time","is_dir",...}]` が返る。層 × 表のディレクトリを 1 つずつ一覧にする
- 一覧の取り方は 1 つのモジュールに閉じ込める (書き手が `manifest.json` を書くようになったら差し替えるため)
- 一覧は外から来るデータなので、スキーマに通してから使う (valibot 等。reference の `typescript/_index.md`)。`.parquet` で終わるファイルだけを拾う (書きかけの `.parquet.tmp` を読まない)
- 一覧と取得の間に、書き手のまとめ直しが元のファイルを消すことがある (ロックはブラウザから取れない)。取得の 404 では一覧を取り直して 1 回だけやり直す
- 同じ記録が 2 つのファイルに入っていることがある (まとめ直しの途中で落ちた時)。読む側は記録の id で重複を除く。除き方は書き手 (CLI 側) と同じ規則にする

## DuckDB-WASM の読み込み

```ts
import * as duckdb from "@duckdb/duckdb-wasm";

const bundle = await duckdb.selectBundle(duckdb.getJsDelivrBundles());
// 別 origin の worker は直接起動できないので、importScripts するだけの worker を Blob URL で作る
const workerUrl = URL.createObjectURL(
  new Blob([`importScripts(${JSON.stringify(bundle.mainWorker)});`], { type: "text/javascript" }),
);
const db = new duckdb.AsyncDuckDB(new duckdb.ConsoleLogger(), new Worker(workerUrl));
await db.instantiate(bundle.mainModule, bundle.pthreadWorker);
URL.revokeObjectURL(workerUrl);

const conn = await db.connect();
await conn.query("SET autoinstall_known_extensions = false; SET autoload_known_extensions = false");
await conn.query("LOAD parquet"); // DuckDB-WASM に Parquet の読み込みは組み込まれていない
// 各ファイルを db.registerFileURL(name, url, duckdb.DuckDBDataProtocol.HTTP, false) で登録してから
// read_parquet([...names], union_by_name = true) で読む
```

- **WASM と worker は jsDelivr の CDN から、版を固定した URL で読む** (`getJsDelivrBundles()` はパッケージ自身の版で URL を組む)。`@duckdb/duckdb-wasm` は `package.json` で exact に固定する
- ブラウザの HTTP キャッシュは、読み込んだページのサイト (スキーム + 登録ドメイン) ごとに分かれる。artifacts のページはどれも `tmpspace.net` (Public Suffix List に無い) の下なので、**どのリポのダッシュボードから読んでも、URL が同じならキャッシュは 1 つ**。リポごとに同梱すると、リポの数だけ数十 MB ずつキャッシュされる
- そのため**ダッシュボードどうしで `@duckdb/duckdb-wasm` の版を揃える**。版を上げる時は全部のダッシュボードを一緒に上げる。今の版は `1.33.1-dev57.0` (2026-11-13 時点で npm の `latest` タグが指す版。中の DuckDB は v1.5.4)
- `LOAD parquet` は DuckDB の拡張の配布元 (`extensions.duckdb.org`) から拡張を取る。jsDelivr とあわせて 2 か所へ通信する
- 転送量の目安: WASM が br 圧縮で約 6 MB (展開後 36 MB)、worker 約 160 KB、parquet 拡張 約 520 KB。初回の表示まで、キャッシュ無しで約 2 秒、キャッシュありで 1 秒前後 (記録 1 MB 程度の時)

## 集計の規則を CLI と揃える

CLI (`report` 等) と同じ集計をダッシュボードでも出すと、集計の規則が CLI の言語と TypeScript の 2 か所にできる。

- ダッシュボード側に、CLI のテストと同じ入力・同じ期待値のテストを置き、規則の食い違いを検出する
- 規則を変える時は両方を同じ変更で直す
