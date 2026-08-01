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
| [kubernetes.yml](docs/kubernetes.md) | Kubernetes(k3s)のコントロールプレーン / ワーカーを構築 |

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
複数のロールで使う処理は `tasks/` 配下に置いて共有しています。
**どれを使うかは各ロールが選びます**(例: Dockerは`development`と`authentik`だけ。
`kubernetes`はk3s同梱のcontainerdを使うため入れません)。

| ファイル | 内容 | 使うロール |
| --- | --- | --- |
| `register-vm-host.yml` | 接続先VMの登録とSSH疎通確認 | 全playbook |
| `assert_debian.yml` | 対象OSがDebianであることの確認 | 全ロール |
| `update_packages.yml` | apt update && upgrade | 全ロール |
| `configure_timezone.yml` / `configure_locale.yml` | タイムゾーン / ロケール | 全ロール |
| `configure_swap.yml` | zramによる動的swap | 全ロール(`kubernetes`は既定で無効化) |
| `configure_admin_group.yml` | SSHユーザーをsudoグループに追加 | 全ロール |
| `install_base_packages.yml` | git, curl, nfs-common等 | 全ロール |
| `install_qemu_guest_agent.yml` | QEMUゲストエージェント | 全ロール |
| `install_docker.yml` | Docker(compose込み)とdockerグループ追加 | `development` / `authentik` |

- `nfs-common` はどのVMからでもNFS共有をマウントできるよう基本パッケージに含めています
  (Kubernetesのnfs系ボリュームもノード側のこれを使います)

- QEMUゲストエージェントは、ホスト側で `qm set <vmid> --agent enabled=1` が必要です
  (`proxmox-hosts/` の管轄。未設定でもplaybookは失敗せず案内を表示します)
- `docker.service` を有効化するため、`restart: unless-stopped` のコンテナは
  VM再起動後に自動復帰します
