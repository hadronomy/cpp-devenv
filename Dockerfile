FROM ubuntu:20.04 as base

SHELL [ "/bin/bash", "-o", "pipefail", "-c", "-l" ]

RUN apt update -y
RUN apt upgrade -y
RUN apt install -y python pip
RUN apt install -y --no-install-recommends \
  libprotobuf-dev \ 
  protobuf-compiler \
  g++ \
  build-essential \
  gdb
RUN apt install -y --no-install-recommends zsh \
  zsh \
  git \
  curl \
  wget \
  ca-certificates=* \
  socat \
  openssh-server \
  supervisor \
  rpl \
  pwgen \
  less \
  sudo

# Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh
# Set vscode as default editor for GitHub CLI
RUN gh config set editor "code --wait"

# SSH Config
# RUN mkdir /var/run/sshd
# ADD config/sshd.conf /etc/supervisor/conf.d/sshd.conf

# Ubuntu 14.04 by default only allows non pwd based root login
# We disable that but also create an .ssh dir so you can copy
# up your key.
# RUN rpl "PermitRootLogin without-password" "PermitRootLogin yes" /etc/ssh/sshd_config
# RUN mkdir /root/.ssh
# RUN chmod o-rwx /root/.ssh
# RUN ssh-keyscan github.com > /root/.ssh/known_hosts

EXPOSE 22

ADD scripts/setup.sh /setup.sh
RUN chmod 0755 /setup.sh
RUN /setup.sh

ADD scripts/start.sh /start.sh
RUN chmod 0755 /start.sh

# Install cmake
ARG CMAKE_VERSION=3.21.4

RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /usr/bin/cmake \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/bin/cmake \
      && rm /tmp/cmake-install.sh

ENV PATH="/usr/bin/cmake/bin:${PATH}"

# Install fzf
RUN \
  FZF_VERSION="0.21.1" \
  && FZF_DOWNLOAD_SHA256="7d4e796bd46bcdea69e79a8f571be1da65ae9d9cc984b50bc4af5c0b5754fbd5" \
  && wget -nv -O fzf.tgz https://github.com/junegunn/fzf-bin/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tgz \
  && echo "$FZF_DOWNLOAD_SHA256 fzf.tgz" | sha256sum -c - \
  && tar zxvf fzf.tgz --directory /usr/local/bin \
  && rm fzf.tgz

# Install Fira Code from Nerd fonts
RUN \
  NERDS_FONT_VERSION="2.1.0" \
  && FONT_DIR=/usr/local/share/fonts \
  && FIRA_CODE_URL=https://github.com/ryanoasis/nerd-fonts/raw/${NERDS_FONT_VERSION}/patched-fonts/FiraCode \
  && FIRA_CODE_LIGHT_DOWNLOAD_SHA256="5e0e3b18b99fc50361a93d7eb1bfe7ed7618769f4db279be0ef1f00c5b9607d6" \
  && FIRA_CODE_REGULAR_DOWNLOAD_SHA256="3771e47c48eb273c60337955f9b33d95bd874d60d52a1ba3dbed924f692403b3" \
  && FIRA_CODE_MEDIUM_DOWNLOAD_SHA256="42dc83c9173550804a8ba2346b13ee1baa72ab09a14826d1418d519d58cd6768" \
  && FIRA_CODE_BOLD_DOWNLOAD_SHA256="060d4572525972b6959899931b8685b89984f3b94f74c2c8c6c18dba5c98c2fe" \
  && FIRA_CODE_RETINA_DOWNLOAD_SHA256="e254b08798d59ac7d02000a3fda0eac1facad093685e705ac8dd4bd0f4961b0b" \
  && mkdir -p $FONT_DIR \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Light/complete/Fura%20Code%20Light%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Regular/complete/Fura%20Code%20Regular%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Medium/complete/Fura%20Code%20Medium%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Bold/complete/Fura%20Code%20Bold%20Nerd%20Font%20Complete.ttf \
  && wget -nv -P $FONT_DIR $FIRA_CODE_URL/Retina/complete/Fura%20Code%20Retina%20Nerd%20Font%20Complete.ttf \
  && echo "$FIRA_CODE_LIGHT_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Light Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_REGULAR_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Regular Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_MEDIUM_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Medium Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_BOLD_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Bold Nerd Font Complete.ttf" | sha256sum -c - \
  && echo "$FIRA_CODE_RETINA_DOWNLOAD_SHA256 $FONT_DIR/Fura Code Retina Nerd Font Complete.ttf" | sha256sum -c -

ENV APP_USER=user
ENV APP_USER_GROUP=user
ARG APP_USER_HOME=/home/$APP_USER

# Add non-root user
RUN addgroup user
RUN \
  adduser --quiet --disabled-password \
  --shell /bin/zsh \
  --gecos "User" $APP_USER \
  --ingroup $APP_USER_GROUP

# RUN mkdir -p ${APP_USER_HOME}/.ssh
# RUN chown -R user:user ${APP_USER_HOME}/.ssh

RUN adduser ${APP_USER} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $APP_USER
WORKDIR $APP_USER_HOME

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ARG ZSH_CUSTOM=$APP_USER_HOME/.oh-my-zsh/custom

# Install oh-my-zsh and powerlevel10k
RUN \
  ZSH_PLUGINS=$ZSH_CUSTOM/plugins \
  && ZSH_THEMES=$ZSH_CUSTOM/themes \
  && git clone --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git $ZSH_THEMES/powerlevel10k

# Install gitstatus
RUN \
  GITSTATUS_VERSION="1.0.0" \
  && GITSTATUS_SHA256="e33867063f091d3c31ede9916fef079ff8cd6fdcc70d051914f962ab3b8f36fd" \
  && wget -nv -O gitstatus.tgz https://github.com/romkatv/gitstatus/releases/download/v${GITSTATUS_VERSION}/gitstatusd-linux-x86_64.tar.gz \
  && echo "$GITSTATUS_SHA256 gitstatus.tgz" | sha256sum -c - \
  && mkdir -p ./.cache/gitstatus \
  && tar zxvf gitstatus.tgz --directory ./.cache/gitstatus \
  && rm gitstatus.tgz

# Install plugins
RUN \
  git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
  && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Copy config files
COPY --chown=$APP_USER:$APP_USER_GROUP ./config/.zshrc ./config/.p10k.zsh $APP_USER_HOME/

RUN mkdir ~/project

WORKDIR $APP_USER_HOME/project

ADD scripts/first_start.sh /etc/start.sh
ENV SHELL /bin/zsh

CMD [ "zsh" ]