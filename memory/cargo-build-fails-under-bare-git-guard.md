# 自前 `.git` の無い jj workspace では cargo build が上位の bare ガードに当たって失敗する

`~/.local/share/repos/github.com/kawaz/.git` は上位探索を止めるための bare 形式のガード。自前の `.git` を持たない旧方式 jj workspace (例: `workboard-personal/incubator`) で `cargo build` すると、cargo (1.99 で実測) が上方探索でそのガードに当たり `did not expect repo at .../kawaz/.git to be bare` で fingerprint 計算に失敗する。`cargo new --vcs none` でも変わらない。

回避: ソース (Cargo.toml / Cargo.lock / build.rs / src) を `mktemp -d` に複製してそこで build し、成果物だけ使う。colocate 方式 (main/ に自前 `.git` がある) のリポでは起きない。
