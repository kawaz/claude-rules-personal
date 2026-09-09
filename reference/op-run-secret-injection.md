# op run で secret を env に注入する

env に `op://...` 参照を書いて op run に解決させる。

```bash
# .env に op:// 参照
SOMEVAR=op://Vault/Item/field

# 1 段目 (確認): masked のまま動作確認
op run --env-file=.env -- <command>

# 2 段目 (本実行で値が必要なとき): --no-masking で生値を出す
op run --no-masking --env-file=.env -- <command>
```

**間違い**: `SOMEVAR=$(op read "op://...")` の `$()` 展開は op の masking フィルタを経由せず、生値が shell 変数に入る (= AI / log / history に露出)。`op://` 参照は env に書いて op run 経由で渡す。

## 2 段の確認 & 実行

1. **1 段目 (確認実行)**: `--no-masking` なしで実行。子プロセスは実値で動くが stdout/stderr は masked。AI が結果を読んでも値が context に乗らない。コマンドの形 / 認証経路 / 動作の正常性を確認する
2. **2 段目 (本実行)**: 値そのものが log / 設定ファイル / 子プロセスを跨ぐ pipe 等に必要なときだけ `--no-masking` を付ける。出力先 (リダイレクト先 / ログファイル) を確認してから

通常は 1 段目で済む。2 段目に進む前に「本当に値が必要か」を自問する。
