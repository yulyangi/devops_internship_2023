#!/usr/bin/env bash

# to generate new ssh key run
# ssh-keygen -b 2048 -t rsa -f /path/to/your/key
# then you need to copy the key.pub to /home/your_user/.ssh/authorized_keys on your server
# to connect run 'ssh your_user@ip_address -i /path/to/your/key.pub'
# copy scripts to the server running
# sudo scp -i ~/path/to/your/public/key 1-initial-setup.sh user@server_ip_address:/home/user/

# error handling
set -o xtrace    # trace the execution of the script
set -o errexit   # exit on most errors
set -o nounset   # exit when an undefined variable is referenced
set -o pipefail  # use last non-zero exit code in a pipeline

# check if you are run this scrit as root
if [[ "${UID}" -ne 0 ]]; then
    printf '%s\n' "You need root privileges to run this script!"
	exit 1
fi

# setup shell variables
user="nginxuser"
script_path_nginx="2-configure-nginx.sh"
readonly user script_path_nginx

# secure sshd
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sed -i -e 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -e 's/^#*PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e 's/^#*PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# functions to enable or disable loaded service
function enable_service() {
    local service="${1}"
    if [ -e $(which "/lib/systemd/system/${service}.service") ]; then
        systemctl start "${service}"
        systemctl enable "${service}"
    fi
}

function disable_service() {
    local service="${1}"
    if [ -e $(which "/lib/systemd/system/${service}.service") ]; then
        systemctl stop "${service}"
        systemctl disable "${service}"
    fi
}

# update system, install nginx, disable default firewall
if [[ -e "$(which apt-get)" ]]; then
    # Ubuntu or Debian
    apt-get update && apt-get install -y logrotate nginx
    enable_service nginx
    disable_service ufw
elif [[ -e "$(which yum)" ]]; then
    # CentOS or RHEL
    yum -y update && yum install -y epel-release logrotate nginx iptables-services
    enable_service nginx
    disable_service firewalld
else
    echo "Unsupported Linux distribution"
    exit 1
fi

# generate an user to run the nginx script
useradd --create-home --gid sudo --shell /bin/bash "${user}"

# restrict permissions for the nginx script
chmod 744 "${script_path_nginx}"
chown "${user}":root "${script_path_nginx}"
mv "${script_path_nginx}" /home/${user}/
