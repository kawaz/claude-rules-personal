# macOS で秘密をメモリに持つプロセスの守り: 最低限満たす条件

macOS で、秘密 (鍵、token、認証の可否のような判定の結論) をメモリに持つプロセス (常駐 daemon、agent、CLI) が、同じ uid の他のプロセスから読まれない・書き換えられない・乗っ取られないために、最低限満たす条件の一覧。設計とレビューで 1 項目ずつ照合する。対象は macOS だけで、Linux は扱わない。

## このリストの読み方

- **満たせば安全というリストではなく、最低限満たすべきリスト**。MUST の項目は必要条件で、1 つでも欠けると、他を全部満たしていても守りにならない (守りの強さは一番低い穴で決まる)
- リストに無い経路が存在しないとは言っていない。調べていない経路は末尾の「未調査・未観測の経路」に置く
- MUST は、欠けた時に同じ uid のプロセスが秘密を読める・書ける・プロセスを乗っ取れる経路が開くことを、観測か一次資料で確かめたもの。SHOULD は、前提が崩れた時の被害を減らすか守りを重ねるもので、それ自体は境界にならない
- 根拠は項目ごとに 3 種類で書き分ける
  - **一次資料**: Apple の文書、man、SDK のヘッダ
  - **観測**: 実機で確かめたもの
  - **推定**: 観測や資料からの推論で、確かめていないもの
- 観測は、特記が無ければ macOS 26.5.2 (25F84)、SIP 有効、開発者モード無効 (`DevToolsSecurity -status`) の Mac でのもの。**プロセスの守りの観測基準日: 2026-11-15** (観測をやり直したら、この日付と版と各項目の根拠も一緒に更新する)。OS の版が変われば結果は変わりうる

## 想定する相手

- 同じ uid で動く、root でないプロセス。任意のコードを実行でき、自分のバイナリを ad-hoc 署名できる
- ad-hoc 署名のバイナリは、`com.apple.security.cs.debugger` を自分に付けて起動できる。カーネルはこれを「宣言済みのデバッガ」として扱う。`lldb` (Apple の `debugserver`) も宣言済みのデバッガに当たる (観測)
- ad-hoc 署名のバイナリは、Apple 専用の entitlement (`com.apple.system-task-ports.read` 等) を付けると起動時に kill される (観測。amfid のログは `The file is adhoc signed but contains restricted entitlements`)
- 扱わない相手: root、カーネル、SIP を無効にできる者、Mac に物理的に触れる者。プロセス自身の不具合 (入力の解釈の誤りからの乗っ取り) も扱わない

## 観測の要点

署名だけを変えた同じ試験プログラム (ヒープとスタックに目印を置いて待つ) に、同じ uid から 4 つの手段を当てた結果。MUST の M1 と M2 はこの表から出ている。

| 対象の署名 | entitlement を持たないプロセスからの task port と ptrace | 宣言済みのデバッガからの task port | 起動時の `DYLD_INSERT_LIBRARIES` | コアダンプ (`ulimit -c unlimited`) |
|---|---|---|---|---|
| hardened runtime なし、`get-task-allow` なし | カーネルが断る | カーネルを通り、利用者の認可のダイアログに進む | 読み込まれる | カーネルが断る |
| hardened runtime、`get-task-allow` なし (満たすべき形) | カーネルが断る | カーネルが断る (利用者の認可より前) | 読み込まれない | カーネルが断る |
| hardened runtime、`get-task-allow` あり | カーネルが断る | カーネルの拒否が出ず、認可待ちと見られる状態で止まる | dyld が変数を読み、library validation が Team ID の不一致で拒む | 書かれる (ヒープの目印を含む) |
| hardened runtime なし、`get-task-allow` あり | 取れる。メモリを読め、書き換えられ、ptrace も接続できる | 同上 (止まる) | 読み込まれる | 書かれる (ヒープの目印を含む) |

- 断るのはカーネル (AMFI) で、理由が unified log に出る。満たすべき形の対象では、呼び出し側が宣言済みのデバッガであることを認めた上で断る: `macOSTaskPolicy: (<呼び出し側>) may not get the task control port of (<対象>) (pid: <pid>): (<対象>) is hardened, (<対象>) doesn't have get-task-allow, (<呼び出し側>) is a declared debugger…`。この拒否は taskgated と利用者の認可 (`system.privilege.taskport`) より前に起きるので、ダイアログは出ず、利用者が認可しても通らない
- 断られる時は、task port の control / read / inspect のどれも断られる。name port だけは取れるが、name port ではメモリの読み書きも領域の一覧もできない
- 満たすべき形の結果は、Developer ID で署名した実物のバイナリでも同じだった。task port、ptrace、`lldb` は、利用者が起動したものと、root のプロセスがユーザ権限に永久降格してから exec したものの両方で確かめた。起動時の差し込みは利用者が起動したものだけ、コアダンプは試験プログラムだけで観測した
- コアダンプは `get-task-allow` の有無で決まり、hardened runtime の有無は関係しない。`get-task-allow` の無い対象は `ulimit -c` が 0 でも unlimited でもカーネルが断る (`AMFI: Denying core dump for pid <pid>`)

## MUST

### M1: hardened runtime で署名する

- 守る対象: 動作中のメモリ、プロセスの中で動くコード
- 条件: 配る実行ファイルとインストールする実行ファイルを `codesign --options runtime` で署名する
- 欠けた時に起きること
  - `DYLD_INSERT_LIBRARIES` を付けて起動すると、ライブラリが読み込まれる。ライブラリの constructor は `main` より前に、そのプロセスのコードの身元で動く (Keychain の ACL も通る。M3)
  - 宣言済みのデバッガの task port の要求がカーネルを通り、利用者の認可のダイアログに進む。守りが「利用者がダイアログを断ること」だけになる。認可した後に port が渡るかは観測していない (カーネルのログの文言からは渡る見込み。推定)
- 強制する仕組み: カーネル (AMFI の task port のポリシー)、dyld (hardened runtime で `get-task-allow` も無い対象では、`DYLD_` で始まる変数を読まないと見られる。ライブラリを開こうとした跡がログに出ない)
- 確かめ方: `codesign -d -v <ファイルか pid>` の `CodeDirectory` の行の `flags` に `runtime` (0x10000) がある
- 根拠: 観測 (差し込みと宣言済みのデバッガ)、一次資料 (Apple の Hardened Runtime のページ。保護は「SIP と組で」と書く)

### M2: 保護を緩める entitlement を付けない

- 守る対象: M1 と同じ。加えてコアダンプに写るメモリ
- 条件: 次の 4 つの key を署名に入れない。値が false でも key があれば不合格にする (一次資料は、false の entitlement を書かないことを求めている)
  - `com.apple.security.get-task-allow`
  - `com.apple.security.cs.allow-dyld-environment-variables`
  - `com.apple.security.cs.disable-library-validation`
  - `com.apple.security.cs.disable-executable-page-protection`
- 欠けた時に起きること
  - `get-task-allow` (観測): hardened runtime があっても、dyld が `DYLD_` の変数を読むようになり (残る守りは library validation だけ)、宣言済みのデバッガの要求をカーネルが断らなくなり、上限 (`ulimit -c`) が許せばコアダンプが書かれる。hardened runtime も無ければ、entitlement を持たないプロセスがそのままメモリを読み書きできる
  - `allow-dyld-environment-variables` (一次資料): dyld が `DYLD_` の変数を読むようになる
  - `disable-library-validation` (一次資料): Apple か同じ Team ID の署名でないライブラリも読み込むようになる
  - `disable-executable-page-protection` (一次資料): コード署名の保護が全部外れ、実行コードを検出されずに書き換えられる
- Xcode は開発用のビルドに `get-task-allow` を自動で足す (`CODE_SIGN_INJECT_BASE_ENTITLEMENTS`。一次資料)。配るビルドで外れていることを確かめる
- 強制する仕組み: カーネル (AMFI)、dyld
- 確かめ方: `codesign -d --entitlements - --xml <ファイル>` の出力に上の key が無い
- 根拠: `get-task-allow` は観測。他の 3 つは一次資料 (個別の観測はしていない)

### M3: 保護の無い署名済みのビルドを作らない・残さない

- 守る対象: コードの身元を条件に渡される秘密 (Keychain の ACL)
- 条件: 配布用の証明書 (Developer ID) と同じ identifier で、M1 と M2 を満たさないファイルを、署名済みのまま 1 つも残さない・配らない。ビルドは署名の直後に M1 と M2 を検査し、落ちたら署名済みのファイルを消す。デバッグ用のビルドは ad-hoc 署名か別の identifier にする
- 欠けた時に起きること
  - Keychain の ACL の requirement は、信頼アプリの designated requirement (identifier、Apple が発行した証明書、Team ID) になる。requirement の言語には署名のフラグの条件が無く、hardened runtime を条件に書けない (一次資料: Code Signing Requirement Language。公開 API で信頼アプリを作る関数は `SecTrustedApplicationCreateFromPath` だけ)
  - ACL は読む側のプロセスのコードの身元だけで判定し、読み込まれたライブラリを問わない。hardened runtime でないバイナリにライブラリを差し込むと、そのバイナリだけを許す ACL の項目を、ライブラリの constructor が読めた。hardened runtime のバイナリでは読み込まれず、読めなかった (観測。ad-hoc 署名のバイナリと試験用の keychain)
  - したがって、保護の無い署名済みのビルドが 1 つでもあれば、相手はそのファイルを持ち込み (守りたい Mac に元から在る必要は無い)、ライブラリを差し込んで、ACL を通って秘密を読める見込み
- 出てしまったファイルは、消すだけでは足りない (写しの署名は有効なまま)
- 強制する仕組み: 無い。ビルドの手順で守る
- 確かめ方: 下の `check_hardened` を署名の直後に呼ぶ。条件を満たすファイルは残り、hardened runtime の無いものと `get-task-allow` 付きのものは消えて失敗することを確かめてある

  ```bash
  # 署名の直後に呼ぶ。条件を満たさなければ、署名済みのファイルを消して失敗する
  check_hardened() {
    local file=$1 info flags entitlements key
    if ! info=$(codesign -d -v "$file" 2>&1); then
      rm -f "$file"
      echo "$info" >&2
      return 1
    fi
    flags=$(sed -nE 's/^CodeDirectory .* flags=0x([0-9a-fA-F]+).*/\1/p' <<<"$info")
    if [[ -z $flags ]] || (( (16#$flags & 0x10000) == 0 )); then
      rm -f "$file"
      echo "$file: hardened runtime のフラグが無い (--options runtime で署名する)" >&2
      return 1
    fi
    entitlements=$(codesign -d --entitlements - --xml "$file" 2>/dev/null)
    for key in \
      com.apple.security.get-task-allow \
      com.apple.security.cs.allow-dyld-environment-variables \
      com.apple.security.cs.disable-library-validation \
      com.apple.security.cs.disable-executable-page-protection; do
      if grep -qF "<key>$key</key>" <<<"$entitlements"; then
        rm -f "$file"
        echo "$file: 保護を緩める entitlement $key がある" >&2
        return 1
      fi
    done
  }
  ```

- 根拠: 観測 (差し込んだライブラリが ACL を通ること。ACL の requirement が cdhash になる ad-hoc 署名で確かめた)、一次資料 (requirement に hardened runtime を書けないこと)、推定 (Developer ID の designated requirement の ACL でも同じになること)

### M4: 保存する秘密は、自分のバイナリだけを許す ACL の Keychain の項目に置く

- 守る対象: 保存してある秘密 (メモリに読む前の置き場)
- 条件
  - 項目は、ACL の信頼アプリを自分のバイナリだけにして作る (`SecTrustedApplicationCreateFromPath` (自分の実行パス) → `SecAccessCreate` → 復号の ACL に `SecACLSetContents`)
  - バイナリは Developer ID で署名する。ad-hoc 署名では requirement が cdhash になり、ビルドのたびに ACL から外れる
  - 読み出しは非対話にする (ダイアログを出さない)。項目を同名で作り直されていると、自分の読み出しでもダイアログになる。利用者にこの種のダイアログを見せない
- 欠けた時に起きること: `security` コマンドで作った項目や「全アプリ可」の ACL の項目は、同じ uid の任意のプロセスが確認なしで読める。モード 600 のファイルも同じ uid から読める。メモリを守っても、置き場から読まれる
- ACL で止まらないもの
  - ACL の外の相手が読もうとすると、パスワード付きのダイアログが出る。利用者が「常に許可」を押すと、その相手が ACL に加わる。利用者の操作に依る点が残る
  - 項目の削除と、同名での作り直しは、ACL の外の相手にもできる。読んだ値が自分の書いた値であることは ACL では保証されない (要るなら値に署名を付ける)
- 読み手の身元を固定できない場合 (スクリプト、`security` コマンドで読むツール) は、この条件を満たせない。権限を絞った token だけを置く (reference の `keychain-secrets`)
- 強制する仕組み: securityd (Keychain の ACL)
- 確かめ方: 同じ作り方で試験用の項目を作り、ACL の外のバイナリ (`security find-generic-password -s <service> -a <account> -w`) から読んで、失敗するかダイアログになることを見る。ダイアログでは「拒否」を押す
- 根拠: 観測 (2026-11-06 と 2026-11-15。Developer ID 署名のバイナリの項目と、ad-hoc 署名の試験用の項目)

### M5: 誰でも使える入口から、秘密を出さない・勝手に使わせない

- 守る対象: 秘密そのものと、秘密を使う操作 (署名、復号、送信)
- 条件
  - 入口 (サブコマンド、引数、環境変数、標準入力、設定ファイル、socket や XPC で受ける要求) から、秘密の値を出力しない
  - 入口から、秘密の参照先 (どの項目を読むか、どこへ送るか) を切り替えさせない
  - 秘密を使う操作を入口が代行するなら、OS が出す本人確認 (Touch ID 等) の後だけにするか、要求する相手のコードの身元を検査する
- 欠けた時に起きること: Keychain の ACL はコードの身元で判定し、誰が起動したかを問わない (観測)。署名済みのバイナリは同じ uid の誰でも起動でき、開いている socket には同じ uid の誰でも繋げる。入口が秘密を出す・使うなら、相手はメモリも ACL も破らずに目的を果たす
- 強制する仕組み: 無い。設計で守る
- 確かめ方: 入口の一覧 (help、引数のパーサ、読む環境変数、受ける要求) を作り、秘密に触る箇所から逆に辿って、どの入口から届くかを見る。内部用の入口の数をテストで固定する
- 根拠: 観測 (ACL の判定がコードの身元だけで決まること)。残りはそこからの帰結

### M6: 秘密を、プロセスの外から見える場所に置かない

- 守る対象: 受け渡しの途中の秘密
- 条件: 秘密を argv、環境変数 (自分のものも、起動する子のものも)、ログ、同じ uid が読めるファイルに置かない。子に渡すなら標準入力か、渡す相手だけが持つ fd にする
- 欠けた時に起きること: entitlement を持たない同じ uid のプロセスが、hardened runtime の対象の argv と起動時の環境変数を `sysctl` (`KERN_PROCARGS2`) で読めた。task port は要らない。argv は `ps` で別の uid からも見える (`/bin/ps` は setuid root)
- 強制する仕組み: 無い (OS が見せる)
- 確かめ方: `ps -Eww -p <pid>` で、自分の引数と環境変数に秘密が出ないことを見る。起動する子についても同じ
- 根拠: 観測 (hardened runtime の ad-hoc 署名の試験プログラム。別の uid の対象には同じ呼び出しが `EINVAL` で断られた)

### M7: 他のプロセスの結論を信頼する側は、起動した後の pid の署名を検査する

他のプロセスがこのプロセスの結論や出力を信頼する構成にだけ当たる (例: root で動く PAM モジュールが、ユーザ権限に降格した helper を起動して、認証の可否を受け取る)。

- 守る対象: 判定の結論
- 条件: 信頼する側は、起動した後の pid について次を検査し、1 つでも満たさなければ結果を受け取らない
  - requirement: `identifier "<identifier>" and anchor apple generic and certificate leaf[subject.OU] = "<Team ID>"`。OID や OU の条件は必ず `anchor apple generic` の後ろに置く (自己署名の証明書でも OID や OU は名乗れる。`anchor apple generic` は満たせない)
  - hardened runtime のフラグ (`kSecCodeSignatureRuntime`) がある
  - 実行中のコードの状態が有効で (`kSecCodeStatusValid`)、デバッガに接続されていない (`kSecCodeStatusDebugged` が立たない)
  - M2 の 4 つの entitlement が無い
  - 署名の情報が読めない時、検証が失敗した時も不合格にする (実行中にディスク上のファイルが差し替えられると、返る署名の情報は走っているコードのものではなくなる)
- あわせて守ること
  - 実行ファイルと親ディレクトリ (`/` まで) を、信頼する側の権限でしか書けない場所に置く。起動する前のファイルの検査は、exec までの間に差し替えられる (推定。差し替えの観測はしていない)
  - 結論は、信頼する側が自分で作ったパイプで受け、明示の成功だけを成功にする。同じ uid のプロセスは対象にシグナルを送れる (一次資料: POSIX `kill`) ので、無応答や終了を成功にしない
- 欠けた時に起きること: M1〜M3 を満たさないビルド (別の配布経路のもの、手作業で署名したもの) の結論を受け取る。そのプロセスは、観測の要点の表のとおり、同じ uid からライブラリを差し込める・メモリを書き換えられるので、結論を偽れる
- 強制する仕組み: 信頼する側のコード (Security.framework の `SecCodeCopyGuestWithAttributes` (pid) → `SecCodeCheckValidity` (requirement) → `SecCodeCopySigningInformation` (`kSecCSDynamicInformation`))。OS が自動で行うものではない
- 確かめ方: hardened runtime の無い ad-hoc 署名のバイナリと、4 つの entitlement を 1 つずつ付けたバイナリを起動して、検査が不合格にすることをテストで固定する。手では `codesign -v -R='<requirement>' <pid>` と `codesign -d -v --entitlements - <pid>`
- 根拠: 観測 (保護の無い対象が差し込まれ・書き換えられること、走っているプロセスに requirement と署名の情報を評価できること、自己署名が `anchor apple generic` を満たさないこと)、推定 (起動する前の検査が差し替えに負けること)

### M8: SIP が有効な Mac で動かす

- 守る対象: M1 と M2 の全部
- 条件: SIP が有効であること。無効なら、守りが効いていない前提で扱う
- 欠けた時に起きること: 一次資料は hardened runtime の保護を「SIP と組で」と書き、`get-task-allow` の無いプロセスの task port が取れないことを「SIP に守られている」と書く。SIP を無効にした Mac での振る舞いは観測していない
- 強制する仕組み: SIP (Recovery の `csrutil` でだけ切り替えられる)
- 確かめ方: `csrutil status`
- 根拠: 一次資料 (観測なし)

## 検証の決まり (MUST)

守りが効いていることを確かめる時は、次の全部を守る。1 つでも欠けた検証の結果は、守りの根拠にしない。

- **Apple の診断ツールの結果を証拠にしない**。`vmmap`、`heap`、`stringdups` は Apple 専用の entitlement (`com.apple.system-task-ports.read` と `.read.safe`) を持ち、普通のプロセスより多くを読める。entitlement を持たないプロセスが port を取れない対象でも、中身を出す。「読めなかった」は守りの証拠にならず、「読めた」は普通のプロセスが読める証拠にならない。道具の entitlement は `codesign -d --entitlements - /usr/bin/heap` で見られる
- **陽性対照を置く**。同じ検査の手段が、守りの無い対象 (hardened runtime なし、`get-task-allow` あり) で成功することを、同じ回に確かめる。断られた結果だけでは、守りが効いたのか、検査が壊れているのかを区別できない
- **拒否の理由をカーネルのログで確かめる**。戻り値だけでは、断ったのがカーネルか、利用者の認可の不足かを区別できない (`lldb` は `Not allowed to attach to process` で断られることも、認可待ちで止まることもあり、表示だけでは理由が分からない)
  - task port と ptrace: `log show --last 5m --style compact --predicate 'eventMessage CONTAINS "macOSTaskPolicy"'`
  - 差し込みとコアダンプ: `log show --last 5m --style compact --predicate 'sender == "AppleMobileFileIntegrity" OR process == "amfid"'` (`Library Validation failed`、`Denying core dump`)
  - 認可の段に進んだか: `log show --last 5m --predicate 'process == "taskgated"'`
- **呼び出し側を 2 種類にする**。entitlement を持たない検査プログラムと、`com.apple.security.cs.debugger` を自分で付けた ad-hoc 署名の検査プログラム (加えて `lldb -p <pid>`)。片方だけでは、hardened runtime の寄与が見えない
- **対象は、自分で作った試験プログラムと自分のバイナリだけにする**。他のプロセスには当てない。root は使わない
- **署名の組み合わせで寄与を切り分ける**。試験プログラムを hardened runtime の有無と `get-task-allow` の有無の 4 通りに署名し、実物のバイナリを加える。plist は、該当の key (`com.apple.security.get-task-allow`、`com.apple.security.cs.debugger`) を true にした dict だけのもの

  ```bash
  codesign -s - --force <対象>                                                         # hardened runtime なし
  codesign -s - --force --options runtime <対象>                                       # 満たすべき形
  codesign -s - --force --options runtime --entitlements get-task-allow.plist <対象>
  codesign -s - --force --entitlements get-task-allow.plist <対象>                     # 陽性対照
  codesign -s - --force --entitlements debugger.plist <検査プログラム>                 # 宣言済みのデバッガ
  ```

- **当てる手段**: `task_for_pid` / `task_read_for_pid` / `task_inspect_for_pid` / `task_name_for_pid`、取れた port での `mach_vm_read_overwrite` と `mach_vm_write`、`ptrace(PT_ATTACHEXC)`、`DYLD_INSERT_LIBRARIES` (constructor が印を出すだけのライブラリ)、コアダンプ (`ulimit -c unlimited` で起動して `kill -QUIT`、`/cores` を見る)
- **認可のダイアログに備える**。宣言済みのデバッガを hardened runtime でない対象に当てると、利用者の画面に認可のダイアログが出て残る。検査には打ち切り (`timeout`) を付け、カーネルが断る見込みの組から先に当て、ダイアログには応じない。認可は共有され 10 時間続く設定になっている (`security authorizationdb read system.privilege.taskport` の `shared` と `timeout`)
- **記録に環境を書く**。macOS の版、SIP の状態、開発者モードの状態、日付。当てていない組は「未観測」と書き、観測した組からの推論と分ける

## SHOULD

どれも境界にはならない。MUST の前提が崩れた時の被害を減らすか、守りを重ねる。

### S1: コアダンプの上限を 0 にする

- 条件: 起動の直後、秘密を読む前に `setrlimit(RLIMIT_CORE)` で soft と hard を 0 にし、設定できなければ何も読まずに終わる。別の権限から起動する側は、exec の前の子で設定する (hard を 0 にすると、特権の無いプロセスは上げ直せない)
- 境界にならない理由: `get-task-allow` の無いプロセスのコアダンプは、上限に依らずカーネルが断る (試験プログラムでの観測)。M2 を満たしていれば、この経路は既に閉じている。上限は、その観測に依らない 2 つ目の守り
- 根拠: 観測 (試験プログラム。実物のバイナリのコアダンプは観測していない)、一次資料 (`setrlimit(2)`)

### S2: 秘密を、使い終わったら消える型で包む

- 条件: 秘密を素の文字列やバイト列で持たず、drop の時に 0 で上書きする型 (Rust なら `secrecy`、`zeroize`) で包む。ログやデバッグ出力に中身が出ない型を選ぶ
- 境界にならない理由: 効くのは、使い終わった後に残る写しだけ。動作中のメモリを読める相手には、使っている間の値が読める。包んでも消せない写しも残る (Keychain の API の内部、JSON のパーサの作業用のバッファ、ライブラリが導いた鍵、再確保で解放された領域)
- 根拠: 推定 (依存ライブラリのソースを読んだ範囲。メモリを読んで確かめてはいない)

### S3: メモリに持つ秘密を、読まれても致命的にならないものに絞る

- 条件
  - 読まれると承認の偽造や権限の昇格に直結する鍵 (署名鍵、全権の token) を、常駐するプロセスに持たせない。使う操作の間だけ読む短命のプロセスに分ける
  - 常駐するプロセスが持つのは、漏れても損失が狭い秘密 (権限を絞った token、要求ごとの使い捨ての鍵) にする (reference の `keychain-secrets`)
  - 取り出せない鍵 (Keychain の非抽出の鍵、Secure Enclave) は、前提が崩れた時に鍵の値の持ち出しを防ぐ選択肢。プロセスの制御まで取られた時に勝手に使われることは、使うたびに生体を求める鍵でなければ防げない
- 境界にならない理由: 被害の上限を下げるだけで、読まれること自体は防がない
- 根拠: 推定 (取り出せない鍵と Secure Enclave は確かめていない)

### S4: 別の権限から起動する側は、呼び出し元の状態を子に持ち込まない

- 条件: 実行ファイルは絶対パスで指定し、環境は空にしてから必要なものだけを渡し、標準入出力以外の fd を閉じる
- 境界にならない理由: hardened runtime の対象は `DYLD_` の変数を読まないので、差し込みは M1 が止めている。これは、呼び出し元の環境や fd が入口 (M5) になるのを減らす
- 根拠: 推定

## やっても守りに数えないもの

- **プロセスの中の自己検査** (起動時に自分の署名やフラグを確かめてから秘密を読む)。守りたい場面は、hardened runtime でないビルドにライブラリを差し込まれた時だが、差し込まれた constructor は `main` より前に動き、検査を経ずに秘密を読む (観測)
- **`ptrace(PT_DENY_ATTACH)`**。寄与を観測していない (未調査の節)
- **Apple の診断ツールで中身が出ないことの確認** (検証の決まり)

## 未調査・未観測の経路

MUST を全部満たしていても、次は確かめていない。

- Apple の道具 (task port を取れる entitlement を持つもの) を、同じ uid のプロセスが実行するだけで、満たすべき形の対象のメモリの中身を取り出せるか。分かっているのは次まで
  - `vmmap` は領域の一覧を出し、引数なしの `heap` は malloc のノード数と型の集計を出す (観測)。中身ではないが、配置と型の情報は同じ uid から取れる
  - `heap --addresses=all` と `stringdups` は、`get-task-allow` の無い対象には `can only show contents of readonly memory of restricted processes` と出して中身を出さない (観測)。これがカーネルの強制か、道具の判断かは確かめていない
- 宣言済みのデバッガに利用者が認可を与えた後の、hardened runtime でない対象の扱い。認可が同じログインセッションの他のプロセスに共有されるか
- 開発者モードを有効にした Mac (`DevToolsSecurity -enable`)。変わるのは利用者の認可の段で、満たすべき形の対象への要求は認可より前にカーネルが断るので、影響しない見込み (推定)
- カーネルのログに出る `declared read-only debugger` に当たる entitlement の名前と、ad-hoc 署名で自分に付けられるか
- Developer ID で署名した実物のバイナリのコアダンプ (観測は試験プログラムだけ)。`get-task-allow` のある対象で `ulimit -c` が 0 の時
- Developer ID の designated requirement の ACL の項目を、同じ identifier と Team ID で hardened runtime なしに署名したビルドに差し込んだライブラリから読めるか (M3 の推定の部分)。System Keychain の項目での同じ観測
- SIP を無効にした Mac での、表の各手段の結果
- `ptrace(PT_DENY_ATTACH)` の寄与
- hardened runtime の他の例外の entitlement (`allow-jit`、`allow-unsigned-executable-memory`) が、同じ uid からの経路を開くか
- socket、XPC、Mach service で要求を受けるプロセスが、相手のコードの身元を検査する方法とその抜け道
- スワップ、メモリの圧縮、休止のイメージに写った秘密
- 画面やキー入力を介する経路 (Accessibility、Apple Events、画面の読み取り)
- macOS の他の版
