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
- これは**初期パスワード**です。対象VM上で`passwd`コマンドにより変更した後は、
  playbookを再実行しても**上書きされません**(設定済みの場合はスキップします)。
  意図的に初期値へ戻したい場合のみ `-e "cockpit_user_password_force=true"` を指定してください
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
  8. QEMUゲストエージェント(`qemu-guest-agent`)のインストールと有効化。
     GUIの有無に関わらず全VM共通で導入します。ProxmoxからのIPアドレス表示・正常な
     シャットダウン制御・整合性を保ったスナップショットのために使います。
     ホスト側で `qm set <vmid> --agent enabled=1` が必要ですが、それは
     `proxmox-hosts/` 側の管轄です(未設定でも本ロールは失敗しません)
  9. Cockpitのインストールと初期パスワード設定
  10. Dockerのインストール(公式スクリプト)。SSHユーザーをdockerグループに追加するため、
      sudoなしで`docker`コマンドが使えます
  11. Cockpit Docker Manager(cockpit-dockermanager)プラグインの導入。
      GPG署名の無い第三者リポジトリ(`trusted=yes`)から導入するため、
      信頼できるソースかどうかは各自でご判断ください
  12. PackageKit(Cockpitの「ソフトウェア更新」)のオフライン誤検知の回避(後述)
  13. kubectl・Helmのインストール(いずれも公式配布物・公式インストールスクリプトを使用)
  14. VSCode Server(Remote-SSH)の定期クリーンアップ設定。接続のたびに蓄積する
      `~/.vscode-server/bin/<バージョン>` を、一定日数触られていなければsystemd timerで
      定期的に削除します。標準のCockpit(Administrative accessモードのServicesページ)で
      このtimer/serviceをそのまま確認・操作できるため、追加のCockpitプラグインは不要です

### PackageKitのオフライン誤検知への対処(全VM共通)
Cockpitの「ソフトウェア更新」画面が `Cannot refresh cache whilst offline` で失敗するのを
避けるため、**NetworkManager管理下にダミーの仮想インターフェースを1つ追加**しています。

| 項目 | 値 |
| --- | --- |
| 接続名 | `packagekit-online-workaround` |
| インターフェース名 | `packagekit-fix`(カーネルの15文字制限のため短縮形) |
| IPアドレス | `10.99.99.1/24`(実在しないプライベートアドレス) |
| ゲートウェイ | `10.99.99.254` |
| 経路メトリック | `20000` |

**これは判定用の存在で、実際のネットワーク通信には一切使用しません。**

原因はCockpit自体のバグではなく、PackageKitとNetworkManagerの既知の相互作用です。
本環境ではeth0がifupdown(cloud-init)管理下でNetworkManagerの管理対象外、Dockerが作る
docker0はNetworkManager管理下だがゲートウェイを持ちません。PackageKitは自分で疎通確認を
せずNetworkManagerに問い合わせるだけなので、NetworkManagerが「管理下にゲートウェイ付きの
有効な接続が無い」と判断して「ローカルのみ接続」と返し、PackageKitもオフラインと誤判定
します(実際にはeth0で正常に疎通しており、`apt update` 等は問題なく動作します)。

ダミー接続にはデフォルトゲートウェイが必要ですが、そのままでは実通信の経路を奪う恐れが
あるため、**経路メトリックに十分大きな値(20000)を設定**し、カーネルが常にeth0側の
既定経路(metric 0)を優先するようにしています。eth0のifupdown管理やdocker0の設定には
一切手を加えません。

アドレスが既存ネットワークと衝突する場合は上書きできます。

```sh
-e "development_packagekit_dummy_ip4=172.31.99.1/24 \
    development_packagekit_dummy_gw4=172.31.99.254"
```

確認方法:

```sh
# CONNECTIVITY が full になっていること
nmcli general status

# NetworkState が 2(Online)を返すこと
gdbus call --system --dest org.freedesktop.PackageKit \
  --object-path /org/freedesktop/PackageKit \
  --method org.freedesktop.DBus.Properties.Get \
  org.freedesktop.PackageKit NetworkState

# 実通信の既定経路がeth0側のままであること(dev eth0 が最上位)
ip route show default
```

## RDPデスクトップを追加する
`vm_gui_required=true` を指定すると、`development.yml`(developmentロール)の実行時に
XFCEデスクトップ + xrdpも構成されます。
**既定(`false`)では一切インストールされません。**

接続先は**VM自身のIPの固定ポート3389**です。Windowsのリモートデスクトップ接続(mstsc)
や各種RDPクライアントからそのまま繋げるため、他サービスと同様にIAP(認証プロキシ)配下に
置くことができます。

```sh
ansible-playbook playbooks/development.yml -vv \
-e "vm_ip=<VMのIPアドレス> vm_ssh_user=<SSHユーザ名> vm_ssh_prikey=~/.ssh/<秘密鍵ファイル名> \
    cockpit_user_password=<初期パスワード> \
    vm_gui_required=true"
```

- `vm_gui_required`(既定: `false`) — `true`のときのみGUIデスクトップ一式を構成します
- ログインは**PAM経由のLinux通常ログインパスワード**です。`cockpit_user_password`で
  設定した初期パスワード(または対象VM上で`passwd`コマンドにより本人が変更した後の
  最新パスワード)をRDPのログイン画面で入力します。RDP専用のパスワードはありません
  (xrdpは標準でPAM認証に対応しているため、追加のPAM設定は不要です)

### Proxmoxホスト側の設定について
RDPはVM自身のIPに直接繋ぐ方式のため、**ディスプレイタイプの変更は不要**です
(既定のままで構いません)。ホスト側で必要なのはQEMUゲストエージェントの有効化
(`qm set <vmid> --agent enabled=1`)のみで、これはGUIの有無に関わらず推奨されます。

### 構成される内容
1. XFCE一式(X11セッション。**Waylandは対象外**)、日本語フォント、`dbus-x11`
2. `xrdp`(**常時起動**、ポート3389)。RDPセッションで`startxfce4`が起動するよう
   `~/.xsession` を配置します(パッケージのconffileである`/etc/xrdp/startwm.sh`は
   変更しません)
3. ブラウザ(**Google Chrome** と **Firefox ESR**)。**既定のブラウザはChrome**です

ディスプレイマネージャ(lightdm等)は導入しません。xrdpはRDP接続のたびに`xrdp-sesman`が
Xセッションを起動するため、常駐のディスプレイマネージャは不要で、既定の起動ターゲットも
`multi-user.target`のままで動作します。

オンデマンド起動・アイドルタイムアウトは実装していません(常時起動を許容する方針です)。

### ブラウザについて
- Google ChromeはDebianの公式リポジトリに無いため、Google公式のaptリポジトリを
  GPG署名鍵付きで追加して `google-chrome-stable` を導入します
- FirefoxはDebian mainの `firefox-esr` を使用します
- 既定ブラウザはDebian流の `x-www-browser`(update-alternatives)と、デスクトップの
  MIME関連付け(`/etc/xdg/mimeapps.list`)の両方をChromeに向けることで設定しています
- 既定をFirefoxに変えたい場合は以下を指定してください
  ```sh
  -e "development_default_browser_bin=/usr/bin/firefox-esr \
      development_default_browser_desktop=firefox-esr.desktop"
  ```

### 動作確認
```sh
# サービスの状態
systemctl status xrdp.service xrdp-sesman.service qemu-guest-agent.service

# 3389番で待ち受けているか
ss -tlnp | grep 3389
```

Windowsのリモートデスクトップ接続(mstsc)で `<VMのIPアドレス>` を指定し、Linuxの
ユーザー名・パスワードを入力するとXFCEデスクトップが表示されます。

接続後にデスクトップが表示されない場合は、セッション側のログを確認してください。

```sh
cat ~/.xsession-errors
journalctl -u xrdp.service -u xrdp-sesman.service
```

## 構成完了後のVM再起動
`development.yml` は最後に対象VMを再起動します(dockerグループへの追加はログインし直す
まで反映されず、カーネル更新の適用にも再起動が必要なため)。再起動後、Ansibleはホストが
復帰するまで待機します。

再起動したくない場合は `-e "vm_reboot_after_setup=false"` を指定してください。
