# CLI設計の好み

CLI (サブコマンド構成 / `--help` の節構成 / bool フラグ / 引数位置 / completion) を設計・変更する時は reference の `cli-design-preferences` ([[knowledge-guide]] のパス) を読む。無自覚に言語やパーサのデフォルトへ流れないため、好みの表明が存在することだけ常に覚えておく。

**実装 (option parser / 振る舞い) ↔ `--help` テキスト ↔ completion 定義の 3 者は常に同時に追従させる。** 片方向だけ追従するアンチパターン (= 「help 更新したけど completion 古いまま」「completion 直したけど help 古い」) は **片面 rule の盲点** ([[self-written-rule-blind-spots]])、3 者の整合は意識的に確認する。
