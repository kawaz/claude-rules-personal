# op run の masking 挙動 (1Password CLI 2.34.1)

## 判明した事実

- **マスク解除フラグは `--no-masking`** (`--reveal` ではない)。`--reveal` は
  unknown flag エラー
- **マスク対象は値そのもの** であり、フィールド種別 (CONCEALED / STRING) は
  関係なく **すべての inject 値が stdout/stderr で置換** される
- **子プロセス内では env の値は実物** (sh の `$VAR` 展開は実値で動く、curl 認証
  等は正しく通る)。マスクは op が **stdout/stderr を後処理して置換** する形
- 置換文字列は `<concealed by 1Password>`
- **`$(op read "op://...")` 展開は masking を経由しない** ため、生値がシェル変数
  に入り、Claude の context / log / history に露出する経路になる

## 実用的な示唆 / ベストプラクティス

- `op run --env-file=.env -- cmd` が基本形 (env に `op://...` 参照を書く)
- 1 段目 (= デフォルト): 子プロセスは実値で動き出力は masked → AI が結果を読んでも
  値が context に乗らない。動作確認 / 認証経路の確認はこれで足りる
- 2 段目 (= `--no-masking`): 値そのものが log / 設定ファイル / 子プロセスを跨ぐ
  pipe 等で必要なときだけ。出力先 (リダイレクト先) を確認してから
- `$()` 展開は使わない (= masking を素通しする)

## 検証の詳細

### 環境

- op CLI version: 2.34.1
- 検証日: 2026-06-17
- テスト vault: `sandbox`
- テスト item: `service-a`
  - `username` (STRING, 値: "username")
  - `password` (CONCEALED, 値: "password")

### 検証コマンドと結果

**.env (テスト用)**:

```
TEST_USERNAME=op://sandbox/service-a/username
TEST_PASSWORD=op://sandbox/service-a/password
```

| ケース | コマンド | TEST_USERNAME 出力 | TEST_PASSWORD 出力 |
|---|---|---|---|
| A: デフォルト + sh -c echo | `op run --env-file=.env -- sh -c 'echo $TEST_USERNAME; echo $TEST_PASSWORD'` | `<concealed by 1Password>` | `<concealed by 1Password>` |
| B: `--no-masking` + sh -c echo | `op run --no-masking --env-file=.env -- sh -c '...'` | `username` | `password` |
| C: デフォルト + printenv (ヘルプ例の形) | `op run --env-file=.env -- printenv TEST_USERNAME TEST_PASSWORD` | `<concealed by 1Password>` | `<concealed by 1Password>` |
| D: `--reveal` 指定 | `op run --reveal --env-file=.env -- env` | (実行不可) | (実行不可) — `unknown flag: --reveal` |

### 考察

- ケース A vs C: cmd が sh / printenv どちらでも masking は効く → 子プロセスの
  種別ではなく op の stdout/stderr 後処理で置換している
- ケース A vs B: `--no-masking` で STRING (username) も生値が出る →
  「CONCEALED フィールドだけマスクされ STRING はそのまま」は誤り。**全 inject 値が
  マスク対象**
- ケース D: `--reveal` は 1Password 8.x の文書 / 過去 version で見かける名前
  かもしれないが、op CLI 2.34.1 のヘルプ例は `--no-masking` を一貫して使用

### 影響範囲

- 本検証は op 2.34.1 単一 version のみ。複数 version での再検証は未済 (= サンプル
  数原則 N=1)。`--reveal` が別 version で alias として残っている可能性は未確認
- 検証は `sh -c echo` / `printenv` の 2 cmd のみ。複雑な pipe / process
  substitution / `tee` 経由で masking がどう振る舞うかは別途検証必要

## 関連

- [[secret-hygiene]] — 本 finding を運用ルール化したもの
- [[empirical-verification]] — N=1 で結論化しない原則 (= 本 finding も N=1 なので、
  別 version / 別 cmd で追試する余地あり)
