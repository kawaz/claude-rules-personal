# 仕様書の精読

POSIX / RFC / API doc / 各種規範を判断根拠にするときは **流し読み禁止**。
1 文を切り出す前に、前提条件 / 例外節 / 規範語の強度を確認する。

## 確認項目

- **規範語の区別**: `MUST` / `SHALL` / `SHOULD` / `MAY` / `RECOMMENDED` の強度差
- **前提条件**: 「ただし～の場合」「Implementations may～」等の but/except 節
- **適用範囲**: その項が適用される object / context (= 例: file vs directory, blocking vs non-blocking)
- **バージョン / errata**: 仕様改訂や errata で覆されていないか

## How to apply

- 重要な判断の根拠にするときは **複数箇所引用 + 実機検証** で裏取り
- 引用するなら段落単位で、1 文だけの切り取りを避ける
- 仕様の主張と実装挙動が食い違ったら、両方記録して判断は保留
- 「仕様にこう書いてある」を根拠に強い断定をする前に、対象の正確な定義を再確認

## Why

仕様書の 1 文は単独で完結しないことが多い。前後の but 節 / 用語定義 / 適用範囲を
読まずに引用すると、本来の意図と逆の結論を導いてしまう。

## 関連

- [[empirical-verification]] — 仕様の主張を実機で裏取り
- [[research-documentation]] — 仕様引用と検証結果の記録
