# プロセス再起動 (resume) 後の teammate は agentId 宛なら transcript 込みで再開できる

Claude Code のプロセスを再起動して resume すると、Agent tool で spawn した teammate は `ListAgents` に載らず、名前宛の `SendMessage` は「reachable でない」で失敗する。spawn 時に返った **agentId** (`a<name>-<hex>`) 宛に送ると「not running だったので過去 N メッセージの transcript を持った in-process teammate として resume」され、以降は従来どおり会話できる (2026-11-02 実測、96 メッセージの文脈を引き継いで返答した)。

- 再開後の teammate は再起動前の癖 (同じ返信の重複送信など) も引き継ぐ
- 名前しか控えていないと復帰できないので、長く使う teammate は agentId を控える
- Workflow tool の `resumeFromRunId` が resume 後に効くかは未検証
