# Ansible Playbook コマンドリスト
- このディレクトリは `proxmox-hosts/` と `proxmox-vms/` のplaybookを**まとめて実行**します
- 独自の処理は持たず、既存のplaybookを `import_playbook` で順番に呼び出すだけです。
  全サービスで同じになる部分は次の2箇所に共通化しています
  - `tasks/` : 構築対象の決定(インベントリ/手動指定)・変数の解決・表示と登録
  - `playbooks/_provision_vm.yml` : テンプレート構築 → VM作成 → ハードウェア調整 →
    動作設定 → cloud-init → 起動 → SSH接続待ち、の共通フロー(単体では実行しない)
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
| [kubernetes.yml](docs/kubernetes.md) | Kubernetes(k3s)のクラスタを構築する(上と同じ流れ + VM内でk3s導入とクラスタへの参加) |
| [technitium-dns.yml](docs/technitium-dns.md) | DNSサーバー(Technitium)のVMを構築する(上と同じ流れ + VM内でDocker ComposeによるDNSサーバー構築) |
| [cloudflare-ddns-ui.yml](docs/cloudflare-ddns-ui.md) | DDNS更新(cloudflare-ddns-ui)のVMを構築する(上と同じ流れ + VM内でDocker ComposeによるDDNS更新サービス構築) |
| [wg-easy.yml](docs/wg-easy.md) | VPN(wg-easy)のVMを構築する(上と同じ流れ + VM内でDocker ComposeによるWireGuard構築) |
| [supabase.yml](docs/supabase.md) | Supabase(セルフホスト)のVMを構築する(上と同じ流れ + VM内でDocker ComposeによるSupabase構築) |

いずれも構築の流れは同じで、最後に呼ぶ `proxmox-vms/` のplaybookだけが違います。
`kubernetes.yml` だけは、最後のVM内セットアップを
**コントロールプレーン → ワーカーの順に1台ずつ**実行します
(ワーカーが参加先からトークンを取得するため)。

## インベントリ
インベントリは**playbookごとにファイルを分けています**(グループ名 = playbook名)。
他のplaybookを追加するときは `inventory/<playbook名>.yml` を同じ形式で作ってください
(`ansible.cfg` でディレクトリ指定しているので、置くだけで読み込まれます)。

```
inventory/
  development.yml     # playbooks/development.yml 用(グループ: development)
  authentik.yml       # playbooks/authentik.yml 用(グループ: authentik)
  kubernetes.yml      # playbooks/kubernetes.yml 用(グループ: kubernetes)
  technitium-dns.yml  # playbooks/technitium-dns.yml 用(グループ: technitium_dns)
  cloudflare-ddns-ui.yml # playbooks/cloudflare-ddns-ui.yml 用(グループ: cloudflare_ddns_ui)
  wg-easy.yml         # playbooks/wg-easy.yml 用(グループ: wg_easy)
  supabase.yml        # playbooks/supabase.yml 用(グループ: supabase)
```

- ⚠ **グループ名にハイフンは使えません**(Ansibleが警告を出します)。
  playbook名にハイフンが入る場合だけ、グループ名はアンダースコアにしてください
  (`technitium-dns.yml` → グループ `technitium_dns`)

- ホスト名は**構築するVMのIPアドレス**です。VMごとの値(VMID・VM名・構築先ノード)は
  `hosts:` 配下に、共通の値は `vars:` に書きます
- パスワードは平文で置かないでください(`-e` で渡すか `ansible-vault encrypt_string` を使用)

## 新しいサービスを追加するとき
1. `proxmox-vms/` にロールとplaybookを作る(既存ロールの `main.yml` の構成に合わせ、
   共通処理は `proxmox-vms/tasks/` のものを import する)
2. `playbooks/` に既存のplaybook(例: `technitium-dns.yml`)をコピーし、次の箇所だけ変える
   - `hosts:` と `pv_group`(インベントリのグループ名。2箇所)
   - `pv_service_summary` / `pv_resize_hint_reason` / `pv_resize_example`(構築内容の表示用)
   - 最後の `import_playbook`(`proxmox-vms/` の対応するplaybook)
   - サービス固有の検証やvaultがあれば「構築対象を確認する」プレイに足す
     (`cloudflare-ddns-ui.yml` / `wg-easy.yml` が実例)
3. `inventory/<playbook名>.yml` を上と同じ形式で作る
