# Ansible Playbook コマンドリスト
- このディレクトリはProxmoxホストに対して操作を行います
- VM内には影響しません

## 指定したノードに対してCloudInitのテンプレートを構築する
- os_typeはgroup_vars/os_defaults/<OSタイプ>.ymlから選んでください(例: debian)
```sh
ansible-playbook playbooks/build-template.yml --ask-vault-pass -vv \
-e "proxmox_node=<Proxmoxノード名> os_type=<OSタイプ> \
    ssh_user=<ユーザ名> ssh_pubkey='<公開鍵>' \
    ipv4=<IPv4アドレス/CIDR> ipv4_gw=<IPv4アドレス> \
    ipv6=<IPv6アドレス/CIDR> ipv6_gw=<IPv6アドレス>"
```
