# Ansible Playbook コマンドリスト
- このディレクトリはProxmox VM「内部」に対してSSH接続で操作を行います
- Proxmoxホスト自体(ハードウェア設定・VMの起動停止など)には一切触れません。
  ホスト側の操作は `proxmox-hosts/` を使用してください
- 対象VMはあらかじめ起動済みである必要があります(未起動の場合はエラーで終了します)
- インベントリファイルは使用しません。接続先は `vm_ip` にIPアドレスを直接指定します

## 開発専用VM(development)の環境をセットアップする
- **Debian(cloud image)を対象としています。他のOSでは動作しません**
- 事前に `proxmox-hosts/` 側でVMを構築・起動しておいてください
```sh
ansible-playbook playbooks/development.yml -vv \
-e "vm_ip=<VMのIPアドレス> vm_ssh_user=<SSHユーザ名> vm_ssh_prikey=~/.ssh/<秘密鍵ファイル名> \
    cockpit_user_password=<cockpit用の初期パスワード>"
```
- `cockpit_user_password` は必須です。cockpitはSSH鍵認証のみのユーザーだとパスワードが
  無くWebコンソールにログインできないため、初期パスワードとして設定します
- 以下はオプションです(省略時の既定値を記載)
  - `cockpit_user`(既定: `vm_ssh_user`と同じ) — cockpitにログインするユーザー
    (dockerグループへの追加もこのユーザーに対して行われます)
  - `development_timezone`(既定: `Asia/Tokyo`)
  - `development_locale`(既定: `ja_JP.UTF-8`)
  - `development_zram_percent`(既定: `50`) — zram(圧縮メモリ上のswap)に割り当てるRAM使用率(%)。
    固定サイズのswapfileではなく、Ubuntu同様に搭載メモリに対する割合で動的に確保されます
  - `development_vscode_cleanup_retention_days`(既定: `14`) — VSCode Serverの古いバージョンを
    何日放置したら削除するか
  - `development_vscode_cleanup_schedule`(既定: `weekly`) — VSCode Serverクリーンアップの
    実行頻度(systemdの`OnCalendar`書式)

- 実施する内容:
  1. 対象OSがDebianであることの確認
  2. OS/パッケージの更新(apt update && upgrade)
  3. タイムゾーンの設定
  4. ロケールの設定
  5. zramによる動的swapの設定
  6. SSHユーザーをsudoグループに追加
  7. 基本パッケージのインストール(git, curl)
  8. Cockpitのインストールと初期パスワード設定
  9. Dockerのインストール(公式スクリプト)。SSHユーザーをdockerグループに追加するため、
     sudoなしで`docker`コマンドが使えます
  10. Cockpit Docker Manager(cockpit-dockermanager)プラグインの導入。
      GPG署名の無い第三者リポジトリ(`trusted=yes`)から導入するため、
      信頼できるソースかどうかは各自でご判断ください
  11. kubectl・Helmのインストール(いずれも公式配布物・公式インストールスクリプトを使用)
  12. VSCode Server(Remote-SSH)の定期クリーンアップ設定。接続のたびに蓄積する
      `~/.vscode-server/bin/<バージョン>` を、一定日数触られていなければsystemd timerで
      定期的に削除します。標準のCockpit(Administrative accessモードのServicesページ)で
      このtimer/serviceをそのまま確認・操作できるため、追加のCockpitプラグインは不要です
