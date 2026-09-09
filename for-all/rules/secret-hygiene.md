# Secret 取扱

## 原則: op run の透過運用に倒す

機微情報 (TOKEN / PASS / SECRET / KEY / CREDENTIAL / 認証鍵) は **op run の env インジェクト経由で透過**させ、AI は値を直接ハンドリングしない。

op run はデフォルトで **子プロセスの stdout/stderr に現れた値を `<concealed by 1Password>` に置換** する (値ベースの後処理マスク、フィールド種別 CONCEALED / STRING 問わず全部マスクされる)。子プロセス内では値は実物なので、curl 認証や API 呼び出しは正しく動く。つまり `--no-masking` を付けない限り、AI が `op run -- cmd` の出力を読んでも値は context に乗らない。

**間違い**: `SOMEVAR=$(op read "op://...")` の `$()` 展開は op の masking フィルタを経由せず生値が shell 変数に入る (= AI / log / history に露出)。`op://` 参照は env に書いて op run 経由で渡す。

op run 経由の具体手順 (env-file の書き方、`--no-masking` を付ける / 付けない 2 段運用) は reference の `op-run-secret-injection` ([[knowledge-guide]] のパス) を読む。

## 機微キーワード (反応対象)

以下を扱う前に「`$()` 直展開していないか / op:// 参照経由か」を確認:

- 大文字略語 (単語境界マッチ): `TOKEN`, `PASSWORD`, `PASS`, `SECRET`, `KEY`, `CREDENTIAL`, `AUTH`, `PRIVATE` (`keyword` / `keymap` 等の一般語は除外、`PUBLIC_KEY` は対象外)
- ファイル / パス: `.env*`, `*.pem`, `*.key`, `id_*` (ssh 鍵), `*credentials*`, `*secret*`

## ユーザが直接 credential を貼ってきた場合

Claude は rotate / revoke を勝手に試みず、kawaz に以下を依頼:

1. **op への登録**: 当該 credential を 1Password vault に保存、今後は `op://...` 参照経由に切替
2. **当該セッション jsonl のクリーニング**: セッションログから該当値を削除 (= context に残ったままだと後続セッションで再露出)
