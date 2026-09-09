# 認証設計パターン

- [passkey-registration-local-first](passkey-registration-local-first.md) — 登録をローカル CLI に閉じた passkey 設計 (登録 URL の jwt、RP ID と検証手順、opaque token と refresh cookie、複数 instance への複製、任意のゲート)。
  発火語: passkey, WebAuthn, 登録フロー, RP ID, attestation, signCount, user handle, access token, refresh token, httpOnly cookie, token rotate, 再利用検知, デバイス一覧
- [peer-auth-url-identity](peer-auth-url-identity.md) — TLS を信頼の根にした peer 間相互認証と、固定 id / 可変 endpoint の分離。
  発火語: peer 認証, mesh, 相互認証, TLS, iss/aud, JWS, challenge, glare, 相乗り, 鍵空間の分離, instance id, 引っ越し, endpoint リスト
- [self-endpoint-identification](self-endpoint-identification.md) — 自分の endpoint URL を probe か config 直書きで確定し、起動時に検証する。
  発火語: self の確定, 自己識別, probe, Host ヘッダ, LB の裏, 自分の URL が分からない, 起動順序, listen してから検証
