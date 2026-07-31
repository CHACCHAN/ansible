# Ansible Playbook コマンドリスト
- このディレクトリは `proxmox-hosts/` と `proxmox-vms/` のplaybookを**まとめて実行**します
- 独自の処理は持たず、既存のplaybookを `import_playbook` で順番に呼び出すだけです
  (ロールもタスクも新しく作っていません)
- 各playbookは**2つの実行方法**を持ちます(対象の決め方が違うだけで、処理は共通です)
  - **インベントリ版**(既定): 構築対象を `inventory/<playbook名>.yml` に**1台1ホスト**で書き、
    `--limit` で個別に、指定なしで全台まとめて実行します。
    変数はインベントリの値が既定値で、`-e` で渡した値が常に優先されます(差分方式)
  - **手動指定版**(`-e "manual=true"`): インベントリも `--limit` も使わず、
    **すべて `-e` で指定**して1台だけ構築します
- 変数の検証は呼び出す各playbookが持っているものをそのまま使うため、
  このディレクトリでは重複した検証を行いません

## Playbook一覧
各playbookの詳しい使い方は `docs/` 配下の同名ファイルを参照してください。

| Playbook | 内容 |
| --- | --- |
| [development.yml](docs/development.md) | 開発専用VMを構築する(テンプレート構築 → VM作成 → ハードウェア調整 → 動作設定 → cloud-init設定 → 起動 → VM内セットアップ) |
| [authentik.yml](docs/authentik.md) | Authentik(SSO/IdP)のVMを構築する(上と同じ流れ + VM内でDocker ComposeによるAuthentik構築) |

どちらも構築の流れは同じで、最後に呼ぶ `proxmox-vms/` のplaybookだけが違います。

## インベントリ
インベントリは**playbookごとにファイルを分けています**(グループ名 = playbook名)。
他のplaybookを追加するときは `inventory/<playbook名>.yml` を同じ形式で作ってください
(`ansible.cfg` でディレクトリ指定しているので、置くだけで読み込まれます)。

```
inventory/
  development.yml   # playbooks/development.yml 用(グループ: development)
  authentik.yml     # playbooks/authentik.yml 用(グループ: authentik)
```

- ホスト名は**構築するVMのIPアドレス**です。VMごとの値(VMID・VM名・構築先ノード)は
  `hosts:` 配下に、共通の値は `vars:` に書きます
- パスワードは平文で置かないでください(`-e` で渡すか `ansible-vault encrypt_string` を使用)
