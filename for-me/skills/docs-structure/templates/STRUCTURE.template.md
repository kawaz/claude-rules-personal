# リポジトリ物理構造

```
{project-name}/
  README.md / README-ja.md
  LICENSE
  {言語固有のビルド設定 e.g. Cargo.toml / package.json / moon.mod.json}
  justfile                  # task runner (canonical, docs-structure 参照)
  VERSION                   # (or 言語固有の version file)
  src/                      # 実装本体
  tests/                    # テスト
  docs/                     # 設計・運用・履歴
    DESIGN-ja.md / DESIGN.md
    STRUCTURE.md
    ROADMAP.md
    decisions/
    journal/
    findings/
    runbooks/
    issue/
    knowledge/
    research/
    design/
```

## 各ディレクトリの役割

- `src/` — {言語ごとに応じた説明}
- `docs/` — `docs-structure` skill 参照
- `tests/` — {テスト構成の説明}
