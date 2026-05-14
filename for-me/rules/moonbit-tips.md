# MoonBit 実践 Tips

## シンボルリネーム

```bash
moon ide rename old_name new_name --loc src/file.mbt:行:列
```

- シンボル定義の位置を `--loc` で指定（行・列は 1-based）
- 全参照（呼び出し元、examples 含む）を自動置換
- テスト名やコメント内の文字列リテラルは対象外（手動対応）
- パッチ出力ではなく**直接ファイルを書き換える**
- `--no-check` で事後の moon check をスキップ可能

## ビルド対象の制御

`moon.mod.json` の `"source"` でソースルートを指定:

```json
{ "source": "src" }
```

- `src/` 配下のみがビルド対象、examples 等は除外される
- インポートパスが変わる: `kawaz/kuu/src/core` → `kawaz/kuu/core`
- 各 moon.pkg のインポートパスも合わせて更新が必要
