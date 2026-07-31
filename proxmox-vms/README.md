# Ansible Playbook コマンドリスト
- このディレクトリはProxmox VM「内部」に対してSSH接続で操作を行います。
  ホスト側の操作(ハードウェア設定・VMの起動停止など)は `proxmox-hosts/` の管轄です
- **Debian13(cloud image)専用**。対象VMは起動済みである必要があります
- インベントリファイルは使用しません。接続先は `vm_ip` にIPアドレスを直接指定します

## Playbook一覧
| Playbook | 内容 |
| --- | --- |
| [development.yml](docs/development.md) | 開発専用VM(Cockpit/Docker/k8s CLI、任意でRDPデスクトップ) |
| [authentik.yml](docs/authentik.md) | Authentik(SSO/IdP)をDocker Composeで構築 |

## 全playbook共通の指定
```sh
ansible-playbook playbooks/<playbook名>.yml -vv \
-e "vm_ip=<VMのIPアドレス> vm_ssh_user=<SSHユーザ名> vm_ssh_prikey=~/.ssh/<秘密鍵ファイル名>"
```

| 変数 | 既定値 | 内容 |
| --- | --- | --- |
| `vm_ip` | (必須) | 対象VMのIPアドレス |
| `vm_ssh_user` | (必須) | SSH接続するユーザー名(cloud-initで作成したユーザー) |
| `vm_ssh_prikey` | (必須) | SSH秘密鍵のパス |
| `vm_timezone` | `Asia/Tokyo` | タイムゾーン |
| `vm_locale` | `ja_JP.UTF-8` | ロケール |
| `vm_zram_percent` | `50` | zram(圧縮メモリ上のswap)に割り当てるRAM使用率(%) |
| `vm_reboot_after_setup` | `true` | 構成完了後にVMを再起動するか |

- ログインパスワードはここでは設定しません。**VM構築時のcloud-initで設定したパスワード**を
  使います(変更は `proxmox-hosts/playbooks/proxmox_vm_cloudinit.yml` またはVM内の`passwd`)
- 各playbookは最後にVMを再起動します(dockerグループへの追加とカーネル更新の反映のため)

## 共通セットアップ(tasks/)
どのVMにも必要な処理は `tasks/` 配下に置き、全ロールで共有しています。

| ファイル | 内容 |
| --- | --- |
| `register-vm-host.yml` | 接続先VMの登録とSSH疎通確認 |
| `assert_debian.yml` | 対象OSがDebianであることの確認 |
| `update_packages.yml` | apt update && upgrade |
| `configure_timezone.yml` / `configure_locale.yml` | タイムゾーン / ロケール |
| `configure_swap.yml` | zramによる動的swap |
| `configure_admin_group.yml` | SSHユーザーをsudoグループに追加 |
| `install_base_packages.yml` | git, curl等 |
| `install_qemu_guest_agent.yml` | QEMUゲストエージェント |
| `install_docker.yml` | Docker(compose込み)とdockerグループ追加 |

- QEMUゲストエージェントは、ホスト側で `qm set <vmid> --agent enabled=1` が必要です
  (`proxmox-hosts/` の管轄。未設定でもplaybookは失敗せず案内を表示します)
- `docker.service` を有効化するため、`restart: unless-stopped` のコンテナは
  VM再起動後に自動復帰します
