# .devcontainer セットアップ手順

## 初回セットアップ

1. `.env` を作成する(このファイルが無いとコンテナ起動に失敗します)

   ```bash
   cp .devcontainer/.env.example .devcontainer/.env
   ```

2. `.devcontainer/.env` を編集し、各値を設定する

   - `ANSIBLE_PROXMOX_GUEST_API_TOKEN`
   - `ANSIBLE_PROXMOX_PERSONAL_API_TOKEN`
   - `ANSIBLE_DEV_VM_PRIVATE_KEY_FILE` (通常はデフォルトのままでOK)
   - `ANSIBLE_K3S_PRIVATE_KEY_FILE` (通常はデフォルトのままでOK)

3. SSH秘密鍵をホストの `~/.ssh/` に配置する
   (`dev-vm-ssh`, `k3s-ssh` など、`.env` で指定したファイル名と一致させる)

4. VSCodeで `Reopen in Container` を実行

## 依存関係を追加したいとき

- Pythonパッケージを追加: `.devcontainer/requirements.txt` に追記 → コンテナを Rebuild
- Ansible collectionを追加: `.devcontainer/requirements.yml` に追記 → コンテナを Rebuild

## 注意

- `.env` は Git 管理対象外です(`.gitignore` 済み)。誤ってコミットしないよう注意してください
- `.env` を更新した場合、コンテナの再起動(`Reopen in Container` の再実行)が必要です