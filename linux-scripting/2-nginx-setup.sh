#!/usr/bin/env bash

# error handling
set -euxo pipefail

# shell vars
system_type=$(awk -F"=" '/^ID_LIKE=/ {printf $2}' /etc/os-release)
private_ip=$(ip route get 1 | awk 'NR==1 {print $7}')
hostname=$(hostname)
chroot_dir=/home/webadmins

if [[ "${system_type}" == "debian" ]]; then
    nginx_user="www-data"
    nginx_crt_path=/etc/ssl/certs/nginx.crt
    nginx_key_path=/etc/ssl/private/nginx.key
elif [[ "${system_type}" == \"fedora\" || "${system_type}" == "\"rhel fedora\"" ]]; then
    nginx_user="nginx"
    nginx_crt_path=/etc/pki/tls/certs/nginx.crt
    nginx_key_path=/etc/pki/tls/private/nginx.key
else
    echo "Unsupported Linux distribution" && exit 1
fi

# func to check if valid domain
function validate_domain() {
    local domain="${1}"
    local validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
    if [[ ! "${domain}" =~ ${validate} ]]; then
        printf "%s\n" "Not valid ${domain} name!" && exit 1
    fi
}

# func to create users to administrate web sites
function create_user() {
    read -p "Enter username : " username
    read -s -p "Enter password \
(ensure the password respects the system's password policy or you can set it manualy \
after executing the script 'sudo passwd ${username}') : " password
    if grep -e "^${username}" /etc/passwd >/dev/null; then
        printf "%s\n" "${username} exists!" && exit 1
    else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        if useradd --create-home --shell /usr/bin/bash -p "${pass}" "${username}"; then
            printf "%s\n" "${username}" 
        else
            echo "Failed to add a user!" && exit 1
        fi
    fi 
}

# functions to enable or disable loaded service
function enable_service() {
    local service="${1}"
    if [ "$(systemctl status "${service}" | awk 'FNR==2 {printf $2}')" == "loaded" ]; then
        systemctl start "${service}"
        systemctl enable "${service}"
    fi
}

function disable_service() {
    local service="${1}"
    if [ "$(systemctl status "${service}" | awk 'FNR==2 {printf $2}')" == "loaded" ]; then
        systemctl stop "${service}"
        systemctl disable "${service}"
    fi
}

# function to copy commands to chroot dir
function copy_commands(){
    commands=("$@")
    for command in "${commands[@]}"; do
        command_path="$(which "${command}")"
        command_dir="$(dirname "${command_path}")"

        # copy each command
        mkdir -p "${chroot_dir}${command_dir}"
        cp "${command_path}" "${chroot_dir}${command_dir}/"

        # grab and copy shared libraries of each command
        command_libs="$(ldd "${command_path}" | awk '/=> \// {print $3}')"
        for lib in ${command_libs}; do
            command_libs_dir="$(dirname "${lib}")"
            mkdir -p "${chroot_dir}${command_libs_dir}"
            cp "${lib}" "${chroot_dir}${command_libs_dir}/"
        done
    done
}

# func to create chroot 
function setup_chroot() {
    local username=$1
    local domain=$2
    
    # create directory for web admin
    mkdir -p "${chroot_dir}/home/${username}/${domain}"
    mkdir -p "${chroot_dir}/home/${username}/.ssh"
    touch "${chroot_dir}/home/${username}/.ssh/authorized_keys"

    chown -R "${username}":"${username}" "${chroot_dir}/home/${username}/"
    chmod -R 700 "${chroot_dir}/home/${username}/"
    chmod 600 "${chroot_dir}/home/${username}/.ssh/authorized_keys"

    # configure sshd
    cat << EOF >> /etc/ssh/sshd_config
Match user ${username}
ChrootDirectory ${chroot_dir}
PasswordAuthentication yes
AuthorizedKeysFile ${chroot_dir}/home/${username}/.ssh/authorized_keys
EOF
}

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # enter domain names and create users
    read -p "Enter first domain : " first_domain
    validate_domain "${first_domain}"
    printf "%s\n" "Create user for administrating ${first_domain}"
    username_first="$(create_user)"

    read -p "Enter second domain : " second_domain
    validate_domain "${second_domain}"
    printf "%s\n" "Create user for administrating ${second_domain}"
    username_second="$(create_user)"
    
    ## create chroot
    # create required directories
    mkdir -p {${chroot_dir}/dev,${chroot_dir}/bin,${chroot_dir}/lib,${chroot_dir}/lib64,${chroot_dir}/etc,${chroot_dir}/usr/bin,${chroot_dir}/home}
    chown -R root:root "${chroot_dir}"
    chmod -R 0755 "${chroot_dir}"
    
    # create special files
    mknod -m 666 "${chroot_dir}/dev/null" c 1 3
    mknod -m 666 "${chroot_dir}/dev/tty" c 5 0
    mknod -m 666 "${chroot_dir}/dev/zero" c 1 5
    mknod -m 666 "${chroot_dir}/dev/random" c 1 8

    # copy required commands
    copy_commands bash sh ls mkdir cat echo touch printf rm cp mv grep
    # copy additional files
    cp /lib64/ld-linux-x86-64.so.2 "${chroot_dir}/lib64/"
    # copy all commands from /bin to /usr/bin to avoid possible issues
    /bin/cp -rf "${chroot_dir}/bin/." "${chroot_dir}/usr/bin/"

    # set up one chroot directoy for both web admins
    setup_chroot "${username_first}" "${first_domain}"
    setup_chroot "${username_second}" "${second_domain}"

    # remove existed home directories
    rm -fr /home/"${username_first:?}"
    rm -fr /home/"${username_second:?}"
else
    echo "You need root privileges to run this script!" && exit 1
fi

# assign config files to vars
first_config=$(
cat <<EOF
server {
    listen 80;
    server_name ${first_domain};
    return 301 https://${first_domain}\$request_uri;
}
server {
    listen 443 ssl;
    ssl_certificate     ${nginx_crt_path};
    ssl_certificate_key ${nginx_key_path};
    server_name ${first_domain}; 
    root /var/www/html/${first_domain};
    index index.html;
    access_log /var/log/nginx/${first_domain}.local.access.log;
    error_log /var/log/nginx/${first_domain}.local.error.log error;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
)
second_config=$(
cat <<EOF
server {
    listen 80;
    server_name ${second_domain};
    return 301 https://${second_domain}\$request_uri;
}
server {
    listen 443 ssl;
    ssl_certificate     ${nginx_crt_path};
    ssl_certificate_key ${nginx_key_path};
    server_name ${second_domain};
    root /var/www/html/${second_domain};
    index index.html;
    access_log /var/log/nginx/${second_domain}.local.access.log;
    error_log /var/log/nginx/${second_domain}.local.error.log error;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
)

## configure nginx
# create directories for the domains
mkdir -p "/var/www/html/${first_domain}"
mkdir -p "/var/www/html/${second_domain}"

# main condition
if [[ "${system_type}" == "debian" ]]; then
    # Ubuntu or Debian
    # update system, install required packages
    # to configure log rotation change /etc/logrotate.d/nginx file
    # logrotation will use default configuration for all *.log files
    apt-get update && apt-get install -y nginx logrotate openssl curl
    enable_service nginx
    disable_service ufw
    systemctl restart ssh

    # create a website contenst for the second domain the same as default nginx web page
    cp /var/www/html/index.nginx*.html "/var/www/html/${second_domain}/index.html"

    # create config files
    printf "%s\n" "${first_config}" | sudo tee /etc/nginx/sites-available/"${first_domain}".conf > /dev/null
    printf "%s\n" "${second_config}" | sudo tee /etc/nginx/sites-available/"${second_domain}".conf > /dev/null
    
    # enable virtual hosts
    unlink /etc/nginx/sites-enabled/default # disable default index.html page
    ln -s "/etc/nginx/sites-available/${first_domain}.conf" /etc/nginx/sites-enabled/
    ln -s "/etc/nginx/sites-available/${second_domain}.conf" /etc/nginx/sites-enabled/

elif [[ "${system_type}" == \"fedora\" || "${system_type}" == "\"rhel fedora\"" ]]; then
    # CentOS or RHEL
    # update system, install required packages
    # to configure log rotation change /etc/logrotate.d/nginx file
    # logrotation will use default configuration for all *.log files
    yum -y update && yum install -y nginx logrotate openssl curl iptables-services
    enable_service nginx
    disable_service firewalld
    systemctl restart sshd
    
    # create a website contenst for the second domain the same as default nginx web page
    cp /usr/share/nginx/html/index.html "/var/www/html/${second_domain}/index.html"

    # create config files
    printf "%s\n" "${first_config}" | sudo tee /etc/nginx/conf.d/"${first_domain}".conf > /dev/null
    printf "%s\n" "${second_config}" | sudo tee /etc/nginx/conf.d/"${second_domain}".conf > /dev/null

    # configure SELinux
    if [[ $(getenforce) != "disabled" ]]; then
        # allow web server access to these directories, change type "var_t"->"httpd_sys_content_t"
        chcon -R -t httpd_sys_content_t /var/www/html/*
        # or disable SELinux
        # setenforce 0
        # sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    fi
fi

# create a simple website content
public_ip=$(curl ident.me)
cat << EOF > /var/www/html/"${first_domain}"/index.html
<html>
<title>${first_domain}</title>
<h1>Public IP address: ${public_ip}</h1>
<h1>Private IP address: ${private_ip}</h1>
<h1>Hostname: ${hostname}</h1>
</html>
EOF

# create ssl certs, we will use them for both websites
openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${nginx_key_path}" -out "${nginx_crt_path}"

# change ownership of both websites recursevely
chown -R "${username_first}:${nginx_user}" "/var/www/html/${first_domain}"
chown -R "${username_second}:${nginx_user}" "/var/www/html/${second_domain}"

# restrict permissions for these files and directories
find "/var/www/html/${first_domain}" -type f -exec chmod 644 {} \;
find "/var/www/html/${first_domain}" -type d -exec chmod 755 {} \;
find "/var/www/html/${second_domain}" -type f -exec chmod 644 {} \;
find "/var/www/html/${second_domain}" -type d -exec chmod 755 {} \;

# reload configuration
systemctl reload nginx

# configure iptables
iptables -F # first remove all rules
iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 22,80,443 -m state --state ESTABLISHED -j ACCEPT
# allow all loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables --policy INPUT DROP
iptables --policy OUTPUT DROP 

# copy files with last changes to chroot directory
cp /etc/{passwd,group,hosts,shadow} "${chroot_dir}/etc/"
# mount web site directory to chroot 
mount --bind "/var/www/html/${first_domain}" "${chroot_dir}/home/${username_first}/${first_domain}"
mount --bind "/var/www/html/${second_domain}" "${chroot_dir}/home/${username_second}/${second_domain}"
# mount web site directory to chroot permanently
printf "%s\n" "/var/www/html/${first_domain} ${chroot_dir}/home/${username_first}/${first_domain} none bind" | sudo tee -a /etc/fstab > /dev/null
printf "%s\n" "/var/www/html/${second_domain} ${chroot_dir}/home/${username_second}/${second_domain} none bind" | sudo tee -a /etc/fstab > /dev/null

# not necessary block
# update /etc/hosts to check domain using curl
# if you use virtual machines write <private_ip> <domain_name> to /etc/hosts file
printf "%s\n" "${public_ip} ${first_domain}" | sudo tee -a /etc/hosts > /dev/null
printf "%s\n" "${public_ip} ${second_domain}" | sudo tee -a /etc/hosts > /dev/null
printf "%s\n" "${private_ip} ${hostname}" | sudo tee -a /etc/hosts > /dev/null
# we want to make curl -k https://our-domain.com
iptables -A INPUT -s "${public_ip}" -j ACCEPT
iptables -A OUTPUT -d "${public_ip}" -j ACCEPT
