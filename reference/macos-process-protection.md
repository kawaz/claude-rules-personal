# macOS で秘密をメモリに持つプロセスの守り: 最低限満たす条件

macOS で、秘密 (鍵、token、認証の可否のような判定の結論) をメモリに持つプロセス (常駐 daemon、agent、CLI) が、同じ uid で動く他のコードに秘密を読まれない・書き換えられない・乗っ取られないために、最低限満たす条件の一覧。設計とレビューで 1 項目ずつ照合する。対象は macOS だけで、Linux は扱わない。

カーネルが断るのは、Apple 専用の entitlement を持たないプロセスからの読み書きまで。Apple の診断ツールは対象のメモリを読める。その中身が相手に渡らないことは、道具の作りに依る (「観測の要点」の「Apple の診断ツール」)。

## このリストの読み方

- **満たせば安全というリストではなく、最低限満たすべきリスト**。MUST の項目は必要条件で、1 つでも欠けると、他を全部満たしていても守りにならない (守りの強さは一番低い穴で決まる)
- **項目を、意味を理解せずに満たしても守りにならない**。どの項目も、守る経路と守らない経路がある。各項目の「守らないもの」を読んで、自分の設計で開いたままの経路を確かめる
- リストに無い経路が存在しないとは言っていない。調べていない経路は末尾の「未調査・未観測の経路」に置く
- MUST は、欠けた時に同じ uid のプロセスが秘密を読める・書ける・プロセスを乗っ取れる経路が開くことを、観測か一次資料で確かめたもの。SHOULD は、前提が崩れた時の被害を減らすか守りを重ねるもので、それ自体は境界にならない
- 根拠は項目ごとに 3 種類で書き分ける
  - **一次資料**: Apple の文書、man、SDK のヘッダ
  - **観測**: 実機で確かめたもの
  - **推定**: 観測や資料からの推論で、確かめていないもの
- 観測は、特記が無ければ macOS 26.5.2 (25F84)、SIP 有効、開発者モード無効 (`DevToolsSecurity -status`) の Mac でのもの。**プロセスの守りの観測基準日: 2026-11-15** (観測をやり直したら、この日付と版と各項目の根拠も一緒に更新する)。項目の中に別の日付を書いた観測は、その日に同じ版・同じ設定の Mac で行ったもの。OS の版が変われば結果は変わりうる
- 本文が名前で指す一次資料の所在
  - Hardened Runtime: https://developer.apple.com/documentation/security/hardened-runtime
  - Debugging tool entitlement (`com.apple.security.cs.debugger`): https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.debugger
  - Allow DYLD environment variables entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.allow-dyld-environment-variables
  - Disable Library Validation Entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.disable-library-validation
  - Disable Executable Memory Protection Entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.disable-executable-page-protection
  - Resolving common notarization issues (`get-task-allow` の節): https://developer.apple.com/documentation/security/resolving-common-notarization-issues
  - Disabling and Enabling System Integrity Protection: https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection
  - Code Signing Requirement Language: https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html
  - TN3137 On Mac keychain APIs and implementations: https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains
  - keychain access group と provisioning profile についての Apple DTS の回答: https://developer.apple.com/forums/thread/685723 、https://developer.apple.com/forums/thread/724013
  - POSIX `kill()`: https://pubs.opengroup.org/onlinepubs/9799919799/functions/kill.html
  - `taskgated(8)`、`DevToolsSecurity(8)`、`setrlimit(2)` は Mac の man
  - SDK のヘッダ: `Security/CSCommon.h`、`Security/SecCode.h`、`Security/SecTrustedApplication.h`、`Security/SecAccess.h`、`sys/un.h`

## 想定する相手

- 同じ uid で動く、root でないプロセス。任意のコードを実行でき、自分のバイナリを ad-hoc 署名できる
- ad-hoc 署名のバイナリは、`com.apple.security.cs.debugger` を自分に付けて起動できる。カーネルはこれを「宣言済みのデバッガ」として扱う。`lldb` (Apple の `debugserver`) も宣言済みのデバッガに当たる (観測)
- ad-hoc 署名のバイナリは、Apple 専用の entitlement を自分に付けられない。`com.apple.system-task-ports.read` と `com.apple.system-task-ports.read.safe` は、どちらも付けたものが起動時に kill された (観測。`.read.safe` は 2026-11-27。終了コードは 137、amfid のログは `The file is adhoc signed but contains restricted entitlements`)
- `gcore` が持つ `com.apple.security.cs.debugger.read.root` は、ad-hoc 署名で自分に付けても起動を止められなかった (観測、2026-11-27)。この entitlement で何ができるかは未観測 (末尾の「未調査・未観測の経路」)
- 相手は Apple の診断ツールを実行できる。道具の出力は相手に渡る
- 相手は、利用者の画面に認可のダイアログを出させられる (宣言済みのデバッガで、hardened runtime でない対象か `get-task-allow` のある対象の task port を求める)
- 扱わない相手: root、カーネル、SIP を無効にできる者、Mac に物理的に触れる者。プロセス自身の不具合 (入力の解釈の誤りからの乗っ取り) も扱わない

## 観測の要点

### 署名の組み合わせと 4 つの手段

署名だけを変えた同じ試験プログラム (ヒープとスタックに目印を置いて待つ) に、同じ uid から 4 つの手段を当てた結果。M1 と M2 はこの表から出ている。

| 対象の署名 | entitlement を持たないプロセスからの task port と ptrace | 宣言済みのデバッガからの task port | 起動時の `DYLD_INSERT_LIBRARIES` | コアダンプ (`ulimit -c unlimited`) |
|---|---|---|---|---|
| hardened runtime なし、`get-task-allow` なし | カーネルが断る | カーネルを通り、利用者の認可の段に進む。認可があれば取れて、読み書きできる | 読み込まれる | カーネルが断る |
| hardened runtime、`get-task-allow` なし (満たすべき形) | カーネルが断る | カーネルが断る (認可があっても) | 読み込まれない | カーネルが断る |
| hardened runtime、`get-task-allow` あり | カーネルが断る | カーネルが断らない。認可があれば取れて、読み書きできる (認可が無い時は止まる) | dyld が変数を読み、library validation が Team ID の不一致で拒む | 書かれる (ヒープの目印を含む) |
| hardened runtime なし、`get-task-allow` あり | 取れる。メモリを読め、書き換えられ、ptrace も接続できる | 同上 | 読み込まれる | 書かれる (ヒープの目印を含む) |

- 断るのはカーネル (AMFI) で、理由が unified log に出る。満たすべき形の対象では、呼び出し側が宣言済みのデバッガであることを認めた上で断る: `macOSTaskPolicy: (<呼び出し側>) may not get the task control port of (<対象>) (pid: <pid>): (<対象>) is hardened, (<対象>) doesn't have get-task-allow, (<呼び出し側>) is a declared debugger…`。この拒否は taskgated と利用者の認可 (`system.privilege.taskport`) より前に起きるので、ダイアログは出ない。認可がある状態でも断られた
- 断られる時は、task port の control / read / inspect のどれも断られる。name port だけは取れるが、name port ではメモリの読み書きも領域の一覧もできない
- 満たすべき形の結果は、Developer ID で署名した実物のバイナリでも同じだった。認可が無い時の task port、ptrace、`lldb` は、利用者が起動したものと、root のプロセスがユーザ権限に永久降格してから exec したものの両方で確かめた。認可がある時と、起動時の差し込みは、利用者が起動したものだけ。コアダンプは試験プログラムだけで観測した
- コアダンプは `get-task-allow` の有無で決まり、hardened runtime の有無は関係しない。`get-task-allow` の無い対象は `ulimit -c` が 0 でも unlimited でもカーネルが断る (`AMFI: Denying core dump for pid <pid>`)

### 利用者の認可は強い境界ではない

宣言済みのデバッガの要求がカーネルを通った先にあるのは、利用者の認可 (`system.privilege.taskport`) だけ。この認可は次の性質を持つ (観測)。

- ダイアログの文言は「Developer Tools Access はデバッグを続行するために別のプロセスを制御する必要があります」で、要求したプログラムも対象のプロセスも示さない。Touch ID で応じられる
- 別の確認の操作の最中にこのダイアログが出ると、利用者はその一部だと思って応じる。同じ日に 2 回起きた (応じた本人の申告)
- 1 つの要求に認可が下りると、その後は別のプロセスもダイアログ無しで同じ認可を使えた。設定は共有 (`shared`) で 10 時間 (`timeout: 36000`)。応じるには `_developer` グループの利用者としての認証が要る (`authenticate-user`、`group: _developer`)。設定は `security authorizationdb read system.privilege.taskport` で読める (2026-11-27 に読んだ値)。要求した検査プログラムを止めた後も、ダイアログは画面に残る
- `security authorize -d system.privilege.taskport` では取り消せなかった。ログアウトで消える見込み (推定)
- `lldb` (`debugserver`) は別の right (`system.privilege.taskport.debug`) を求め、改めてダイアログが出た

したがって、認可の段まで進む対象 (上の表の 1 行目、3 行目、4 行目) の守りは、「利用者がダイアログを断ること」ですらなく、「利用者がその瞬間に何のダイアログかを見分けること」に依る。

### Apple の診断ツール

- `com.apple.system-task-ports.read.safe` を持つ Apple の道具 (`vmmap`、`heap`、`leaks`、`stringdups`、`malloc_history`、`sample`、`atos`、`footprint`) は、満たすべき形の対象でもカーネルに断られず、書き込み可能なメモリを実際に読む。`leaks --debug=contents` は、ヒープのブロックを指す値を対象の `__bss` とスタックの中から見つけて、その場所を出した
- 道具は、`get-task-allow` の無い対象のメモリの中身を、出力にもファイルにも出さない (`Process <pid> is not debuggable. Due to security restrictions, ... can only show contents of readonly memory of restricted processes.`)。これは道具の判断で、カーネルの強制ではない
- 中身が出うる使い方 (中身の説明、memory graph の保存と読み直し、corpse、`leaks --debug` の各モード) を全部当てても、満たすべき形の対象では目印は 1 つも出なかった。`get-task-allow` のある対象では同じ使い方で出た
- 道具が出すもの: 領域の一覧、malloc のノード数と型の集計、確保済みのブロックを指す値がある場所
- `com.apple.system-task-ports.read` だけを持つ道具 (`lsmp`、`symbols`) と `gcore` は、満たすべき形の対象の read port をカーネルに断られた
- 道具へのライブラリの差し込み (`DYLD_INSERT_LIBRARIES`) は効かず、対象の port を持っている最中の道具への task port の要求もカーネルが断った

守りは 2 つに依る。相手がその entitlement を自分のバイナリに付けられないこと (OS の強制) と、Apple の道具が中身を出力しないこと (道具の作りで、境界ではない)。

## 経路と、それを受け持つ項目

相手が使える経路ごとに、どの項目が塞ぐかの対応。項目を 1 つ外した時にどの経路が開くかは、この表の「受け持つ項目」から辿る。

| 経路 | 受け持つ項目 | 根拠 |
|---|---|---|
| entitlement を持たないプロセスが、task port か ptrace でメモリを読む・書く | M1 か、M2 のうち `get-task-allow` を付けないこと、のどちらか一方があれば断られる。両方を外すと開く | 観測 |
| 宣言済みのデバッガが task port を取る | M1 と M2 の両方。片方でも欠けると、カーネルが断らなくなり、残るのは利用者の認可だけ (強い境界ではない) | 観測 |
| 起動時にライブラリを差し込む | M1 と M2 の両方。M1 だけだと (`get-task-allow` があると) library validation だけが残る | 観測 |
| 保護の無い、同じ身元の別のビルド (access group では、同じ group を名乗れる別のビルド) を持ち込み、ライブラリを差し込んで、コードの身元で渡される秘密を読む | M3 | 観測、一次資料、推定 |
| コアダンプに写ったメモリを読む | M2 (`get-task-allow` を付けない)。S1 が重ねる | 観測 (試験プログラム) |
| 保存してある秘密を、置き場から読む | M4 | ファイル型の Keychain は観測、data protection keychain は一次資料 |
| 入口から秘密を出させる・使わせる | M5 | 観測と、そこからの帰結 |
| argv、環境変数、ログ、ファイルから読む | M6 | 観測 |
| 保護の無いビルドや別のコードの結論を、信頼する側に受け取らせる | M7 | 観測、推定 |
| SIP を無効にした Mac で上の手段を使う | M8 | 一次資料 |

どの項目も受け持たない経路 (満たしていても開いたまま):

| 経路 | 状態 | 根拠 |
|---|---|---|
| Apple の診断ツールが、対象の書き込み可能なメモリを読む | カーネルは断らない。相手に渡るのは道具の出力 (領域の一覧、型の集計、ブロックを指す値の場所) で、中身は出ない。中身が出ないことは道具の作りに依る。S2 と S3 が、崩れた時の被害を減らす | 観測 |
| 利用者に認可のダイアログで応じさせる | M1 と M2 を満たした対象には届かない。満たさない対象では、利用者が見分けることに依る | 観測 |
| ファイル型の Keychain のダイアログで、利用者に「常に許可」を押させる | 利用者の操作に依る。data protection keychain (M4 の (a)) にはこのダイアログが無い (一次資料からの推定) | 観測 |
| プロセスにシグナルを送って止める・殺す | 同じ uid のプロセスは送れる。可用性は守れない。結論の偽造にならないようにすることだけ M7 が受け持つ | 一次資料 (POSIX `kill()`) |
| ファイル型の Keychain の項目を消す、同名で作り直す | ACL の外の相手にもできる。data protection keychain (M4 の (a)) では group の外の相手にはできない見込み (推定、未観測) | 観測 |
| 末尾の「未調査・未観測の経路」に挙げたもの | 確かめていない | — |

## MUST

### M1: hardened runtime で署名する

- 条件: 配る実行ファイルとインストールする実行ファイルを `codesign --options runtime` で署名する
- 守るもの
  - 起動時のライブラリの差し込み (`DYLD_INSERT_LIBRARIES`)。M2 も満たしている時
  - 宣言済みのデバッガからの task port の取得。M2 も満たしている時。利用者の認可があっても断られる
  - entitlement を持たないプロセスからの task port の取得と ptrace の接続 (これは M2 だけでも断られる)
- 守らないもの
  - Apple の診断ツール (`com.apple.system-task-ports.read.safe` を持つもの) が、対象の書き込み可能なメモリを読むこと。カーネルは断らない。中身が相手に渡らないのは、道具が出力しないことに依る → 受け持つ項目なし (S2、S3 が被害を減らす)
  - `get-task-allow` が付いている時の、宣言済みのデバッガ、差し込み (library validation だけが残る)、コアダンプ → M2
  - コアダンプ。hardened runtime の有無は関係しない → M2、S1
  - 同じ身元で hardened runtime なしに署名された別のビルドを通じて、コードの身元で渡される秘密を読むこと → M3
  - 秘密を置いたファイルや Keychain の項目を、別の経路で読むこと → M4
  - 入口から秘密を出させること → M5。argv や環境変数から読むこと → M6
  - プロセスにシグナルを送ること → 受け持つ項目なし
- なぜ守られるか
  - task port: 相手が task port を求めた時 (`task_for_pid` 等、ptrace の接続) に、カーネルの AMFI が、対象の署名のフラグ (hardened runtime か) と entitlement (`get-task-allow` があるか)、呼び出し側が宣言済みのデバッガか root かを見て決める。`mach_vm_read` や `mach_vm_write` でのメモリの読み書きには task port が要るので、port が渡らなければこの手段は使えない
  - 差し込み: プロセスの起動時、`main` より前に、dyld が対象の署名を見て `DYLD_` で始まる変数を扱うかを決める。hardened runtime で `get-task-allow` も無い対象では、ライブラリを開こうとした跡がログに出ない (変数を読んでいないと見られる)
- 欠けた時に起きること
  - `DYLD_INSERT_LIBRARIES` を付けて起動すると、ライブラリが読み込まれる。ライブラリの constructor は `main` より前に、そのプロセスのコードの身元で動く (ファイル型の Keychain の ACL も通る (観測)。data protection keychain の access group も、読み込まれたコードは本体と区別されない (一次資料: Apple DTS の回答 thread/724013「an in-memory plug-in is indistinguishable from the host app」)。M3)
  - 宣言済みのデバッガの task port の要求がカーネルを通り、利用者の認可の段に進む。認可があれば port が渡り、メモリを読み書きできる。認可は 1 度下りると共有され、その後は別のプロセスもダイアログ無しで通る。守りは、利用者がその瞬間に何のダイアログかを見分けることに依る (「利用者の認可は強い境界ではない」)
- 確かめ方: `codesign -d -v <ファイルか pid>` の `CodeDirectory` の行の `flags` に `runtime` (0x10000) がある
- 根拠: 観測 (差し込み、宣言済みのデバッガ、認可がある時とない時)、一次資料 (Hardened Runtime。保護は「SIP と組で」と書く)

### M2: 保護を緩める entitlement を付けない

- 条件: 次の 4 つの key を署名に入れない。値が false でも key があれば不合格にする (一次資料の Hardened Runtime は、false の entitlement を書かないことを求めている)
  - `com.apple.security.get-task-allow`
  - `com.apple.security.cs.allow-dyld-environment-variables`
  - `com.apple.security.cs.disable-library-validation`
  - `com.apple.security.cs.disable-executable-page-protection`
- 守るもの
  - コアダンプに写るメモリ (`get-task-allow` が無ければ、上限に依らず書かれない)
  - entitlement を持たないプロセスからの task port の取得と ptrace の接続 (`get-task-allow` が無ければ、M1 が無くても断られる)
  - M1 と合わせて、宣言済みのデバッガからの task port の取得と、起動時の差し込み
  - Apple の診断ツールが中身を出すこと (道具は `get-task-allow` のある対象の中身を出す。道具の作りに依る)
- 守らないもの
  - hardened runtime が無い時の、差し込みと宣言済みのデバッガ → M1
  - Apple の診断ツールが対象の書き込み可能なメモリを読むこと自体 → 受け持つ項目なし (M1 と同じ)
  - M1 が守らないものと同じ経路 (別のビルド → M3、置き場 → M4、入口 → M5、argv と環境変数 → M6、シグナル → 受け持つ項目なし)
- なぜ守られるか: M1 と同じ時点で、同じ仕組み (AMFI、dyld) が entitlement を見る。コアダンプは、コアダンプを起こすシグナルを対象が受けた時に、AMFI が `get-task-allow` を見て断る
- 欠けた時に起きること
  - `get-task-allow` (観測): hardened runtime があっても、dyld が `DYLD_` の変数を読むようになり (残る守りは library validation だけ)、宣言済みのデバッガの要求をカーネルが断らなくなり (認可があれば読み書きできる)、上限 (`ulimit -c`) が許せばコアダンプが書かれ、Apple の診断ツールが中身を出す。hardened runtime も無ければ、entitlement を持たないプロセスがそのままメモリを読み書きできる
  - `allow-dyld-environment-variables` (一次資料): dyld が `DYLD_` の変数を読むようになる
  - `disable-library-validation` (一次資料): Apple か同じ Team ID の署名でないライブラリも読み込むようになる
  - `disable-executable-page-protection` (一次資料): コード署名の保護が全部外れ、実行コードを検出されずに書き換えられる
- Xcode は開発用のビルドに `get-task-allow` を自動で足す (`CODE_SIGN_INJECT_BASE_ENTITLEMENTS`。一次資料の Resolving common notarization issues)。配るビルドで外れていることを確かめる
- 確かめ方: `codesign -d --entitlements - --xml <ファイル>` の出力に上の key が無い
- 根拠: `get-task-allow` は観測。他の 3 つは一次資料 (それぞれの entitlement のページ。個別の観測はしていない)

### M3: 保護の無い署名済みのビルドを作らない・残さない

- 条件
  - 秘密の置き場が自分の身元として認めるビルド (下の 2 つ) のうち、M1 と M2 を満たさないものを、署名済みのまま 1 つも残さない・配らない
    - ファイル型の Keychain の ACL (M4 の (b)): 配布用の証明書 (Developer ID) と同じ identifier のビルド
    - data protection keychain の access group (M4 の (a)): その group を名乗れる全てのビルド。access group は署名の entitlement で決まり、同じ Team ID で profile が許す別のアプリや開発用のビルド (Apple Development 署名) も、同じ group を名乗れる
  - ビルドは署名の直後に M1 と M2 を検査し、落ちたら署名済みのファイルを消す
  - デバッグ用のビルドは、ad-hoc 署名か別の identifier にする。access group を使うなら、デバッグ用のビルドに本番の group を名乗らせない (profile と entitlement から外す)。Xcode は開発用のビルドに `get-task-allow` を自動で足す (M2) ので、本番の group を名乗る開発用のビルドは、そのまま保護の無いビルドになる
- 守るもの: コードの身元を条件に渡される秘密 (ファイル型の Keychain の ACL の項目、data protection keychain の access group の項目) が、保護の無いビルドに差し込んだコードから読まれること
- 守らないもの
  - 既に出てしまった保護の無いビルド。ファイルを消しても、写しの署名は有効なまま → 受け持つ項目なし
  - 署名に使う証明書の秘密鍵が漏れること (相手が自分で同じ身元のビルドを作れる) → 受け持つ項目なし
  - 保護のあるビルドの入口から秘密を出させること → M5
  - コードの身元に依らない置き場 (ファイル、全アプリ可の項目) → M4
- なぜ要るか: OS はこの経路を止めない
  - ファイル型の Keychain の ACL は、項目を読む要求が来た時に、要求したプロセスのコードの署名を requirement に照らして判定する。見るのはプロセスの本体の身元だけで、読み込まれたライブラリは見ない (観測)
  - その requirement は信頼アプリの designated requirement (identifier、Apple が発行した証明書、Team ID) になる。requirement の言語には署名のフラグの条件が無く、hardened runtime を条件に書けない (一次資料: Code Signing Requirement Language。公開 API で信頼アプリを作る関数は SDK の `SecTrustedApplicationCreateFromPath` だけ)
  - data protection keychain は、プロセスの署名の entitlement (`keychain-access-groups` 等) から読める group を決める。entitlement は provisioning profile が許すものに限られ、開発用の profile は `<Team ID>.*` のような wildcard で group を許しうる。読み込まれたライブラリは本体と区別されない (一次資料: Apple DTS の回答 thread/685723、thread/724013)
- 欠けた時に起きること
  - hardened runtime でないバイナリにライブラリを差し込むと、そのバイナリだけを許す ACL の項目を、ライブラリの constructor が読めた。hardened runtime のバイナリでは読み込まれず、読めなかった (観測。ad-hoc 署名のバイナリと試験用の keychain)
  - したがって、保護の無い署名済みのビルドが 1 つでもあれば、相手はそのファイルを持ち込み (守りたい Mac に元から在る必要は無い)、ライブラリを差し込んで、ACL を通って秘密を読める見込み。access group でも、group を名乗れる保護の無いビルドがあれば同じになる見込み (推定、未観測)
- 確かめ方: 下の `check_hardened` を署名の直後に、実行ファイルごとに呼ぶ (.app は中の実行ファイルを 1 つずつ渡す)。universal binary は arch ごとに調べる (`codesign -d -v` は `--arch` が無いと、動かしている Mac の arch しか表示しない)。条件を満たすファイルは残り、hardened runtime の無いもの、`get-task-allow` 付きのもの、一部の arch だけ hardened runtime の無い universal binary、Mach-O でないファイルは消えて失敗する (観測。最後の 2 つは 2026-11-27、bash 3.2)

  ```bash
  # 署名の直後に、実行ファイルごとに呼ぶ。条件を満たさなければ、署名済みのファイルを消して失敗する
  check_hardened() {
    local file=$1 archs arch info flags entitlements key
    if ! archs=$(lipo -archs "$file" 2>&1); then
      rm -f "$file"
      echo "$file: Mach-O の実行ファイルではない ($archs)" >&2
      return 1
    fi
    for arch in $archs; do
      if ! info=$(codesign -d -v --arch "$arch" "$file" 2>&1); then
        rm -f "$file"
        echo "$info" >&2
        return 1
      fi
      flags=$(sed -nE 's/^CodeDirectory .* flags=0x([0-9a-fA-F]+).*/\1/p' <<<"$info")
      if [[ -z $flags ]] || (( (16#$flags & 0x10000) == 0 )); then
        rm -f "$file"
        echo "$file ($arch): hardened runtime のフラグが無い (--options runtime で署名する)" >&2
        return 1
      fi
      entitlements=$(codesign -d --entitlements - --xml --arch "$arch" "$file" 2>/dev/null)
      for key in \
        com.apple.security.get-task-allow \
        com.apple.security.cs.allow-dyld-environment-variables \
        com.apple.security.cs.disable-library-validation \
        com.apple.security.cs.disable-executable-page-protection; do
        if grep -qF "<key>$key</key>" <<<"$entitlements"; then
          rm -f "$file"
          echo "$file ($arch): 保護を緩める entitlement $key がある" >&2
          return 1
        fi
      done
    done
  }
  ```

- access group を使うなら、配る前に `codesign -d --entitlements - --xml <ファイル>` で `keychain-access-groups` を見て、本番の group を名乗るビルドを把握する。同じ group を名乗る開発用のビルドや別のアプリにも、この検査を当てる
- 根拠: 観測 (差し込んだライブラリが ACL を通ること。ACL の requirement が cdhash になる ad-hoc 署名で確かめた)、一次資料 (requirement に hardened runtime を書けないこと。access group が entitlement と profile で決まり、差し込まれたコードが本体と区別されないこと)、推定 (Developer ID の designated requirement の ACL でも、access group でも同じになること)

### M4: 保存する秘密は、自分のコードの身元にだけ読ませる Keychain の項目に置く

置き場は 2 通り。プロセスが動く文脈で選ぶ。**Keychain の置き場 選定判断基準日: 2026-11-27** (選定を変えたらこの日付と根拠も一緒に更新する)

| 動く文脈 | 置き場 |
|---|---|
| 利用者のログインセッション (app、LaunchAgent) で動き、app の形の bundle に provisioning profile を埋め込める | (a) data protection keychain と access group |
| launchd daemon (system の文脈)、root で動くもの (PAM モジュール等)、bundle にできない CLI | (b) ファイル型の Keychain の ACL |

data protection keychain はログインセッションの中でしか使えず、launchd daemon はファイル型を使うしかない (一次資料: TN3137)。root で動く PAM モジュールが (a) を使えないことは、TN3137 からの推定 (未観測)。ファイル型の Keychain の API (`SecTrustedApplicationCreateFromPath`、`SecAccessCreate`、`SecACLSetContents` を含む SecKeychain 系) は非推奨で、Apple はファイル型を「on the road to deprecation」と書く (一次資料: SDK のヘッダの `API_DEPRECATED("SecKeychain is deprecated", macos(10.x, 10.10))`、TN3137)。(a) を使えない文脈でだけ (b) を使う。

#### (a) data protection keychain と access group

- 条件
  - app の形の bundle (`Contents/MacOS/` と `Contents/embedded.provisionprofile`) にして、Developer ID で署名する。provisioning profile が許す範囲で、自分だけが名乗る access group を `keychain-access-groups` (または `com.apple.application-identifier` の既定の group) で entitlement に入れる
  - 項目は SecItem の API で `kSecUseDataProtectionKeychain` を true にし、その group (`kSecAttrAccessGroup`) を指定して作る・読む
  - その group を名乗るビルドは全部 M1、M2、M3 の対象にする
- 守るもの: 保存してある秘密を、group を名乗らないコード (別のバイナリ、`security` コマンド、スクリプト) が読むこと。項目の削除と作り直し、「常に許可」のダイアログの経路は、group の外の相手には開かない見込み (推定)
- 守らないもの
  - group を名乗るプロセスの中で動くコード。差し込まれたライブラリは本体と区別されない → M1、M2、M3
  - 同じ Team ID で、profile が同じ group を許す別のアプリや開発用のビルド → M3
  - group を名乗るバイナリを起動して、入口から出させること → M5
  - メモリに読んだ後の秘密 → M1、M2
- なぜ守られるか: Keychain が、要求したプロセスの署名の entitlement から読める group を決める。entitlement は provisioning profile が許すものに限られ、他の開発者は同じ group を名乗れない (一次資料: TN3137、Apple DTS の回答 thread/685723)
- 確かめ方: `codesign -d --entitlements - --xml <app>` に `keychain-access-groups` (または `com.apple.application-identifier`) があり、`<app>/Contents/embedded.provisionprofile` がある。group を名乗らないバイナリから同じ項目を引いて、見つからないことを見る
- 根拠: 一次資料 (TN3137、Apple DTS の回答)。観測なし (Developer ID の profile で `keychain-access-groups` を使えることも含めて未観測)

#### (b) ファイル型の Keychain の ACL

- 条件
  - 項目は、ACL の信頼アプリを自分のバイナリだけにして作る (`SecTrustedApplicationCreateFromPath` (自分の実行パス) → `SecAccessCreate` → 復号の ACL に `SecACLSetContents`)
  - バイナリは Developer ID で署名する。ad-hoc 署名では requirement が cdhash になり、ビルドのたびに ACL から外れる
  - 読み出しは非対話にする (ダイアログを出さない)。項目を同名で作り直されていると、自分の読み出しでもダイアログになる。利用者にこの種のダイアログを見せない
- 守るもの: 保存してある秘密を、ACL の外のコード (別のバイナリ、`security` コマンド、スクリプト) が読むこと
- 守らないもの
  - ACL を満たすプロセスの中で動くコード。差し込まれたライブラリは、本体の身元で読める → M1、M2、M3
  - ACL を満たすバイナリを起動して、入口から出させること → M5
  - 項目の削除と、同名での作り直し。読んだ値が自分の書いた値であることは ACL では保証されない (要るなら値に署名を付ける) → 受け持つ項目なし
  - ACL の外の相手が読もうとした時に出るパスワード付きのダイアログで、利用者が「常に許可」を押すこと (その相手が ACL に加わる) → 受け持つ項目なし
  - メモリに読んだ後の秘密 → M1、M2
- なぜ守られるか: 項目の復号を求められた時に、Keychain が、求めたプロセスのコードの署名を ACL の requirement に照らす。満たさなければ、ダイアログを出すか (対話が許されている時)、失敗を返す
- 確かめ方: 同じ作り方で試験用の項目を作り、ACL の外のバイナリ (`security find-generic-password -s <service> -a <account> -w`) から読んで、失敗するかダイアログになることを見る。ダイアログでは「拒否」を押す
- 根拠: 観測 (2026-11-06 と 2026-11-15。Developer ID 署名のバイナリの項目と、ad-hoc 署名の試験用の項目)

#### (a) と (b) に共通

- 欠けた時に起きること: `security` コマンドで作った項目や「全アプリ可」の ACL の項目は、同じ uid の任意のプロセスが確認なしで読める (観測)。モード 600 のファイルも同じ uid から読める。メモリを守っても、置き場から読まれる
- 読み手の身元を固定できない場合 (スクリプト、`security` コマンドで読むツール) は、この条件を満たせない。権限を絞った token だけを置く (reference の `keychain-secrets`)

### M5: 誰でも使える入口から、秘密を出さない・勝手に使わせない

- 条件
  - 入口 (サブコマンド、引数、環境変数、標準入力、設定ファイル、socket や XPC で受ける要求) から、秘密の値を出力しない
  - 入口から、秘密の参照先 (どの項目を読むか、どこへ送るか) を切り替えさせない
  - 秘密を使う操作 (署名、復号、送信) を入口が代行するなら、OS が出す本人確認 (Touch ID 等) の後だけにするか、要求する相手のコードの身元を検査する
  - 相手のコードの身元は、pid ではなく audit token で引く。Unix socket なら `getsockopt` の `LOCAL_PEERTOKEN` で相手の audit token を取り、`SecCodeCopyGuestWithAttributes` に `kSecGuestAttributeAudit` で渡す (一次資料: SDK の `sys/un.h`、`Security/SecCode.h`)。pid は、相手が終わって再利用されると別のプロセスを指す (推定、未観測)
- 守るもの: 相手が、メモリも ACL も破らずに、正規の入口から秘密の値を得ること・秘密を使う操作をさせること
- 守らないもの
  - メモリと置き場への直接の経路 → M1〜M4
  - 本人確認を通した利用者自身の操作 (利用者が、何の確認かを見分けずに応じる) → 受け持つ項目なし
  - 相手のコードの身元を検査する方法の抜け道 → 未調査
- なぜ要るか: OS はこの経路を止めない。Keychain の ACL はコードの身元で判定し、誰が起動したかを問わない (観測)。署名済みのバイナリは同じ uid の誰でも起動でき、開いている socket には同じ uid の誰でも繋げる
- 欠けた時に起きること: 入口が秘密を出す・使うなら、相手は M1〜M4 を 1 つも破らずに目的を果たす
- 確かめ方: 入口の一覧 (help、引数のパーサ、読む環境変数、受ける要求) を作り、秘密に触る箇所から逆に辿って、どの入口から届くかを見る。内部用の入口の数をテストで固定する
- 根拠: 観測 (ACL の判定がコードの身元だけで決まること)。残りはそこからの帰結

### M6: 秘密を、プロセスの外から見える場所に置かない

- 条件: 秘密を argv、環境変数 (自分のものも、起動する子のものも)、ログ、同じ uid が読めるファイルに置かない。子に渡すなら標準入力か、渡す相手だけが持つ fd にする
- 守るもの: 受け渡しの途中の秘密が、task port を使わない経路 (プロセスの引数と環境の一覧、ログ、ファイル) で読まれること
- 守らないもの
  - 渡した先のプロセスの中の秘密。子も M1 と M2 を満たしていなければ、子のメモリから読まれる → 子の側の M1、M2
  - 自分のメモリの中の秘密 → M1、M2
- なぜ要るか: OS はこれらを同じ uid に見せる。argv と起動時の環境変数は、カーネルが `sysctl` (`KERN_PROCARGS2`) で同じ uid のプロセスに返す。hardened runtime の対象についても返す
- 欠けた時に起きること: entitlement を持たない同じ uid のプロセスが、hardened runtime の対象の argv と起動時の環境変数を読めた。argv は `ps` で別の uid からも見える (`/bin/ps` は setuid root)
- 確かめ方: `ps -Eww -p <pid>` で、自分の引数と環境変数に秘密が出ないことを見る。起動する子についても同じ
- 根拠: 観測 (hardened runtime の ad-hoc 署名の試験プログラム。別の uid の対象には同じ呼び出しが `EINVAL` で断られた)

### M7: 他のプロセスの結論を信頼する側は、起動した後の pid の署名を検査する

他のプロセスがこのプロセスの結論や出力を信頼する構成にだけ当たる (例: root で動く PAM モジュールが、ユーザ権限に降格した helper を起動して、認証の可否を受け取る)。

- 条件: 信頼する側は、起動した後の pid について次を検査し、1 つでも満たさなければ結果を受け取らない
  - requirement: 配る実物の designated requirement (`codesign -d -r- <ファイル>` の `designated =>` の右辺) を使う。Developer ID で署名したものは `identifier "<identifier>" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "<Team ID>"` になる (観測)。2 つの OID の条件が Developer ID の証明書に絞り、Apple Development 等の同じ Team の別の証明書を外す
  - 手で書くなら、OID や OU の条件を `anchor apple generic` と `and` で結ぶ。`or` の枝に、`anchor apple generic` の無い OID や OU の条件を置かない (自己署名の証明書でも OID や OU は名乗れる。`anchor apple generic` は満たせない)。`and` で結んだ条件の並びの順は結果を変えない
  - hardened runtime のフラグ (`kSecCodeSignatureRuntime`) がある
  - 実行中のコードの状態が有効で (`kSecCodeStatusValid`)、デバッガに接続されていない (`kSecCodeStatusDebugged` が立たない)
  - M2 の 4 つの entitlement が無い
  - 署名の情報が読めない時、検証が失敗した時も不合格にする (実行中にディスク上のファイルが差し替えられると、返る署名の情報は走っているコードのものではなくなる)
- あわせて守ること
  - 実行ファイルと親ディレクトリ (`/` まで) を、信頼する側の権限でしか書けない場所に置く。起動する前のファイルの検査は、exec までの間に差し替えられる (推定。差し替えの観測はしていない)
  - 結論は、信頼する側が自分で作ったパイプで受け、明示の成功だけを成功にする。無応答や終了を成功にしない
- 守るもの: M1〜M3 を満たさないビルド (別の配布経路のもの、手作業で署名したもの) や別の身元のコードが出した結論を、信頼する側が受け取ること
- 守らないもの
  - 検査の後に起きること。検査は起動した直後の 1 回で、その後に対象を守るのは M1 と M2 のカーネルの判定 → M1、M2
  - 対象を止める・殺すこと。同じ uid のプロセスはシグナルを送れる。結果は失敗か時間切れになり、成功にはならない (上の「明示の成功だけ」) → 可用性は受け持つ項目なし
  - 検査を通ったビルド自身の不具合 → 扱わない
  - 対象が読む秘密の置き場 → M3、M4
- なぜ守られるか: 信頼する側が、起動した直後に Security.framework で、その pid で走っているコードの署名を調べる (`SecCodeCopyGuestWithAttributes` (pid) → `SecCodeCheckValidity` (requirement) → `SecCodeCopySigningInformation` (`kSecCSDynamicInformation`))。自分で起動して、まだ `wait` していない子なので、pid が他のプロセスを指すことはない。自分で起動していない相手 (socket で繋いでくる相手) は M5 のとおり audit token で引く。OS が自動で行うものではなく、検査を書いた側が呼ぶ。保護の無いビルドは、観測の要点の表のとおり同じ uid から差し込める・書き換えられるので、この検査で受け取らないことにする
- 欠けた時に起きること: 保護の無いビルドの結論を受け取る。そのプロセスには同じ uid からライブラリを差し込める・メモリを書き換えられるので、結論を偽れる
- 確かめ方: hardened runtime の無い ad-hoc 署名のバイナリと、4 つの entitlement を 1 つずつ付けたバイナリを起動して、検査が不合格にすることをテストで固定する。手では `codesign -v -R='<requirement>' <pid>` と `codesign -d -v --entitlements - <pid>`
- 根拠: 観測 (保護の無い対象が差し込まれ・書き換えられること、走っているプロセスに requirement と署名の情報を評価できること、自己署名が `anchor apple generic` を満たさないこと、Developer ID の designated requirement の形)、一次資料 (POSIX `kill()`: 同じ uid はシグナルを送れる)、推定 (起動する前の検査が差し替えに負けること)

### M8: SIP が有効な Mac で動かす

- 条件: SIP が有効であること。無効なら、M1 と M2 の守りが効いていない前提で扱う
- 守るもの: M1 と M2 が依る、カーネルの判定そのもの
- 守らないもの: SIP が有効でも、M1〜M7 のどれかが欠けて開く経路はそのまま開く。SIP は他の項目の代わりにならない
- なぜ要るか: 一次資料の Hardened Runtime は保護を「SIP と組で」と書き、Debugging tool entitlement は `get-task-allow` の無いプロセスの task port が取れないことを「SIP に守られている」と書く。SIP は Recovery の `csrutil` でだけ切り替えられる
- Debugging tool entitlement のこの記述は、hardened runtime の無い対象では観測と合わない。hardened runtime も `get-task-allow` も無い対象の task port を、宣言済みのデバッガは利用者の認可があれば取れた (「観測の要点」の表の 1 行目)。カーネルが断るのは、hardened runtime があり `get-task-allow` が無い対象だけ
- 欠けた時に起きること: SIP を無効にした Mac での振る舞いは観測していない。一次資料の Disabling and Enabling System Integrity Protection は、無効のままにすると悪意あるコードに対して脆弱になると警告する
- 確かめ方: `csrutil status`
- 根拠: 一次資料 (観測なし)

## 検証の決まり (MUST)

守りが効いていることを確かめる時は、次の全部を守る。1 つでも欠けた検証の結果は、守りの根拠にしない。

- **Apple の診断ツールの結果を証拠にしない**。`vmmap`、`heap`、`stringdups` 等は Apple 専用の entitlement (`com.apple.system-task-ports.read.safe`) を持ち、満たすべき形の対象でもカーネルから read port を受け取って、書き込み可能なメモリを読んでいる。中身を出さないのは道具の判断で、カーネルが断った結果ではない。「道具で読めなかった」は守りの証拠にならず、「道具で読めた」は普通のプロセスが読める証拠にならない。道具の entitlement は `codesign -d --entitlements - /usr/bin/heap` で見られる
- **陽性対照を置く**。同じ検査の手段が、守りの無い対象 (hardened runtime なし、`get-task-allow` あり) で成功することを、同じ回に確かめる。断られた結果だけでは、守りが効いたのか、検査が壊れているのかを区別できない
- **拒否の理由をカーネルのログで確かめる**。戻り値だけでは、断ったのがカーネルか、利用者の認可の不足かを区別できない (`lldb` は `Not allowed to attach to process` で断られることも、認可待ちで止まることもあり、表示だけでは理由が分からない)
  - task port と ptrace: `/usr/bin/log show --last 5m --style compact --predicate 'eventMessage CONTAINS "macOSTaskPolicy"'`
  - 差し込みとコアダンプ: `/usr/bin/log show --last 5m --style compact --predicate 'sender == "AppleMobileFileIntegrity" OR process == "amfid"'` (`Library Validation failed`、`Denying core dump`)
  - 認可の段に進んだか、認可が下りたか: `/usr/bin/log show --last 5m --style compact --predicate 'process == "taskgated" OR process == "authd"'`
  - `log` は zsh の組み込みと名前が衝突するので、絶対パスで呼ぶ
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
- **認可のダイアログに備える**。宣言済みのデバッガを、満たすべき形でない対象 (hardened runtime なし、または `get-task-allow` あり) に当てると、利用者の画面に認可のダイアログが出る
  - ダイアログが出うる試行の前に、Mac の前に居る利用者に「このダイアログには応じない」と伝える。出たらキャンセルしてもらう。ダイアログは要求元も対象も示さないので、伝えていないと、利用者は別の操作の確認だと思って応じる
  - 検査には打ち切り (`timeout`) を付け、カーネルが断る見込みの組 (満たすべき形の対象) から先に当てる。打ち切った後もダイアログは画面に残る
  - 応じてしまうと、認可は共有されて 10 時間続き、その間は宣言済みのデバッガを名乗る任意のプロセスが、満たすべき形でない対象をダイアログ無しで読み書きできる。`security authorize -d` では取り消せなかった。ログアウトする
  - 認可がある状態とない状態を分けて記録する (結果が変わる)
- **記録に環境を書く**。macOS の版、SIP の状態、開発者モードの状態、認可の有無、日付。当てていない組は「未観測」と書き、観測した組からの推論と分ける

## SHOULD

どれも境界にはならない。MUST の前提が崩れた時の被害を減らすか、守りを重ねる。SHOULD を満たしても、MUST の欠けは埋まらない。

### S1: コアダンプの上限を 0 にする

- 条件: 起動の直後、秘密を読む前に `setrlimit(RLIMIT_CORE)` で soft と hard を 0 にし、設定できなければ何も読まずに終わる。別の権限から起動する側は、exec の前の子で設定する
- 守るもの: コアダンプのファイルに写るメモリ。M2 の観測 (カーネルが断る) が当てはまらない場合に備える 2 つ目の守り
- 守らないもの
  - 動作中のメモリの読み書き、差し込み → M1、M2
  - コアダンプ以外の、メモリの写しが残る場所 (スワップ等) → 未調査
- なぜ守られるか: カーネルは、コアダンプを書く時にそのプロセスの上限を見る。hard を 0 にすると、特権の無いプロセスは上げ直せない
- 境界にならない理由: `get-task-allow` の無いプロセスのコアダンプは、上限に依らずカーネルが断る (試験プログラムでの観測)。M2 を満たしていれば、この経路は既に閉じている
- 根拠: 観測 (試験プログラム。実物のバイナリのコアダンプは観測していない)、一次資料 (`setrlimit(2)`)

### S2: 秘密を、使い終わったら消える型で包む

- 条件: 秘密を素の文字列やバイト列で持たず、drop の時に 0 で上書きする型 (Rust なら `secrecy`、`zeroize`) で包む。ログやデバッグ出力に中身が出ない型を選ぶ
- 守るもの: 使い終わった後にメモリに残る写し。MUST の前提が崩れた時や、Apple の診断ツールの作りが変わって中身が出るようになった時に、読める秘密と時間を減らす
- 守らないもの
  - 使っている間の値。動作中のメモリを読める相手には読める → M1、M2
  - 包んでも消せない写し (Keychain の API の内部、JSON のパーサの作業用のバッファ、ライブラリが導いた鍵、再確保で解放された領域) → 受け持つ項目なし
- なぜ守られるか: OS の仕組みではなく、型が drop の時に上書きする。読む経路を塞ぐものではない
- 根拠: 推定 (依存ライブラリのソースを読んだ範囲。メモリを読んで確かめてはいない)

### S3: メモリに持つ秘密を、読まれても致命的にならないものに絞る

- 条件
  - 読まれると承認の偽造や権限の昇格に直結する鍵 (署名鍵、全権の token) を、常駐するプロセスに持たせない。使う操作の間だけ読む短命のプロセスに分ける
  - 常駐するプロセスが持つのは、漏れても損失が狭い秘密 (権限を絞った token、要求ごとの使い捨ての鍵) にする (reference の `keychain-secrets`)
  - 取り出せない鍵 (Keychain の非抽出の鍵、Secure Enclave) は、前提が崩れた時に鍵の値の持ち出しを防ぐ選択肢
- 守るもの: MUST の前提が崩れた時と、Apple の診断ツールの作りが変わった時の、被害の上限
- 守らないもの
  - 読まれること自体 → M1〜M6
  - 取り出せない鍵でも、プロセスの制御を取られた時に勝手に使われること。使うたびに生体を求める鍵でなければ防げない (推定)
- なぜ守られるか: 守る仕組みではなく、漏れるものを減らす設計
- 根拠: 推定 (取り出せない鍵と Secure Enclave は確かめていない)

### S4: 別の権限から起動する側は、呼び出し元の状態を子に持ち込まない

- 条件: 実行ファイルは絶対パスで指定し、環境は空にしてから必要なものだけを渡し、標準入出力以外の fd を閉じる
- 守るもの: 呼び出し元の環境変数や fd が、子の入口 (M5) になること
- 守らないもの
  - 差し込み。止めているのは M1 と M2 で、環境を空にすることではない (相手は自分で環境を付けて起動できる) → M1、M2
  - 子が自分で開く入口 → M5
- なぜ守られるか: 守る仕組みではなく、起動する側が渡すものを減らす
- 根拠: 推定

## やっても守りに数えないもの

- **プロセスの中の自己検査** (起動時に自分の署名やフラグを確かめてから秘密を読む)。守りたい場面は、hardened runtime でないビルドにライブラリを差し込まれた時だが、差し込まれた constructor は `main` より前に動き、検査を経ずに秘密を読む (観測)。この経路を受け持つのは M3
- **対象の側での、接続や読み取りの検出** (検出したら終了する)。task port での読み取りは、対象の側からは何も見えない。見える副作用 (書き込み、停止の飛び、`CS_DEBUGGED`) は、どれも読まれた後にしか分からない。制御を取れる相手は、検出のスレッドを止めてから読み書きできた (観測)。満たすべき形の対象では、接続はカーネルが断るので、検出が防ぐものは無い
- **`ptrace(PT_DENY_ATTACH)`**。ptrace での接続と `lldb` は止めるが、task port での読み取りは止めない (観測。保護の無い対象で、呼んだ後も読めた)
- **利用者の認可のダイアログ**。満たすべき形でない対象の守りとして数えない (「利用者の認可は強い境界ではない」)
- **Apple の診断ツールで中身が出ないことの確認** (検証の決まり)

## 未調査・未観測の経路

MUST を全部満たしていても、次は確かめていない。

- Apple の診断ツールで中身を取り出す経路のうち、試していないもの
  - `--help` に載らないオプションや、`DYLD_` 以外の環境変数で、道具の出力の制限を外せるか
  - 将来の版の道具の振る舞い (中身が出ないことは道具の作りに依る)
  - Instruments と `xctrace` (Allocations 等)
  - root が要る道具 (`tailspin`、`spindump`、`trace`、`ktrace`、`fs_usage`、`powermetrics`、`dtrace`)
  - 道具が書く一時ファイルや、道具が使う XPC サービスを経由して中身が出るか
  - 道具が出す「確保済みのブロックを指す値の場所」から秘密が漏れうるか (秘密の値がブロックのアドレスと一致する時だけ出る形なので、乱数の鍵ではまず起きないと見るが、推定)
- 認可がある状態での、root のプロセスが降格して起動した対象への宣言済みのデバッガ (利用者が起動した対象では、認可があっても断られた)
- 認可がログアウトで消えるか
- 開発者モードを有効にした Mac (`DevToolsSecurity -enable`)。変わるのは利用者の認可の段で、満たすべき形の対象への要求は認可より前にカーネルが断るので、影響しない見込み (推定)。満たすべき形でない対象は、ダイアログ無しで読まれうる (推定)
- カーネルのログに出る `declared read-only debugger` に当たる entitlement と、それで何ができるか。候補は `gcore` が持つ `com.apple.security.cs.debugger.read.root` で、ad-hoc 署名で自分に付けても起動は止められなかった (観測、2026-11-27)。付けたプロセスから他のプロセスの read port を求めた時の結果は未観測
- 認可の設定にある `system.privilege.taskport.safe` (`class: allow`、つまりダイアログ無しで許される。2026-11-27 に `security authorizationdb read` で読んだ値)。どの要求がこの right を使い、満たすべき形でない対象の read port がダイアログ無しで渡るか
- Developer ID で署名した実物のバイナリのコアダンプ (観測は試験プログラムだけ)。`get-task-allow` のある対象で `ulimit -c` が 0 の時
- Developer ID の designated requirement の ACL の項目を、同じ identifier と Team ID で hardened runtime なしに署名したビルドに差し込んだライブラリから読めるか (M3 の推定の部分)。System Keychain の項目での同じ観測
- data protection keychain の access group (M4 の (a)) の全体: Developer ID の profile で `keychain-access-groups` を使えるか、group を名乗らないバイナリから項目を読めない・消せないこと、group を名乗る保護の無いビルドに差し込んだライブラリから読めること (M3 の推定の部分)
- SIP を無効にした Mac での、表の各手段の結果
- hardened runtime の他の例外の entitlement (`allow-jit`、`allow-unsigned-executable-memory`) が、同じ uid からの経路を開くか
- socket、XPC、Mach service で要求を受けるプロセスが、相手のコードの身元を検査する方法とその抜け道
- スワップ、メモリの圧縮、休止のイメージに写った秘密
- 画面やキー入力を介する経路 (Accessibility、Apple Events、画面の読み取り)
- macOS の他の版
