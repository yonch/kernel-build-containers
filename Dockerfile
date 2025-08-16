ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION} AS base

# Install base system packages and tools
RUN set -ex; \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; \
    apt-get update; \
    apt-get install -y -q apt-utils dialog; \
    apt-get install -y -q sudo aptitude flex bison cpio libncurses5-dev make git exuberant-ctags sparse bc libssl-dev libelf-dev bsdmainutils dwarves xz-utils zstd gawk locales silversearcher-ag ccache curl unzip initramfs-tools openssh-server mosh tmux jq; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure locale
RUN set -ex; \
    locale-gen en_US.UTF-8; \
    update-locale LANG=en_US.UTF-8

# Install Python and npm
RUN set -ex; \
    apt-get update; \
    apt-get install -y -q python3 python3-venv; \
    apt-get install -y -q python-is-python3 || apt-get install -y -q python; \
    apt-get install -y -q npm; \
    npm install -g @anthropic-ai/claude-code; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install GCC toolchain
ARG GCC_VERSION
RUN set -ex; \
    if [ "$GCC_VERSION" ]; then \
      apt-get update; \
      apt-get install -y -q gcc-${GCC_VERSION} g++-${GCC_VERSION} gcc-${GCC_VERSION}-plugin-dev \
        gcc-${GCC_VERSION}-aarch64-linux-gnu g++-${GCC_VERSION}-aarch64-linux-gnu \
        gcc-${GCC_VERSION}-arm-linux-gnueabi g++-${GCC_VERSION}-arm-linux-gnueabi; \
      if [ "$GCC_VERSION" != "4.9" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-plugin-dev-aarch64-linux-gnu gcc-${GCC_VERSION}-plugin-dev-arm-linux-gnueabi; \
      fi; \
      if [ "$GCC_VERSION" != "4.9" ] && [ "$GCC_VERSION" != "5" ] && [ "$GCC_VERSION" != "6" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-riscv64-linux-gnu g++-${GCC_VERSION}-riscv64-linux-gnu gcc-${GCC_VERSION}-plugin-dev-riscv64-linux-gnu; \
      fi; \
      update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/aarch64-linux-gnu-g++ aarch64-linux-gnu-g++ /usr/bin/aarch64-linux-gnu-g++-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/arm-linux-gnueabi-gcc arm-linux-gnueabi-gcc /usr/bin/arm-linux-gnueabi-gcc-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/arm-linux-gnueabi-g++ arm-linux-gnueabi-g++ /usr/bin/arm-linux-gnueabi-g++-${GCC_VERSION} 100; \
      if [ "$GCC_VERSION" != "4.9" ] && [ "$GCC_VERSION" != "5" ] && [ "$GCC_VERSION" != "6" ]; then \
        update-alternatives --install /usr/bin/riscv64-linux-gnu-gcc riscv64-linux-gnu-gcc /usr/bin/riscv64-linux-gnu-gcc-${GCC_VERSION} 100; \
        update-alternatives --install /usr/bin/riscv64-linux-gnu-g++ riscv64-linux-gnu-g++ /usr/bin/riscv64-linux-gnu-g++-${GCC_VERSION} 100; \
      fi; \
      apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi

# Install Clang toolchain  
ARG CLANG_VERSION
RUN set -ex; \
    if [ "$CLANG_VERSION" ]; then \
      apt-get update; \
      if [ "$CLANG_VERSION" = "5" ] || [ "$CLANG_VERSION" = "6" ]; then \
        CLANG_VERSION="${CLANG_VERSION}.0"; \
        apt-get install -y -q clang-${CLANG_VERSION} lld-${CLANG_VERSION} clang-tools-6.0; \
      else \
        apt-get install -y -q clang-${CLANG_VERSION} lld-${CLANG_VERSION} clang-tools-${CLANG_VERSION}; \
      fi; \
      update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${CLANG_VERSION} 100; \
      apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi

RUN set -ex; \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    unzip awscliv2.zip; \
    ./aws/install; \
    rm -rf aws awscliv2.zip

RUN set -ex; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null; \
    apt-get update; \
    apt-get install -y -q gh; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ARG UNAME
ARG UID
ARG GNAME
ARG GID
RUN set -x; \
    # These commands are allowed to fail (it happens for root, for example).
    # The result will be checked in the next RUN.
    userdel -r `getent passwd ${UID} | cut -d : -f 1` > /dev/null 2>&1; \
    groupdel -f `getent group ${GID} | cut -d : -f 1` > /dev/null 2>&1; \
    groupadd -g ${GID} ${GNAME}; \
    useradd -u $UID -g $GID -G sudo -ms /bin/bash ${UNAME}; \
    mkdir /src; \
    chown -R ${UNAME}:${GNAME} /src; \
    mkdir /out; \
    chown -R ${UNAME}:${GNAME} /out; \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN set -ex; \
    mkdir -p /var/run/sshd; \
    mkdir -p /home/${UNAME}/.ssh; \
    chown ${UNAME}:${GNAME} /home/${UNAME}/.ssh; \
    chmod 700 /home/${UNAME}/.ssh

USER ${UNAME}:${GNAME}
WORKDIR /src

RUN set -ex; \
    ln -sf /workspace/.ccache /home/${UNAME}/.ccache; \
    ln -sf /workspace/.aws /home/${UNAME}/.aws; \
    ln -sf /workspace/.claude /home/${UNAME}/.claude; \
    mkdir -p /home/${UNAME}/.config; \
    ln -sf /workspace/.config/gh /home/${UNAME}/.config/gh

RUN set -ex; \
    id | grep "uid=${UID}(${UNAME}) gid=${GID}(${GNAME})"; \
    sudo ls; \
    pwd | grep "^/src"; \
    touch /src/test; \
    rm /src/test; \
    touch /out/test; \
    rm /out/test

COPY sshd_config /etc/ssh/sshd_config

EXPOSE 22

CMD ["/bin/bash", "-c", "sudo /usr/sbin/sshd && exec bash"]
