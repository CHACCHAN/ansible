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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY requirements.yml .
RUN ansible-galaxy collection install -r requirements.yml \
    && rm -rf /tmp/build
 
WORKDIR /workspace

CMD ["/bin/bash"]