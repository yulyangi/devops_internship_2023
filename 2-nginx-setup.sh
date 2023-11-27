#!/usr/bin/env bash

# error handling
set -euxo pipefail

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
        if useradd --create-home --shell /bin/bash -p "${pass}" "${username}"; then
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
else
    echo "You need root privileges to run this script!" && exit 1
fi

# shell vars
nginx_user_debian="www-data"
nginx_user_fedora="nginx"
private_ip=$(ip route get 1 | awk 'NR==1 {print $7}')
hostname=$(hostname)
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
    ssl_certificate     /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
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
    ssl_certificate     /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
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
if [[ "$(awk -F"=" '/^ID_LIKE=/ {printf $2}' /etc/os-release)" == "debian" ]]; then
    # Ubuntu or Debian
    # update system, install required packages
    # to configure log rotation change /etc/logrotate.d/nginx file
    # logrotation will use default configuration for all *.log files
    apt-get update && apt-get install -y nginx logrotate openssl curl
    enable_service nginx
    disable_service ufw

    # create a website contenst for the second domain the same as default nginx web page
    cp /var/www/html/index.nginx*.html "/var/www/html/${second_domain}/index.html"

    # create config files
    printf "%s\n" "${first_config}" | sudo tee /etc/nginx/sites-available/"${first_domain}".conf > /dev/null
    printf "%s\n" "${second_config}" | sudo tee /etc/nginx/sites-available/"${second_domain}".conf > /dev/null
    
    # enable virtual hosts
    unlink /etc/nginx/sites-enabled/default # disable default index.html page
    ln -s "/etc/nginx/sites-available/${first_domain}.conf" /etc/nginx/sites-enabled/
    ln -s "/etc/nginx/sites-available/${second_domain}.conf" /etc/nginx/sites-enabled/

    # change ownership of both websites recursevely
    chown -R "${username_first}:${nginx_user_debian}" "/var/www/html/${first_domain}"
    chown -R "${username_second}:${nginx_user_debian}" "/var/www/html/${second_domain}"

elif [[ "$(awk -F"=" '/^ID_LIKE=/ {printf $2}' /etc/os-release)" == \"fedora\" ]]; then
    # CentOS or RHEL
    # update system, install required packages
    # to configure log rotation change /etc/logrotate.d/nginx file
    # logrotation will use default configuration for all *.log files
    yum -y update && yum install -y nginx logrotate openssl curl iptables-services
    enable_service nginx
    disable_service firewalld
    
    # create a website contenst for the second domain the same as default nginx web page
    cp /usr/share/nginx/html/index.html "/var/www/html/${second_domain}/index.html"

    # create config files
    printf "%s\n" "${first_config}" | sudo tee /etc/nginx/conf.d/"${first_domain}".conf > /dev/null
    printf "%s\n" "${second_config}" | sudo tee /etc/nginx/conf.d/"${second_domain}".conf > /dev/null

    # change ownership of both websites recursevely
    chown -R "${username_first}:${nginx_user_fedora}" "/var/www/html/${first_domain}"
    chown -R "${username_second}:${nginx_user_fedora}" "/var/www/html/${second_domain}"

    # disable SELinux
    ausearch -c 'nginx' --raw | audit2allow -M nginx-policy
    semodule -i nginx-policy.pp
    # or you can temporary disable SELinux running "setenforce 0"
else
    echo "Unsupported Linux distribution" && exit 1
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
mkdir -p /etc/ssl/private
openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt

# restrict permissions for these files and directories directories
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
iptables --policy INPUT DROP
iptables --policy OUTPUT DROP 

# not nessessary block
# update /etc/hosts to check domain using curl
printf "%s\n" "${public_ip} ${first_domain}" | sudo tee -a /etc/hosts > /dev/null
printf "%s\n" "${public_ip} ${second_domain}" | sudo tee -a /etc/hosts > /dev/null
# we want to make curl -k https://our-domain.com
iptables -A INPUT -s "${first_domain},${second_domain}" -j ACCEPT
iptables -A OUTPUT -d "${first_domain},${second_domain}" -j ACCEPT
