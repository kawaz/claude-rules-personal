---
name: mythos-for-defensive-security-projects
description: 防御的なセキュリティ対策が要るプロジェクトでは、fable を使う場面で mythos を使う
metadata:
  type: feedback
---

防御的なセキュリティ対策が要るプロジェクトでは、fable を使う場面 (統括のセッション、引き継ぎ先の起動など) で mythos を使う。mythos はその要件での利用として使っているもので、それに値するプロジェクトで fable の代わりに選ぶ、という使い分け (kawaz 2026-11-17)。

fable と mythos の違いは、dual-use の領域への追加の制限 (censor) の有無だけ。能力も単価も使い方も基本同じで、制限の無い mythos の方が、その分だけ少し強い。worker 選定や effort の考え方は fable と同じに扱う。

2026-11-17 時点の該当: procline、pam-passkey、cache-warden など。

**How to apply:** これらのプロジェクトでセッションを起動する・引き継ぐ時は、model に mythos を選ぶ (「mythos で続けてよいか」と聞かない)。
