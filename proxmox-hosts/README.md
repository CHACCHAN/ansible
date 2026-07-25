# Ansible Playbook コマンドリスト
- このディレクトリはProxmoxホストに対して操作を行います
- VM内には影響しません
- インベントリファイルは使用しません。接続先は `proxmox_ip` にIPアドレスを直接指定します
  (ノード名は接続先ホストから自動取得されます)

## 指定したノードに対してCloudInitのテンプレートを構築する
- os_typeはgroup_vars/os_defaults/<OSタイプ>.ymlから選んでください(例: debian)
```sh
ansible-playbook playbooks/proxmox_template_build.yml --ask-vault-pass -vv \
-e "proxmox_ip=<ProxmoxホストのIPアドレス> proxmox_storage=<Proxmoxホストのストレージ名> \
    os_type=<OSタイプ> ssh_user=<ユーザ名> ssh_pubkey='<公開鍵>' \
    ipv4=<IPv4アドレス/CIDR> ipv4_gw=<IPv4アドレス> \
    ipv6=<IPv6アドレス/CIDR> ipv6_gw=<IPv6アドレス>"
```
- SSHユーザは既定で `root`。変更する場合は `-e "proxmox_ssh_user=<ユーザ名>"` を追加します
- 対象VMIDのテンプレートがクラスタ内の別ノードに存在する場合は、Proxmox API経由で
  そちらを削除してから接続先ノードで再構築します
