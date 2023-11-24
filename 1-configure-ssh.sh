#!/usr/bin/env bash

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # configure sshd
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    sed -i -e 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i -e 's/^#*PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e 's/^#*PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
else
    echo "You need root privileges to run this script!"
    exit 1
fi
