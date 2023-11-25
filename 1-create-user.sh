#!/usr/bin/env bash

# error handling
set -e

main_script_path="/tmp/2-nginx-setup.sh"

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # promt to input username and password
    read -p "Enter username (restricted user to install nginx): " username
    read -s -p "Enter password : " password

    # check exit status of last command
    if grep -e "^${username}" /etc/passwd >/dev/null; then
        echo "${username} exists!"
        exit 1
    else
        # generate encrypted password
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        
        # add new user
        if useradd --create-home --shell /bin/bash -p "${pass}" "${username}"; then
            echo -e "\nUser has been added to system!"
        else
            echo "Failed to add a user!"
        fi
    fi
else
    echo "You need root privileges to run this script!"
    exit 1
fi

# secure ssh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sed -i -e 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -e 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e 's/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

if [[ -e "$(which apt-get)" ]]; then
    systemctl restart ssh
elif [[ -e "$(which yum)" ]]; then
    systemctl restart sshd
else
    echo "Unsupported Linux distribution"
    exit 1
fi

# restrict permissions for the nginx script
chmod 744 "${main_script_path}"
chown "${username}":root "${main_script_path}"

# configure suders to restrict run only this script
cat << EOF > /etc/sudoers.d/"${username}"
${username} ALL=(root) NOPASSWD:${main_script_path}
EOF
