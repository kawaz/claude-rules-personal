# AI がやりがちな雑な対応 anti-pattern 集 (自警)

根本原因への深掘りを放棄して **症状を symptom-fix で誤魔化す** 振る舞いの
カタログ。AI (= Claude) は triage コストが高く退屈な調査を打ち切りたい衝動が
強いため、これらに流れやすい。**書きたくなった瞬間が手抜きシグナル**。
kawaz スタンス: 手抜きで蓋をするくらいなら、調査未完了として可視化する方が誠実。

各 pattern の代替手段 (言語別 event-driven primitive 表) と正当な例外の
詳細は `sloppy-ai-patterns` skill を参照。

## sleep / polling で時間待ち

症状: `sleep 5; check_ready` / `while ! is_ready; do sleep 1; done` /
`setTimeout(check, 500)` 等を書きたくなった。

なぜ駄目か: 間隔値に根拠がない (早すぎ = false negative、遅すぎ = 浪費 /
外側 timeout)、真の完了瞬間を捉えられない、poll 間の状態往復を見逃す。

自警 (書きたくなった瞬間に3問):

1. その対象の状態変化を**直接通知してくれる primitive** はないか?
2. 言語 / 環境の event-driven 抽象 (inotify / fswatch / channel / await /
   `wait $pid` 等) を1度は探したか? **Claude Code 自身の作業では Monitor
   tool が既にある** — 使わず `sleep` ループを書いたら原則 anti-pattern
3. ポーリング interval の値に根拠を言えるか? (言えないなら勘)

正当な例外 (真の定期実行 / polling しか無い外部 API / test の deterministic
sleep / commit 前提の wip) の判定条件は skill 側。

## 他に発見した anti-pattern の扱い

新パターンに気づいたら追加検討。常時ロードには「症状 / なぜ駄目 / 自警」の
~10 行だけ足し、代替表・例外の詳細は skill 側に足す (= 常時ロード肥大防止)。
既に専用 rule がある anti-pattern は重複させず link で済ます:

- flaky 即断 / timeout 延長 / test 改変で green 偽装: [[test-failure-no-tampering]]
- 撤退 / 機能削除で逃げる: [[retreat-is-last-resort]]
- 言語 default に無自覚に流れる: [[default-convergence-guard]]

## 関連

- [[empirical-verification]] — 観測道具で実体確認 (= 推測で sleep 間隔を決めない)
- [[design-priority]] — sleep が必要に見えるのは設計不整合の徴候かも
- [[self-written-rule-blind-spots]] — 例外を skill 側に明示して両面化
