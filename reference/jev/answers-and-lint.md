# Jev の答えの読み方 (しきい値と confidence) とテンプレの静的 lint

## しきい値はコードに置き、答えの型ごとに置く場所を変える

| 型 | しきい値を置く値 | 始めの値 |
|---|---|---|
| Noul | `noul` そのもの (yes の確率) | 0.7 以上を yes、0.3 以下を no、その間は別の経路 (人に回す等) |
| Choice | 行動する選択肢の確率 `probabilities[choice]` | 行動ごとに決める (取り消せない操作ほど高く) |
| Score (1 つの level が決め手) | その level の確率 | 同上 |
| Score (答えが定まっているか) | `confidence` を先に見てから `score` で振り分け | 低い confidence は人へ |

- 0.3〜0.7 の中間帯をどちらかに丸めない。中間帯に独自の行き先を作る
- 誤った yes が高くつく (人を呼び出す、返金する) なら yes のしきい値を上げ、yes の見逃しが高くつく (安全上の問題を見落とす) なら下げる
- 同じシステムでも行動ごとにしきい値を変える (読み取りだけの操作は低く、破壊的な操作は高く)
- 少数のテスト事例にしきい値を合わせ込まない。同じ入力でも Noul / Score は ±0.02〜0.05 揺れるので、しきい値ちょうどの境界には余裕を持たせる
- 複数の Noul を組み合わせる時も、どれかが中間帯ならその入力全体を別経路に回すように書ける

```python
YES, NO = 0.7, 0.3
wants_human = answers["q00"]["noul"]
repeat = answers["q01"]["noul"]
if NO < wants_human < YES or NO < repeat < YES:
    send_to_review(msg)
elif wants_human >= YES:
    route_to_agent(msg, priority="high" if repeat >= YES else "normal")
else:
    route_to_bot(msg)
```

## confidence は確率と別物で、確率から計算されている

`confidence` は `probabilities` の分布の尖り具合を 0〜1 にまとめた値。「選んだ答えが正しい確率」ではない。Choice と Score にだけあり、Noul には無い (`noul` 自体が確率)。

- Choice (選択肢 n 個、最大の確率 p_max): `(p_max − 1/n) / (1 − 1/n)`。最大の確率だけで決まるので、選択肢の数が決まった Choice では `confidence` と最大の確率は同じ情報。同じ confidence 0.5 でも、2 択なら最大 0.75、10 択なら 0.55
- Score (level 0〜n−1、最頻の level m): `max(0, 1 − Σ p_i·|i − m| / MAD_unif)`、`MAD_unif = (1/n) Σ |i − (n−1)/2|`。隣の level に割れても下がりにくく、両端に割れると 0 になる。隣り合う 2 level に半々で割れた答え (score が level の間に来る) は confidence を見ても分からないので、決め手の level の確率を見る
- Noul で confidence 風の値が要るなら `|2p − 1|` (Choice の式を 2 択に当てたものと同じ尺度)
- 返ってくる `confidence` はこの式と丸めの範囲 (±0.005) で一致する。自分の用途に合う別の統計量 (最大の確率、1 位と 2 位の比) を `probabilities` から計算して使ってよい
- 低い confidence は「行動してよいか」の信号で、質問の作りの信号でもある。同じ質問で低い confidence が並ぶなら、論点が複数混ざっているか、state だけでは決まらない暗黙の前提を要している。質問を分解する

## テンプレの静的 lint

テンプレ (request から state を除いた `{"model", "questions"}` の JSON) は、Jev を呼ぶ前に字面で検査できる。lab-jev リポの `bin/jev-lint <template.json>...` が次の項目を検査する (警告があれば終了コード 1)。

| 検査 | 理由 |
|---|---|
| `model` が版 ID (`jev-X.Y.Z`) か | alias は指す先が動いて答えが変わる |
| `instructions` がある | 問いは instructions にしか書けない (質問 ID は送られない) |
| instructions にリスク選好・価値判断の語 (`better than` / `prefer` / 「安全」等) が無い | 価値判断は事実の問いに分解してコードで合成する |
| instructions / criteria の地の文が CJK でない | 日本語の質問文は Noul を大きく動かす。入力の語を例として引くのは許す |
| Noul の `criteria` が `{true, false}` の入れ子か、`true` / `false` が質問直下に無いか | 直下に置くと 200 のまま黙って捨てられる |
| Choice の選択肢が 2〜255 個 | 256 個以上は 400 |
| Choice に範囲外の受け皿 (none / other / unknown 等の選択肢、または「どれかに当てはまるか」の Noul) がある | Choice は範囲外の入力にも高い確率で何かを選ぶ |
| Score の level が 2〜10 段 | 11 段以上は 400 |
| Box の model が 1.14 以降で、写っているかの Noul が同じテンプレにある | Box は対象が無くても位置を返す |
| 未知の `type` が無い | 型は `choice` / `score` / `noul` / `box` の 4 つ |

字面の検査なので限界がある。価値判断の語は、規約のテーマを説明する文 (「CLI 設計の好み」の prefer) にも反応する。受け皿の Noul の検出も語のパターンによる。語では拾えない「価値判断が混ざっている」「判断軸が複数ある」「境界事例が criteria に無い」は、質問自体を state にして Jev に Noul で問う意味的 lint か、期待値付きの入力集合 (golden) での一致率と confidence 分布で見る。
