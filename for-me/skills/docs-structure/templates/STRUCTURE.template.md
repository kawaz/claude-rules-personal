# リポジトリ物理構造

```
{project-name}/
  README.md / README-ja.md
  LICENSE
  {言語固有のビルド設定 e.g. Cargo.toml / package.json / pyproject.toml / moon.mod.json}
                            # ↑ ビルド設定が version を持つ言語 (Rust / Node / Python など) は
                            #   それを単一の正本にする (VERSION file を別に置かない)
  justfile                  # task runner (canonical, docs-structure 参照)
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
