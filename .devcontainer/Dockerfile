FROM mcr.microsoft.com/devcontainers/python:3.12-trixie

# Runtime tools needed for Ansible operations
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    openssh-client \
    rsync \
    sshpass \
    ca-certificates \
    jq \
    less \
    vim \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

RUN pip install --no-cache-dir ansible ansible-lint

CMD ["sleep", "infinity"]
