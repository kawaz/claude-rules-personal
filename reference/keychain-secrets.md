# 無人で読むツールの secret を macOS のキーチェーンに置く

自作ツールが API トークン等を無人で読む (launchd、定時実行、CLI ツールの既定の読み口) なら、macOS のキーチェーンの generic password に置き、`/usr/bin/security` で読む。人が対話で使う secret は 1Password の `op run` で渡す (reference の `op-run-secret-injection`)。op は launchd 配下では Touch ID の確認が画面に届かず、無人では通らない。

実例は 2 つ: ある観測スクリプトの credential の取り出し口 (登録・取り出しを 1 本のスクリプトに閉じる) と、artifacts-share (reference の `artifacts/share`) の `load_settings` / `load_credentials`。

## 項目の名前

- **service**: 値を読むツールの名前。ツールごとに 1 つ (例 `artifacts-share`)
- **account**: そのツールの中の何の値か (例 `r2-token`、`settings`)
- 1 つのツールが複数の連携先の値を持つなら、account を `<連携先>/<名前>` にする (例 `github/token`)
- label は付けない

service と account をこの形に固定すれば、項目の対応表をツールの外に持たなくてよい。

## 登録する

人が手で入れる時は、値を最後の `-w` に付けずに置く。man security の記述 ("Put at end of command to be prompted (recommended)") どおり、対話で尋ねられる。`-U` は既にあれば上書き。

```bash
security add-generic-password -U -s <service> -a <account> -w
```

ツールやスクリプトが値を流し込む時は、`security -i` (対話モード) の stdin にコマンド行を流し、値は `-X` (16 進) で渡す。`-w <値>` を argv に書くと `ps` に出る。16 進にすると引用符やバックスラッシュのエスケープも要らない。`printf` は bash の builtin なので値は `ps` に出ない。

```bash
hex=$(printf '%s' "$value" | od -An -v -tx1 | tr -d ' \n')
printf 'add-generic-password -U -s %s -a %s -X %s\n' "$service" "$account" "$hex" |
  /usr/bin/security -i >/dev/null 2>&1
```

`security -i` の出力は捨てる (エラー時に入力の行をそのまま出すことがある)。

入ったかの確認は `-w` を付けない `find-generic-password` で行う。属性だけが出て値は出ない。

```bash
security find-generic-password -s <service> -a <account> >/dev/null && echo 入った
```

## 読む

- `/usr/bin/security find-generic-password -s <service> -a <account> -w` を子プロセスとして起動し、stdout だけを受ける。シェルのコマンド文字列を組まず、引数を配列で渡す
- 終了コード 44 は項目なし (errSecItemNotFound)。「未登録。登録は <手順>」のエラーにする。それ以外の非 0 はキーチェーンのロック等なので、別のエラーにする (「無い」と言わない)
- `-w` の出力は値の末尾に改行が 1 つ付く。それを 1 つ落とし、残りが空でないことを確かめる
- エラー文・ログには service / account と終了コードだけを出し、値を入れない

```bash
rc=0
value=$(/usr/bin/security find-generic-password -s "$service" -a "$account" -w 2>/dev/null) || rc=$?
case $rc in
  0) ;;
  44) die "未登録: $service / $account (登録は security add-generic-password -U -s $service -a $account -w)" ;;
  *) die "キーチェーンを引けない ($service / $account、終了コード $rc。ロック等を確認)" ;;
esac
[[ -n $value ]] || die "値が空: $service / $account"
```

bash の `$(…)` は末尾の改行をすべて落とす。改行を 1 つだけ落としたい時は、他の言語で stdout をバイト列で受けて末尾の `\n` を 1 つ外す。

## 秘密でない設定も同じ service に置ける

アカウント ID・バケット名・公開ドメインのように秘密ではないが public のコードに書きたくない値は、同じ service の別 account (例 `settings`) に JSON 1 つで置ける。読んだ側で各キーの形を検査してから使う (artifacts-share の `load_settings` は `jq` で型と正規表現を確かめ、合わなければどのキーが不正かを出して止まる)。

## 守りの限界

`security` で作った項目は、同じユーザーの任意のプロセスが確認なしで `find-generic-password -w` で読める (実測)。launchd agent からも読める。キーチェーンは読み手を絞る守りにならないので、守りは置く token の権限を絞って作る (読み取り専用、対象のバケットや Project 1 つだけ等)。漏れても損失がその権限の範囲に留まる token だけを置き、人の全権 token や書き込み権限が広い token は置かない。
