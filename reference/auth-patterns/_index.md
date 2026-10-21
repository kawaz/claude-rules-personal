# 認証設計パターン

ここの各文書は kawaz 製の他プロダクトへ持ち帰る (バックポートする) 前提の標準である。各リポの DESIGN / DR は独自に書き起こさず、ここを正本として参照し、差分だけを書く。

- [passkey-registration-local-first](passkey-registration-local-first.md) — 登録をローカル CLI に閉じた passkey 設計 (登録 URL、RP ID、token と cookie、複製)。
  発火語: passkey, WebAuthn, 登録フロー, RP ID, attestation, signCount, user handle, access token, refresh token, httpOnly cookie, token rotate, 再利用検知, デバイス一覧
- [multi-tab-token-refresh](multi-tab-token-refresh.md) — 複数タブ / プロセスで access token を共有しつつ安全に refresh する手順。
  発火語: 複数タブ, refresh token, Web Locks, BroadcastChannel, rotate, 同時 refresh, タブ間共有
- [peer-auth-url-identity](peer-auth-url-identity.md) — TLS を信頼の根にした peer 間相互認証と、固定 id / 可変 endpoint の分離。
  発火語: peer 認証, mesh, 相互認証, TLS, iss/aud, JWS, challenge, glare, 相乗り, 鍵空間の分離, instance id, 引っ越し, endpoint リスト
- [self-endpoint-identification](self-endpoint-identification.md) — 自分の endpoint URL を probe か config 直書きで確定し、起動時に検証する。
  発火語: self の確定, 自己識別, probe, Host ヘッダ, LB の裏, 自分の URL が分からない, 起動順序, listen してから検証
