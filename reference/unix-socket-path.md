# Unix socket のパスの長さ

`sun_path` の上限を超えるパスで Unix socket を bind / connect する時は [sockat](https://github.com/kawaz/sockat) を使う。作業している言語の実装が無ければ、sockat-{lang} を作ってとユーザに依頼する。
