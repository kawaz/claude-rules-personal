# ローカルパスのサニタイズ

公開ファイル（コミット対象）にローカルのフルパスが含まれている場合、プロジェクトルートからの相対パスに変換するか確認する。

## 例

- `/Users/kawaz/.dotfiles/local/share/repos/github.com/kawaz/project/src/foo.js` → `src/foo.js`
- `file:///Users/kawaz/.../project/benchmarks/test.js` → `benchmarks/test.js`

## 適用タイミング

- コミット前に公開ファイル内のパスを確認
- cpuprofile、ログファイル、生成ファイルなど特に注意
