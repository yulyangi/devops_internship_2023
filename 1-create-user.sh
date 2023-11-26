#!/usr/bin/env bash

# error handling
set -e

main_script_path="/tmp/2-nginx-setup.sh"

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # secure ssh
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    sed -i -e 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i -e 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e 's/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

    # update system, install perl
    if [[ "$(awk -F"=" '/^ID_LIKE=/ {printf $2}' /etc/os-release)" == \"debian\" ]]; then
        # Ubuntu or Debian
        apt-get update && apt-get install -y perl
        systemctl restart ssh
    elif [[ "$(awk -F"=" '/^ID_LIKE=/ {printf $2}' /etc/os-release)" == \"fedora\" ]]; then
        # CentOS or RHEL
        yum -y update && yum install -y perl
        systemctl restart sshd
    else
        echo "Unsupported Linux distribution" && exit 1
    fi

    # promt to input username and password
    read -p "Enter username (restricted user to install nginx): " username
    read -s -p "Enter password \
(ensure the password respects the system's password policy or you can set it manualy \
after executing the script 'sudo passwd ${username}') : " password

    # check exit status of last command
    if grep -e "^${username}" /etc/passwd >/dev/null; then
        printf "%s\n" "${username} exists!" && exit 1
    else
        # generate encrypted password
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        
        # add new user
        if useradd --create-home --shell /bin/bash -p "${pass}" "${username}"; then
            echo "User has been added to system!"
        else
            echo "Failed to add a user!" && exit 1
        fi
    fi
else
    echo "You need root privileges to run this script!" && exit 1
fi

# restrict permissions for the nginx script
chmod 544 "${main_script_path}"
chown "${username}:root" "${main_script_path}"

# configure suders to restrict run only this script
cat << EOF > /etc/sudoers.d/"${username}"
${username} ALL=(root) NOPASSWD:${main_script_path}
EOF
