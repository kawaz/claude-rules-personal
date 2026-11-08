# Jev の request と state の渡し方

`POST https://api.typesafe.ai/v1/systemone` に `{"model", "state", "questions"}` (画像を使うなら `assets` も) を送る。質問の組み方は reference の `jev/question-design`。

## model は版 ID で固定する

- alias (`jev-latest` / `jev-preview`) は新しい版が出ると指す先が動き、コードを変えなくても答えが変わる。閾値を合わせたテンプレは版 ID (`jev-1.14.0` 等) で送る
- 応答の `model` 欄に答えた版 ID が入る。結果と一緒に記録する
- alias の今の指す先は `GET /v1/models` では分からない (一覧は alias だけで、`release_date` も版の指す先を示さない)。alias で 1 回送って応答の `model` を見る
- 版を上げる時は、golden (期待値付きの入力集合) を旧版と新版で並べて取り、閾値を見直してから切り替える
- 廃止は予告制 (1.13 は 60 日前、1.14 は 30 日前に通知すると公式が述べている)

## state はオブジェクトにして、質問から部分を名指す

- state は文字列・JSON オブジェクト・配列のどれでもよい。部分が複数あるなら、各部分に名前の付いたオブジェクトにする (`{"message": ..., "posted_at": ..., "channel": ...}`)
- 質問からはバッククォート付きのキー (`` `customer` ``、`` `ticket.messages[0].text` ``) でどの部分を判断するかを指す。複数の話者や文書が並ぶ state では、名指さないと他の部分に引きずられる (「客は返金不要、担当者が返金を提案」で「返金を求めているか」: `customer` を名指すと 0.02、「the message」だと 0.15〜0.20)
- 効くのは名指すことで、オブジェクトであること自体ではない (文字列の state でも「the customer」と書けば同じ値)。オブジェクトはキー名の分だけ token が少し増える
- 判断に要らない内容を state に入れない。無関係な内容が増えるほど精度が落ちる。先にコードで絞り、要るフィールドだけ渡す
- 日付・数値の比較に要る値は、コードで計算済みの値か名前の付いた区分 (「期限切れ」「今週」) にして入れる

### シェルから送る

state を JSON で組んでファイルに置き、`jq` で request に合成する。文字列として読み込む (`--rawfile`) と JSON の中身ごと 1 つの文字列になり、オブジェクトとして届かない。

```bash
# state.json は {"message": "...", "posted_at": "..."} のような JSON 値
jq -n --slurpfile t template.json --slurpfile s state.json '$t[0] + {state: $s[0]}' > req.json
curl -sS https://api.typesafe.ai/v1/systemone \
  -H "Authorization: Bearer $TYPESAFE_API_KEY" -H 'Content-Type: application/json' -d @req.json
```

本文 (業務のメッセージ等) は argv に載せずファイル経由で渡す。API key の渡し方は reference の `op-run-secret-injection`。

## CJK (日本語) の入力

- 質問文 (`instructions`) と `criteria` は英語で書き、state は原文 (日本語) のまま渡す。この組み合わせだと、同じ内容の英語の state とほぼ同じ答えになる (Noul の差は平均 0.02、Choice は一致、Score は平均 0.1 程度)
- 質問文と `criteria` を日本語にすると、Noul が大きく動く (「人間の担当者を求めているか」が、求めていない文で 0.01〜0.11 から 0.13〜0.81 に上がった)。1.14 の多言語の改善でもこれは直っていない
- 英文の instructions の中に入力側の語を例として引く (「treat 休みます / 早退します as ...」) のは、日本語の言い回しの境界を伝える手段として使ってよい
- Score は言語で 0.1〜0.5 程度動くことがあるので、日本語の入力で閾値を決めるなら日本語の入力で測る

## 制限・料金・エラー

| 項目 | 値 |
|---|---|
| 料金 | 入力 $0.042 / MTok、出力は無料 |
| context | request あたり 64k token、state + 質問 1 件あたり 32k token |
| 質問数 | 上限なし (context の範囲で) |
| Choice の選択肢 | 1〜255 |
| Score の level | 1〜10 |
| body | 32 MiB まで。`Content-Encoding: gzip` / `zstd` を受ける |
| 入れ子 | state / instructions / criteria は 64 段まで |
| レート制限 | 組織ごと。値は developer console にだけあり、応答の header には出ない |
| 応答時間 | 中央値 170 ms 前後 (日本から) |

- 状態コード: 400 (不正な request。存在しない型、画像の header 抜け)、401、413 (大きすぎる)、415、422 (検証エラー、欄ごとの詳細付き)、429 (レート制限。`retry-after` があれば従う)、529 (過負荷)。再試行は 429 と 529 を対象にする
- token 超過はまず質問の集合を半分に割って送り直す方が、見積もりを正確にするより安い

## 実験機能 (Danger Zone)

本番向けの水準ではないと公式が明記している機能。header を付けた request でだけ使える。

- **画像**: header `TypeSafe-Danger-Zone-Images: true`。最上位の `assets` に `{"<名前>": {"type": "image", "format": "png", "data_base64": "..."}}` を置き、state / instructions / criteria から名前で参照する。PNG / JPEG、1 枚 16 MiB まで、1 辺 280〜1568 px (280 px 未満は 400)。入力 token として同じ単価で課金される。jev-1.13.0 でも使える
- **Box**: 画像の中の位置を返す。jev-1.14.0 以降 (1.13 に送ると 400)。対象が写っていなくても必ず位置を返すので、「`photo` に X が写っているか」の Noul を同じ request に足し、Noul が yes の時だけ box を使う
- **long context**: header `TypeSafe-Danger-Zone-Long-Context: true` で両方の context 上限が 262k token になる。単価は同じだが遅く、精度も落ちる。長い文書は分割して問う方を先に考える
