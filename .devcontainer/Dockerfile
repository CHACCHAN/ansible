FROM python:3.13-alpine3.24

# Runtime tools needed for Ansible operations
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssh-client \
    rsync \
    sshpass

# Build dependencies are grouped as a virtual package (.build-deps) so they
# can be removed in the same layer after pip install completes.
# cryptography and paramiko (Ansible deps) require C compilation on Alpine/musl.
RUN apk add --no-cache --virtual .build-deps \
        gcc \
        musl-dev \
        libffi-dev \
        openssl-dev \
    && pip install --no-cache-dir \
        ansible \
        ansible-lint \
    && apk del .build-deps

WORKDIR /workspace

CMD ["/bin/bash"]
