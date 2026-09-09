# GitHub まわりの運用

- [gh-image-fetch](gh-image-fetch.md) — GH 上の画像 (user-attachments / camo / 相対パス) を公式 API 経路で URL 化して curl で取る。
  発火語: GitHub の画像を取得, user-attachments, body_html, camo, raw.githubusercontent, JWT URL の 5 分 TTL
- [gh-image-attach](gh-image-attach.md) — 画像付き Markdown を issue / PR / discussion / release へ投稿する (playwright でのアップロードをサブエージェントに委譲する)。
  発火語: GitHub に画像を貼る, 画像付きコメント, user-attachments へアップロード, スクショを issue に投稿, gh に画像添付手段が無い
- [instruction](instruction.md) — gh-image-attach の委譲先サブエージェントが読む browser 自動化手順書 (attach → drop → poll → fill → submit → 確認)。
  発火語: 画像投稿サブエージェントの手順書, playwright drop, textarea 自動検出, submit ボタンの安全ガード
- [homebrew-tap-deploy-key](homebrew-tap-deploy-key.md) — kawaz/homebrew-tap への自動 push 用 deploy key の生成・登録と、dotfiles の brews 登録忘れの徴候。
  発火語: HOMEBREW_TAP_DEPLOY_KEY, Permission to homebrew-tap denied, tap への自動 push, brew formula が消える, darwin-rebuild で uninstall
