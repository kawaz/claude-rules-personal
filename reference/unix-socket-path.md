# Unix socket のパスの長さ

Unix socket を bind / connect するコードと、その試験を書く時の決まり。

## 何が上限か

上限は `bind(2)` / `connect(2)` に渡す `sockaddr_un` の `sun_path` の長さで、macOS 104 / Linux 108 バイト (NUL 込み)。ファイルシステム側には上限が無い。つまり **同じ場所を指す短い綴りを渡せば、深い場所にも socket を置ける**。

macOS の `$TMPDIR` だけで約 50 バイト、作業ごとに深い一時ディレクトリを割り当てる環境ではそれだけで 100 バイトを超える。置き場の深さは利用者と環境が決めるもので、コードからは選べない。短いことに頼らず、長くても通る書き方にする。

上限を踏んだ時のエラーの例:

- Rust std: `path must be shorter than SUN_LEN`
- Python: `OSError: AF_UNIX path too long`

## Rust: sockat を使う

crate `sockat` (crates.io、`sockat = "0.2"`) が、長いパスでも OS ごとに負担の少ない手を順に試して、渡したパスそのものに socket を作る / 繋ぐ。std の `bind` / `connect` を使う所では `sockat::bind` / `sockat::connect`、非同期の上では `sockat::connect_nonblocking` を使う。

```rust
let listener = sockat::bind(&path)?;   // std::os::unix::net::UnixListener (listen 済み)
let stream = sockat::connect(&path)?;  // std::os::unix::net::UnixStream (ブロックする)
```

- 100 バイト以内のパスは std をそのまま呼ぶので、短いパスの挙動は std と同じ
- 経路は Linux が `/proc/self/fd/<fd>/<名前>`、FreeBSD が `connectat(2)` / `bindat(2)`、macOS が cwd からの相対パス → 広げた sockaddr → 短い symlink。どれも呼び出し元の cwd を変えない。経路と制約の正本は sockat の `docs/MANUAL.md` と `docs/decisions/DR-0001`
- symlink は `$TMPDIR` (絶対パスの時) か `/tmp` の、他のユーザが差し替えられない場所 (sticky のディレクトリか、自分専用のディレクトリ) にだけ作る。ふつうの環境 (`/tmp` に書ける) ならどの深さのパスにも届く
- **connect は fork しない**。fork でしか届かない場面 (`/proc` も安全な一時ディレクトリも無い等) では、`sun_path` に収まらないパスを素で connect した時と同じく `ENAMETOOLONG` を返す。bind だけは最後の手として fork した子に bind させる (listen は呼んだ側が行う)

tokio へは std の型から変換する。`connect_nonblocking` は待たずに非ブロッキングの stream を返す (Unix domain の connect は呼んだ中で終わり、相手の backlog が満杯なら Linux ではすぐ `EAGAIN`、macOS では `ECONNREFUSED`) ので、runtime の worker の上でそのまま呼び、`from_std` に渡す。`spawn_blocking` は要らない。

```rust
let listener = sockat::bind(&path)?;
listener.set_nonblocking(true)?;
let listener = tokio::net::UnixListener::from_std(listener)?;

let stream = sockat::connect_nonblocking(&path)?;
let stream = tokio::net::UnixStream::from_std(stream)?;
```

- connect の口を差し替えられないライブラリ (例: reqwest の unix socket 対応) は、パスを渡す API を使わず、sockat で繋いだ stream の上でプロトコルを話す (HTTP なら hyper の client の handshake に stream を渡す)
- `sockat::connect_any` / `connect_any_nonblocking` は、`connect` でも届かない珍しい環境 (sandbox で一時ディレクトリが使えない等) で、fork の副作用を負ってでも繋ぎたい時だけに使う。fork の経路を通ったかを `(UnixStream, bool)` の `bool` で返す。通った時は受ける側から見える相手の pid が既に終わった子になる (uid / gid は繋いだプロセスのまま)。ふつうは使わず、`connect` の `ENAMETOOLONG` をそのままエラーにする
- 受ける側で相手を確かめるなら uid で確かめ、pid に頼らない (`connect_any` の類で繋いでくる相手の pid は意味を持たない)

## Rust 以外でライブラリが無い時

上から順に試す。

1. **パスが要らないならパスを使わない**。試験やプロセス内の通信は `socketpair(2)` で繋がった組を作るか、bind 済みの listener (の fd) を渡す。親子プロセス間なら fd を継承させる。上限に当たる余地そのものが無くなる
2. **短い symlink で綴りを短くする**。`/tmp` (無ければ `$TMPDIR`) に短いランダム名の symlink を作ってソケットのディレクトリを指させ、それを通したパスで bind / connect し、終わったら symlink を消す。socket ファイルは symlink の先、つまり本来のパスにできる。bind する側も connect する側も同じ手で届く。置き場は他のユーザが symlink を差し替えられない所 (`/tmp` のような sticky のディレクトリか、group / other が書けない自分専用のディレクトリ) に限る
3. **chdir して相対パスで渡す手は使わない**。cwd はプロセスに 1 つで、全スレッドの相対パスを巻き込む (並行に走る試験、ログ書き出し、他のライブラリ)。既に cwd の下にあるパスを相対で渡すのは cwd を変えないので構わないが、cwd が変わらない前提に立つことになる

2 の Python の例 (macOS で 252 バイトのパスに対して実測済み):

```python
link = tempfile.mktemp(prefix="app.", dir="/tmp")
os.symlink(os.path.dirname(path), link)
try:
    sock.bind(os.path.join(link, os.path.basename(path)))
finally:
    os.unlink(link)
```

symlink を作ってから消すまでにプロセスが死ぬと symlink が残る。名前の prefix で自分の残骸と分かるようにしておく。

## 試験で `$TMPDIR` が長くても通す

試験の一時ディレクトリは `$TMPDIR` の下に作るのが流儀で、その長さは試験からは選べない。

- **socket を開く側が長いパスを扱えるなら、試験は `$TMPDIR` の下のまま書く**。sockat を通しているなら一時ディレクトリをそのまま使い、短くする細工をしない
- **長いパスでも通ることを試験で固定する**。`$TMPDIR` が短い環境 (CI、他の開発機) でも上限を超えるよう、深さを足して作る

```rust
let dir = tempfile::tempdir()?;
let deep = dir.path().join("d".repeat(120));
std::fs::create_dir_all(&deep)?;
let path = deep.join("s.sock");
assert!(path.as_os_str().len() > 108);
```

- **開く側が長いパスを扱えない時** (std を直接使う、変えられない外部プログラムに socket のパスを渡す等) は、実体を `$TMPDIR` の下に作り、`/tmp` に置いた短いランダム名の symlink を試験が使うディレクトリとして渡す。片付けは symlink を先に消し、実体を後に消す。子プロセスに `XDG_STATE_HOME` 等で渡すパスは絶対パスが要るので、相対パスにする手は使えない
- 試験の並行実行と衝突しないよう、symlink の名前は固定にせずランダムにする

## getsockname は元のパスを返さないことがある

短い綴りで bind / connect した socket は、`getsockname(2)` / `getpeername(2)` (Rust の `local_addr()` / `peer_addr()`、Python の `getsockname()`) が **カーネルに渡した綴り** を返す。

| 渡した綴り | 返るもの |
|---|---|
| symlink 越し | もう無い symlink を通したパス (Python で実測: `/tmp/x.ypcs1bf7/s.sock`) |
| 相対パス | 相対パス |
| `/proc/self/fd/<fd>/<名前>` | そのパス (fd はもう閉じている) |
| `bindat` / `connectat`、fork した子でのファイル名だけ | ファイル名だけ |

socket ファイルを消す・ログに出す・他のプロセスに教える時は、**bind に使った元のパスを自分で持っておいてそれを使う**。socket ファイルの unlink には `sun_path` の上限が無いので、元のパスでそのまま消せる。
