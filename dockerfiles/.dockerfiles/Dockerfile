FROM ubuntu:latest

ARG USER=atsign
ARG HOMEDIR=/atsign

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y vim git curl wget openssh-client openssh-server sudo && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash --home ${HOMEDIR} ${USER} && \
    usermod -aG sudo ${USER} && \
    mkdir -p ${HOMEDIR}/.ssh ${HOMEDIR}/.atsign/keys && \
    touch ${HOMEDIR}/.ssh/authorized_keys && \
    ssh-keygen -t ed25519 -a 100 -f ${HOMEDIR}/.ssh/id_ed25519 -q -N '' && \
    cat ${HOMEDIR}/.ssh/id_ed25519.pub >> ${HOMEDIR}/.ssh/authorized_keys && \
    chmod 700 ${HOMEDIR}/.ssh && \
    chmod 644 ${HOMEDIR}/.ssh/authorized_keys && \
    chmod 600 ${HOMEDIR}/.ssh/id_ed25519 && \
    chmod 644 ${HOMEDIR}/.ssh/id_ed25519.pub && \
    chown -R ${USER}:${USER} ${HOMEDIR} && \
    sed -i '$ a %sudo ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers && \
    sed -E -i 's|^#?(PasswordAuthentication)\s.*|\1 no|' /etc/ssh/sshd_config

ENV USER=${USER}

USER ${USER}
WORKDIR ${HOMEDIR}
