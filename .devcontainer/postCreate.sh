#!/usr/bin/env bash
set -euo pipefail

echo "=== postCreate: .env existence check ==="
if [ ! -f /workspace/.devcontainer/.env ]; then
    echo "!! .devcontainer/.env not found."
    echo "!! cp Execute `cp .devcontainer/.env.example .devcontainer/.env` and set the values."
    echo "!! (If you don't create a .env file, the API token and other fields will remain empty after the container is rebuilt.)"
fi

echo "=== postCreate: SSH key permission correction ==="
if [ -d /root/.ssh ]; then
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/* 2>/dev/null || true
fi

echo "=== postCreate: Enable Python argcomplete ==="
activate-global-python-argcomplete

echo "=== postCreate: Checking the version of the ansible-galaxy collection. ==="
ansible-galaxy collection list

echo "=== postCreate: Complete! ==="