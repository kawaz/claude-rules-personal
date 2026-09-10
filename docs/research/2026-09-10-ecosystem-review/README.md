# kawaz エコシステム外部レビュー (2026-09-09〜10)

別セッションで kawaz のルール・プロダクト群を横断レビューした成果物を、宛先ごとに分割して置いたもの。

## 温度感 (必読)

初版の指摘から個別プロジェクトのレビューを進めるたびに認識が改まり、指摘が覆されたケースが多い (fix-list 内の「(削除)」「(訂正)」「(取り下げ)」がその痕跡)。**全面的に鵜呑みにせず、各リポで実物と照合してから採否を決める**。「裁定待ち」の項目は kawaz の判断が要る。

## 構成

- [common.md](common.md) — 全プロジェクト共通: バックポート候補パターン P-1〜P-48 (良い形を reference / rule に標準化する候補) と未評価リスト
- リポ別の指摘 (各リポの担当セッションが読む):
  - [claude-rules-personal.md](claude-rules-personal.md)
  - [ccmsg.md](ccmsg.md)
  - [claude-ccmsg.md](claude-ccmsg.md)
  - [hyoui.md](hyoui.md)
  - [cache-warden.md](cache-warden.md)
  - [bump-semver.md](bump-semver.md)
  - [stable-which.md](stable-which.md)
  - [die.md](die.md)
  - [llm-gateway.md](llm-gateway.md)
  - [canddy-app-proxy.md](canddy-app-proxy.md)
  - [claude-session-analysis.md](claude-session-analysis.md)
  - [kuu.md](kuu.md)
- [misc/](misc/) — 指摘以外: 設計パターンの変遷 (evolution)、9 か月の年表 (timeline)、初日の全体評価 (review-initial、後の会話で訂正済みの内容を含む)

読む順: 自リポのファイル → common → misc。
