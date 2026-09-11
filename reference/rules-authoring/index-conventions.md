# 索引の規約と機械検査

## 参照知識の索引エントリ

`reference/` `memory/` とその下のトピックディレクトリは、同ディレクトリの `_index.md` に本文 1 件 1 エントリを持つ。

```markdown
- [<slug>](<slug>.md) — 1 行要旨。
  発火語: そのトピックを読むべき場面で口に出る語, 別の語, エラーメッセージの一部
```

- 索引は常時 context に載るコストを払うので **1 エントリ 1〜2 行**に収める
- 発火語は「その知識が要る場面で実際に出てくる語」を並べる。ドキュメントの見出し語ではなく、困りごとの語・エラー文字列・コマンド名を入れる
- トピックディレクトリへのエントリはリンク先を `<topic>/_index.md` にする
- スクリプト・テンプレ・付属ファイルは載せない (reference-layout)

## 本文と索引の 1:1

本文 `<slug>.md` と `_index.md` のエントリは 1:1。**追加・削除・改名は両方を同じ変更で**行う。片方だけ足すと「本文はあるが誰も辿れない」「リンク先が無い」になる。

## private 層の写し

privacy リポの本文は private のまま、**索引だけを public 側の `reference/_index.md` の「private 層」節に写す**。privacy 側の `reference/_index.md` を更新したら、同じ変更で public 側の写しも更新する。リンクはフルパスで書く (本文が別リポにあるため)。

## 常時ロード rule のフェーズ別 index

`for-*/rules/_index.md` は rule をフェーズ (設計 / 実装 / コミット / CI / レビュー / 運用 / メタ) で引くための索引。rule を追加・削除・改名したら同じ変更でここも更新する。同じ rule が複数フェーズに出るのは正常なので、**多重所属なら全フェーズ分**を直す。

## `just lint-rules` が検査する項目

claude-rules-personal リポと各 overlay リポの `lint-rules` recipe が機械検査する (push の deps で自動実行される)。

| 検査 | 結果 |
|---|---|
| `for-all/rules/` の wikilink が `for-me/rules/` を指す (overlay 越境で dead link 化) | FATAL (central のみ) |
| rule が `[[自分の slug]]` で自身を参照 | FATAL |
| `.draft-` が rules 配下に存在 | FATAL |
| wikilink が rule ファイル名 / skill ディレクトリ名 / `.lint-external-slugs` のどれにも解決できない | FATAL |
| 参照知識のディレクトリに `_index.md` が無い / 本文が索引に無い / 索引のリンク先が実在しない | FATAL |
| 5KB 超の rule | WARN (省コンテキストの検討材料) |
| 常時ロード rules の合計が予算超過 | WARN (central のみ) |

overlay リポの rule から central (claude-rules-personal) の rule を wikilink で参照する場合は、overlay の `.lint-external-slugs` に slug を足す (central の rule を増減したら overlay 側も更新する)。

機械検査できないものは目視で確認する:

- 参照知識・skill への参照を名前で書いているか (「reference の `<topic>/<slug>`」「`<name>` skill」)
- 未来予告・過去 narrative が混ざっていないか (`no-historical-noise` rule)
