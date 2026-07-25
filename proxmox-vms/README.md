# Ansible Playbook コマンドリスト
- このディレクトリはProxmox VMに対して操作を行います
- ホストには直接影響はしません

## 開発専用VMの構築を行う
```sh
ansible-playbook playbooks/build-template.yml --ask-vault-pass -vv \
-e "proxmox_ip=<ProxmoxホストのIPアドレス> proxmox_storage=<Proxmoxホストのストレージ名> \
    os_type=<OSタイプ> ssh_user=<ユーザ名> ssh_pubkey='<公開鍵>' \
    ipv4=<IPv4アドレス/CIDR> ipv4_gw=<IPv4アドレス> \
    ipv6=<IPv6アドレス/CIDR> ipv6_gw=<IPv6アドレス>"
```
