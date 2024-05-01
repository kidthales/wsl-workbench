FROM debian:stable-slim

ARG user=non-root
ARG wsl_name=workbench
ARG wsl_automount=/mnt

ARG nvm_version=0.39.7
ARG nodejs_version=20
ARG php_version=8.3

WORKDIR /tmp

# Create wsl.conf
RUN cat > /etc/wsl.conf <<-EOF
[automount]
root = "${wsl_automount}"
options = "metadata"

[user]
default = "${user}"
EOF

# Update packages & setup a user account with bash & sudo.
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bash \
    sudo \
    && \
    useradd -m -s /bin/bash "${user}" && \
    echo "${user}" ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/"${user}" && \
    chmod 0440 /etc/sudoers.d/"${user}" && \
    # Append to .bashrc
    cat >> /home/"${user}"/.bashrc <<-EOF

# https://github.com/microsoft/WSL/issues/5065
fix_wsl2_interop() {
    for i in $(pstree -np -s $$ | grep -o -E '[0-9]+'); do
        if [[ -e "/run/WSL/${i}_interop" ]]; then
            export WSL_INTEROP=/run/WSL/${i}_interop
        fi
    done
}

fix_wsl2_interop

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='\\[\\033[32m\\]'             # change to green
PS1="\$PS1"'\\u@\\h:${wsl_name} ' # user@host:wsl<space>
PS1="\$PS1"'\\[\\033[35m\\]'      # change to purple
PS1="\$PS1"'\\s-\\v '             # shell-version<space>
PS1="\$PS1"'\\[\\033[33m\\]'      # change to brownish yellow
PS1="\$PS1"'\\w '                 # cwd<space>
PS1="\$PS1"'\\[\\033[36m\\]'      # change to cyan
PS1="\$PS1\\\$(parse_git_branch)" # current git branch
PS1="\$PS1"'\\[\\033[0m\\]'       # change color
PS1="\$PS1"'\\n'                  # new line
PS1="\$PS1"'\\$ '                 # prompt<space>
EOF

SHELL ["/bin/bash", "-c"]

# Install core packages & setup user keychain.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    gcc \
    git \
    keychain \
    make \
    pkg-config \
    psmisc \
    wget \
    && \
    # Append to .profile
    echo $'\n# start ssh-agent if not running\neval $(keychain --eval --agents ssh id_rsa)' >> /home/"${user}"/.profile

# Setup nvm & NodeJS.
RUN su "${user}" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v'"${nvm_version}"'/install.sh | bash' && \
    su "${user}" -c 'source ~/.nvm/nvm.sh && nvm install "${nodejs_version}" && corepack enable && yarn set version stable'

# Setup PHP, composer, & symfony cli. Derived from https://php.watch/articles/php-8.3-install-upgrade-on-debian-ubuntu
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    lsb-release \
    && \
    curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg && \
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && \
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    php${php_version} \
    php${php_version}-cli \
    php${php_version}-{bz2,curl,dom,intl,mbstring,simplexml,xml} \
    symfony-cli \
    && \
    # Append to .profile
    echo $'\n# composer\nexport COMPOSER_HOME="${HOME}/.composer"' >> /home/"${user}"/.profile
