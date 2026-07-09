# MoonBit 実践 Tips

## シンボルリネーム

```bash
moon ide rename old_name new_name --loc src/file.mbt:行:列 --apply
```

- **デフォルトは edits のプレビュー出力のみ。書き換えには `--apply` が必須**
- `--loc` は `path[:line[:col]]` (行・列は 1-based)。`--loc` なしはモジュール/ワークスペース
  全域のセマンティック検索 (シンボル形式: `foo` / `@pkg.foo` / `Type::member`)。
  ローカル変数・shadow 名・曖昧なシンボルは行・列まで指定する
- 全参照（呼び出し元、examples 含む）を自動置換
- テスト名やコメント内の文字列リテラルは対象外（手動対応）
- **誤爆実績あり**: 関数パラメータの rename で無関係な別関数のパラメータまで
  書き換わった事例 (kuu.mbt、2026-07-10)。`--apply` 後は毎回 `jj diff` / `git diff`
  で意図した範囲だけが変わったことを確認する
- `--no-check` で事後の moon check をスキップ可能

## ビルド対象の制御

`moon.mod.json` の `"source"` でソースルートを指定:

```json
{ "source": "src" }
```

- `src/` 配下のみがビルド対象、examples 等は除外される
- インポートパスが変わる: `kawaz/kuu/src/core` → `kawaz/kuu/core`
- 各 moon.pkg のインポートパスも合わせて更新が必要
