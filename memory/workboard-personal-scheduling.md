---
name: workboard-personal-scheduling
description: 翌日以降の予定・締切・「1 週間後に確認」は workboard-personal/main のセッションに ccmsg で一言送ると kawaz の予定として管理・催促してくれる (kawaz 2026-10-22)
metadata:
  type: feedback
---

先の予定 (翌日以降) ができたら、自分で覚えようとせず **workboard-personal/main で動いているセッション** (`peers` で `workboard-personal@main` を探す) に ccmsg で送る。期日・タスク内容・条件・実行の仕方を書き、「期日になったら session_id <自分の id> を ccmsg で起こして」と添えると、当日に kawaz へ音声通知しつつこちらのセッションを呼んでくれる。セッションが居なければ kawaz に通知で可、と書いておく。

**Why**: kawaz のタスク・予定は全部そこに集約されていて、締切を見ながら kawaz を急き立てる役を担っている (kawaz 2026-10-22)。各セッションが個別に cron や memory で抱えると漏れる。

**How to apply**: 例 — kojienuniv 旧環境の削除を 1 週間後に、という依頼は item `2026-10-22-kojienuniv-old-env-teardown` として登録され、10/29 09:00 に通知 → こちらを起こす約束になった。登録後に相手から確認が返るので ack を返す。
