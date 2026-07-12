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

## Claude Code / Cline を使わない場合

`devcontainer.json` の `mounts` には、デフォルトで Claude Code (`~/.claude`) と Cline (`~/.cline`) のマウント設定が**有効な状態で含まれています**。

- `initializeCommand` がコンテナ起動前に `~/.claude`, `~/.cline` を(無ければ)自動作成するため、これらのツールを導入していない環境でもエラーでコンテナ起動が止まることはありません
- 使わない場合、単に中身が空のディレクトリがコンテナ内にマウントされるだけで実害はありません

それでも自分の環境に不要なマウントを残したくない場合は、`devcontainer.json` の該当行を削除(またはコメントアウト)してください。

```jsonc
"mounts": [
    // 不要なら以下の2行を削除してください
    "source=${localEnv:HOME}/.claude,target=/root/.claude,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.cline,target=/root/.cline,type=bind,consistency=cached",

    "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,readonly",
    "source=${localWorkspaceFolder}/.cache/pip,target=/root/.cache/pip,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.ansible,target=/root/.ansible,type=bind,consistency=cached"
],
```

削除する場合、あわせて `initializeCommand` からも `${localEnv:HOME}/.claude ${localEnv:HOME}/.cline` の部分を削除して構いません(削除しなくても、自動作成されるだけで害はありません)。

## キャッシュディレクトリについて

- `.cache/pip`, `.ansible` (プロジェクトルート直下) はpip / ansible-galaxyのダウンロードキャッシュです
- 名前付きDocker Volumeではなく、プロジェクトルート配下の通常ディレクトリへのbind mountにしています(Volumeを増やさない方針のため)
- `initializeCommand` によりコンテナ起動前に自動で `mkdir -p` されますが、`.gitkeep` で空ディレクトリ自体もリポジトリに含めています
  (bind mountはホスト側にディレクトリが実在しないと起動失敗するため: `docker: invalid mount config for type "bind": bind source path does not exist`)
- 中身は `.gitignore` 対象です。不要になったら単純に `rm -rf .cache .ansible` で削除できます(次回起動時に `initializeCommand` が空ディレクトリを作り直します)

## 注意

- `.env` は Git 管理対象外です(`.gitignore` 済み)。誤ってコミットしないよう注意してください
- `.env` を更新した場合、コンテナの再起動(`Reopen in Container` の再実行)が必要です
