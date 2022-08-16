FROM ubuntu:18.04

RUN apt update -y
RUN apt install -y gawk wget git-core diffstat unzip texinfo gcc-multilib \
	build-essential	chrpath socat libsdl1.2-dev xterm
RUN apt install -y cpio python python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping vim
RUN apt install -y lsb-release locales sudo

RUN dpkg-reconfigure locales && locale-gen en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN apt update -y && apt install -y rsync curl
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo && \
chmod a+x /usr/bin/repo

# Support for devshell.
RUN apt install -y xterm tmux libncurses-dev

ARG homedir
ARG uid
ARG user
ARG gid
ARG group

ENV HOME=$homedir
RUN echo ${uid} ${user} ${gid} ${group}
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${gid} ${user}

WORKDIR /src
