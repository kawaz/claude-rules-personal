# op run で secret を env に注入する

env に `op://...` 参照を書いて op run に解決させる。

人が対話で使う secret の渡し方。launchd や定時実行で無人で読むツールの secret はキーチェーンに置く (reference の `keychain-secrets`)。

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

## 守りの限界

op run は値を子プロセスの環境変数に入れる。子が動いている間、その値は同じ uid のプロセスから見える (`ps -Eww -p <pid>` で子の環境変数が出る。観測、macOS 26.5.2、2026-11-27)。masking が隠すのは op run が中継する stdout / stderr だけ。

人が対話で使う一時的なコマンドなら許容できる。秘密を同じ uid の他のプロセスから守るべきプロセス (常駐の daemon、他のプロセスが結論を信頼する helper) に渡す経路には使わず、標準入力か、渡す相手だけが持つ fd で渡す (reference の `macos-process-protection` の M6)。
