# `XDG_CONFIG_HOME` を上書きしたシェルで jj を実行すると ignore 対象が取り込まれる

実験用に `XDG_CONFIG_HOME` を一時ディレクトリへ向けたシェルのまま `jj status` 等を実行すると、jj が global の ignore 設定 (`$XDG_CONFIG_HOME/git/ignore`) と user config を読めず、普段 ignore されているファイル (`.claude/settings.local.json`、`*.local.code-workspace`、`.playwright-cli/` 等) を作業コピーに snapshot して track する。読み取りのつもりの `jj status` 1 回で起きる (jj は実行のたびに snapshot する)。出力に `Per-repo config not found. Generating an empty one` が出ていたら、この状態で走っている。

- `XDG_*` の上書きはシェルに export せず、起動するプロセスの呼び出しにだけ付ける (`env XDG_CONFIG_HOME=<dir> <cmd>`)。worker への委譲プロンプトにも「`XDG_*` を上書きしたシェルで jj / git を実行しない」と書く
- 取り込まれた時の戻し方: 通常の環境で `jj file untrack <path>...` (ディレクトリも渡せる)。ディスク上のファイルは残り、ignore が効いているので以後は取り込まれない。`jj op restore` は他の作業の snapshot まで巻き戻すので使わない
- path 指定の commit をしていれば、取り込まれたファイルは commit に入らない (作業コピーの change に載るだけ)。確認は `jj file list -r <rev> | grep <path>`
