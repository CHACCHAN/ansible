# proxmox_vm_hardware.yml
既存VMのハードウェア設定を変更します。CPU/メモリの変更や、ディスク・NICなどの追加/削除を
まとめて行える汎用のplaybookです。

- **対象VMの電源がオフの場合のみ**変更できます(起動中はエラーで終了します)
- WebUIを操作しなくても、`qm set` が扱えるハードウェア設定はすべて指定できます
- 指定できるオプションの一覧は以下の公式ドキュメントを参照してください
  - `qm` コマンドのマニュアル(全オプション一覧): https://pve.proxmox.com/pve-docs/qm.1.html
  - QEMU/KVM仮想マシンの解説(CPU/メモリ/ディスク/NIC等の設定ガイド): https://pve.proxmox.com/pve-docs/chapter-qm.html
- SSHユーザは既定で `root`。変更する場合は `-e "proxmox_ssh_user=<ユーザ名>"` を追加します
- 指定したVMIDがクラスタ内に見つからない場合、接続先ノード以外に存在する場合は
  エラーで終了します(`proxmox_ip` にVMが存在するノードのIPアドレスを指定し直してください)

## 1. vm_hardware の書式
`vm_hardware` はカテゴリ別にネストした辞書で指定します。**JSON文字列で渡す場合はスペースを
含めないこと**(辞書そのものを渡すことも可能。詳しくは 5 を参照)。

| カテゴリ | 内容 | 主なキー(= qmのオプション名) |
| --- | --- | --- |
| `cpu` | CPU設定(単一の辞書) | `cores`, `sockets`, `type`(→`cputype`のエイリアス), `numa`, `vcpus`、その他は`--cpu`のプロパティ文字列にそのまま渡す(`flags`, `hidden`等) |
| `memory` | メモリ設定(単一の辞書) | `size`(→`--memory`), `balloon`(→`--balloon`) |
| `disks` | ディスクの追加/変更(リスト) | `bus`(`scsi`/`sata`/`ide`/`virtio`), `index`, 新規作成は`storage`+`size`、既存ボリューム参照は`volume`。他に`discard`, `ssd`, `cache`, `format`等を追加可能 |
| `network` | NICの追加/変更(リスト) | `index`、他は`model`, `bridge`, `firewall`, `tag`, `macaddr`, `mtu`, `rate`等、qmの`net[n]`オプションのキー名をそのまま指定 |
| `options` | 上記に当てはまらない残りすべて | `qm set`のオプション名をキーにした`{"オプション名":値}`(例: `boot`, `bios`, `machine`, `vga`等) |
| `resize` | 既存ディスクの拡張(リスト) | `bus`, `index`, `size`(GiB)。例: `[{"bus":"scsi","index":0,"size":256}]` |

`disks` はディスクの**新規作成/付け替え**のため、既存ディスクに指定すると新しい空ディスクに
置き換わり、元のディスクは未使用ボリュームとして残ります。**クローンしたVMのディスクを
広げる場合は `resize`** を使ってください(縮小には非対応のため、現在のサイズが指定サイズ
以上の場合は何もしません)。

`agent` や `onboot` など**稼働中でも変更できる設定**は
[proxmox_vm_options.yml](proxmox_vm_options.md) を使うと電源を落とさずに変更できます。

`vm_hardware_delete` には削除したいqmのプロパティ名を `["net1","scsi2"]` のような配列文字列
(**スペースを含めないこと**)、またはリストそのもので指定します。`vm_hardware` と同時に指定
することも可能です。`vm_hardware`/`vm_hardware_delete` の少なくとも一方は必須です。

## 2. CPU/メモリを変更する例
```sh
ansible-playbook playbooks/proxmox_vm_hardware.yml --ask-vault-pass -vv \
-e 'proxmox_ip=<ProxmoxホストのIPアドレス> vm_id=<対象VMのVMID> \
    vm_hardware={"cpu":{"cores":4,"sockets":1,"type":"host"},"memory":{"size":8192}}'
```

## 3. ディスクを追加しつつ、NICを追加/削除する例
```sh
# ディスクを追加(新規32GB)しつつ、NIC1枚追加+NIC1を削除する
ansible-playbook playbooks/proxmox_vm_hardware.yml --ask-vault-pass -vv \
-e 'proxmox_ip=<ProxmoxホストのIPアドレス> vm_id=<対象VMのVMID> \
    vm_hardware={"disks":[{"bus":"scsi","index":1,"storage":"local-lvm","size":32}],"network":[{"index":2,"model":"virtio","bridge":"vmbr0"}]} \
    vm_hardware_delete=["net1"]'
```

## 4. cpu/memory/disks/network に無いオプションを変更する例
```sh
# 起動順序・QEMU Guest Agentなど、options経由で指定する
ansible-playbook playbooks/proxmox_vm_hardware.yml --ask-vault-pass -vv \
-e 'proxmox_ip=<ProxmoxホストのIPアドレス> vm_id=<対象VMのVMID> \
    vm_hardware={"options":{"boot":"order=scsi0;net0","agent":1}}'
```

## 5. 値にスペースを含めたい場合(例: description)
`-e` 全体をJSONにする方法が使えます:
```sh
ansible-playbook playbooks/proxmox_vm_hardware.yml --ask-vault-pass -vv \
-e '{"proxmox_ip":"<ProxmoxホストのIPアドレス>","vm_id":101,"vm_hardware":{"options":{"description":"my server"}}}'
```
