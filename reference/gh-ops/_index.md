# GitHub まわりの運用

- [gh-image-fetch](gh-image-fetch.md) — GH 上の画像 (user-attachments / camo / 相対パス) を公式 API で URL 化して取る。
  GitHub の画像を取得, user-attachments, body_html, camo, raw.githubusercontent, JWT URL の 5 分 TTL
- [gh-image-attach](gh-image-attach.md) — `gh --attach` で画像 / 動画を issue / PR に埋め込む (playwright は fallback)。
  GitHub に画像を貼る, 画像付きコメント, --attach, user-attachments へアップロード, スクショを issue に投稿, gh のバージョンが古い
- [instruction](instruction.md) — gh-image-attach の fallback で委譲先が読む browser 自動化手順書。
  画像投稿サブエージェントの手順書, playwright drop, textarea 自動検出, submit ボタンの安全ガード
- [homebrew-tap-deploy-key](homebrew-tap-deploy-key.md) — kawaz/homebrew-tap への自動 push 用 deploy key の生成・登録と、brews 登録忘れの徴候。
  HOMEBREW_TAP_DEPLOY_KEY, Permission to homebrew-tap denied, tap への自動 push, brew formula が消える, darwin-rebuild で uninstall
