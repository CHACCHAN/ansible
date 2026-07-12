FROM python:3.13-slim-trixie

# Runtime tools needed for Ansible operations
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
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

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

WORKDIR /tmp/build

# Python Dependency
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Ansible Dependency Modules
COPY requirements.yml .
RUN ansible-galaxy collection install -r requirements.yml \
    && rm -rf /tmp/build

WORKDIR /workspace

CMD ["/bin/bash"]
