# CLI 設計パターン

kawaz 製 CLI に共通の設計規約。好みの表明と、常駐プロセスを持つ CLI の標準サブコマンド体系。

- [preferences](preferences.md) — CLI のサブコマンド・`--help`・bool フラグ・引数位置・completion を決める時に読む。
  発火語: CLI 設計, サブコマンド, --help, completion
- [daemon-subcommands](daemon-subcommands.md) — 常駐プロセスを持つ CLI に `daemon` / `service` サブコマンドを付ける時に読む。
  発火語: daemon サブコマンド, 常駐, launchd / systemd 登録, supervise
