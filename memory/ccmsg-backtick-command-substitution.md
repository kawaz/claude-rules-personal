---
name: ccmsg-backtick-command-substitution
description: ccmsg のメッセージ本文をダブルクォートで渡すとバッククォート部分がコマンド置換されて消える
metadata:
  type: reference
---

`ccmsg post` / `ccmsg reply` の本文を **ダブルクォートで囲んで渡すと、本文中のバッククォートがシェルのコマンド置換として評価される**。中身はコマンドとして実行され (大抵は失敗し)、その位置は**空文字になって送信される**。送信自体は成功するので気づきにくい。

```bash
# 壊れる: `docs/QUESTIONS.local.md` の部分が消える
ccmsg reply r318m1 "… `docs/QUESTIONS.local.md` は gitignore 対象 …"
```

`??` のような glob もエラーを出す (`no matches found`)。

## 対処

- **本文でバッククォートを使わない** (コード表記を諦めて素のテキストにする)
- 使うならシングルクォートで全体を囲む。ただし本文中に `'` を書けなくなる
- 送信後に `ccmsg read <room><mid>` で自分の送信内容を読み返すと、欠落に気づける

## Why

エージェント間メッセージはファイルパスや識別子を含みがちで、つい `` ` `` で囲みたくなる。送信は ok で返るため、相手が読むまで欠落が露見しない。
