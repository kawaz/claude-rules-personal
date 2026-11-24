# ツール利用の tips

## Bash: 別ディレクトリでのコマンド実行は、行き先の `.envrc` で形を決める

cwd の中のコマンドには `cd` も `direnv exec` も付けない (direnv は起動時に適用済み)。別ディレクトリに出る時は、行き先を治める `.envrc` が今のセッションの物と同じかで分ける。

- **同じ `.envrc` の下** (同じ owner の隣のリポ等): `(cd /path/to/dir && command args...)`。`direnv exec` は付けない (env は既に同じで、付けると auto mode の classifier に止められることがある)
- **違う `.envrc` の下** (別の面・別のアカウントのリポ)、または行き先が自前の `.envrc` を持つ: `(cd /path/to/dir && direnv exec . command args...)`。**`cd` だけ / `direnv exec` だけの片方では事故る** (env が乗らず別アカウント鍵のまま push する / cwd が呼び出し元のままで別リポの状態を観測する)

`git -C dir` は cwd も env も揃わないので避ける。direnv 未 allow のディレクトリでは指示を仰ぐ (勝手に `direnv allow` しない)。見分け方と落ちる罠の詳細は reference の `direnv-exec-cwd` ([[knowledge-guide]] のパス) を読む。
