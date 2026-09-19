---
name: commit-push-scope-by-repo-kind
description: リポの種別で commit / push の許可範囲が違う (rules・privacy は push 可、プロダクトは docs の commit まで)
metadata:
  type: feedback
---

kawaz の裁定 (2026-09-19): **rules 系 (claude-rules-*) と privacy 系リポは commit も push もしてよい。プロダクト系リポはドキュメント系の変更なら commit までしてよい。push は、そのリポに他の未 push commit (コード変更等) が無ければしてよく、あればそのリポの次の push に相乗りさせる** (push はリリースを伴いうるため)。

**Why:** プロダクトリポの push は CI だけでなく release workflow や tag 作成の引き金になりうる。docs / issue の変更を溜めて kawaz がリリース窓に同乗させる方が安全。rules / privacy はリリース概念が無く、配備は `just setup` で手元に反映するだけなので push しても副作用が無い。

**How to apply:** 他リポへの issue 起票・sanitize・docs 修正は local commit (パス指定) で止め、push 可否は QUESTIONS.md の確認待ちに載せず、`jj log -r 'main & ~remote_bookmarks()'` で自分の commit 以外の未 push が無いかを見て決める。「止まる理由がなければ作業系は GO」の一般則より、この種別ごとの線引きが優先する。
