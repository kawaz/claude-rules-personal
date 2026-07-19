# Secret 取扱

## 原則: op run の透過運用に倒す

機微情報 (TOKEN / PASS / SECRET / KEY / CREDENTIAL / 認証鍵) は **op run の
env インジェクト経由で透過**させ、AI は値を直接ハンドリングしない。

op run はデフォルトで **子プロセスの stdout/stderr に現れた値を
`<concealed by 1Password>` に置換** する (値ベースの後処理マスク、フィールド
種別 CONCEALED / STRING 問わず全部マスクされる)。子プロセス内では値は実物
なので、curl 認証や API 呼び出しは正しく動く。

つまり `--no-masking` を付けない限り、AI が `op run -- cmd` の出力を読んでも
値は context に乗らない。

## 使い方

env に `op://...` 参照を書いて op run に解決させる:

```bash
# .env に op:// 参照
SOMEVAR=op://Vault/Item/field

# 1 段目 (確認): masked のまま動作確認
op run --env-file=.env -- <command>

# 2 段目 (本実行で値が必要なとき): --no-masking で生値を出す
op run --no-masking --env-file=.env -- <command>
```

**間違い**: `SOMEVAR=$(op read "op://...")` の `$()` 展開は op の masking
フィルタを経由せず生値が shell 変数に入る (= AI / log / history に露出)。
op:// 参照は env に書いて op run 経由で渡す。

## 2 段の確認 & 実行

1. **1 段目 (確認実行)**: `--no-masking` なしで実行。子プロセスは実値で動くが
   stdout/stderr は masked。AI が結果を読んでも値が context に乗らない。
   コマンドの形 / 認証経路 / 動作の正常性を確認
2. **2 段目 (本実行)**: 値そのものが log / 設定ファイル / 子プロセスを跨ぐ
   pipe 等に必要なときだけ `--no-masking` を付ける。出力先 (リダイレクト先 /
   ログファイル) を確認してから

通常は 1 段目で済む。2 段目に進む前に「本当に値が必要か」を自問。

## 機微キーワード (反応対象)

以下を扱う前に「`$()` 直展開していないか / op:// 参照経由か」を確認:

- 大文字略語 (単語境界マッチ): `TOKEN`, `PASSWORD`, `PASS`, `SECRET`, `KEY`,
  `CREDENTIAL`, `AUTH`, `PRIVATE`
  (`keyword` / `keymap` 等の一般語は除外、`PUBLIC_KEY` は対象外)
- ファイル / パス: `.env*`, `*.pem`, `*.key`, `id_*` (ssh 鍵),
  `*credentials*`, `*secret*`

## ユーザが直接 credential を貼ってきた場合

Claude は rotate / revoke を勝手に試みず、kawaz に以下を依頼:

1. **op への登録**: 当該 credential を 1Password vault に保存、今後は
   `op://...` 参照経由に切替
2. **当該セッション jsonl のクリーニング**: セッションログから該当値を削除
   (= context に残ったままだと後続セッションで再露出)
