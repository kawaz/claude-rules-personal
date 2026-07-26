# リポジトリ物理構造

```
{project-name}/
  README.md / README-ja.md
  LICENSE
  {言語固有のビルド設定 e.g. Cargo.toml / package.json / pyproject.toml / moon.mod.json}
  justfile                  # task runner (canonical, docs-structure 参照)
  src/                      # 実装本体
  tests/                    # テスト(配置は言語慣習に従う)
  docs/                     # 設計・運用・履歴 ()`docs-structure` skill 参照)
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
