#!/usr/bin/env bash

# error handling
set -e 

# func if valid domain
function validate_domain() {
    local domain="${1}"
    local validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
    if [[ ! "${domain}" =~ ${validate} ]]; then
        echo "Not valid ${domain} name!"
        exit 1
    fi
}

# func to create users to administrate web sites
function create_user() {
    read -p "Enter username : " username
    read -s -p "Enter password : " password
    echo -e "\n"
    if grep -e "^${username}" /etc/passwd >/dev/null; then
        echo "${username} exists!"
        exit 1
    else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        if useradd --create-home --shell /bin/bash -p "${pass}" "${username}"; then
            echo "${username}" 
        else
            echo "Failed to add a user!" && exit 2
        fi
    fi 
}

# functions to enable or disable loaded service
function enable_service() {
    local service="${1}"
    if [ -e "$(which /lib/systemd/system/"${service}".service)" ]; then
        systemctl start "${service}"
        systemctl enable "${service}"
    fi
}

function disable_service() {
    local service="${1}"
    if [ -e "$(which /lib/systemd/system/"${service}".service)" ]; then
        systemctl stop "${service}"
        systemctl disable "${service}"
    fi
}

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # enter domain names and create users
    read -p "Enter first domain : " first_domain
    validate_domain "${first_domain}"
    echo "Create user for administrating ${first_domain}"
    username_first="$(create_user)"
    read -p "Enter second domain : " second_domain
    validate_domain "${second_domain}"
    echo "Create user for administrating ${second_domain}"
    username_second="$(create_user)"
fi

# assign some shell variables
private_ip=$(bash -c "ip route get 1 | awk 'NR==1{print \$7}'")
public_ip=$(bash -c "curl ident.me")
hostname=$(bash -c "hostname")

# update system, install nginx, logrotate, disable default firewall
if [[ -e "$(which apt-get)" ]]; then
    # Ubuntu or Debian
    apt-get update && apt-get install -y logrotate nginx openssl curl
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

## configure nginx
# create directories for the domains
mkdir "/var/www/html/${first_domain}"
mkdir "/var/www/html/${second_domain}"

# create ssl certs
# we will use them for both websites
openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt

# create config files for websites
# to configure log rotation change /etc/logrotate.d/nginx file
# now logrotation uses default configuration for all *.log files
cat << EOF > /etc/nginx/sites-available/"${first_domain}".conf
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

cat << EOF > /etc/nginx/sites-available/"${second_domain}".conf
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

# create a simple website content
cat << EOF > /var/www/html/"${first_domain}"/index.html
<html>
<title>${first_domain}</title>
<h1>Public IP address: ${public_ip}</h1>
<h1>Private IP address: ${private_ip}</h1>
<h1>Hostname: ${hostname}</h1>
</html>
EOF

# create a website contenst for the second domain the same as default nginx web page
# just copy default index.html file
cp /var/www/html/index.nginx*.html "/var/www/html/${second_domain}/index.html"

# change ownership of both websites recursevely
chown -R "${username_first}":www-data "/var/www/html/${first_domain}"
chown -R "${username_second}":www-data "/var/www/html/${second_domain}"

# restrict permissions for these files and directories directories
find "/var/www/html/${first_domain}" -type f -exec chmod 644 {} \;
find "/var/www/html/${first_domain}" -type d -exec chmod 755 {} \;
find "/var/www/html/${second_domain}" -type f -exec chmod 644 {} \;
find "/var/www/html/${second_domain}" -type d -exec chmod 755 {} \;

# enable virtual hosts
unlink /etc/nginx/sites-enabled/default # disable default index.html page
ln -s "/etc/nginx/sites-available/${first_domain}.conf" /etc/nginx/sites-enabled/
ln -s "/etc/nginx/sites-available/${second_domain}.conf" /etc/nginx/sites-enabled/

# reload configuration
systemctl reload nginx

# update /etc/hosts to check domain using curl
printf "%s\n" "${public_ip} ${first_domain}" | sudo tee -a /etc/hosts > /dev/null
printf "%s\n" "${public_ip} ${second_domain}" | sudo tee -a /etc/hosts > /dev/null

## configure iptables
iptables -F # first remove all rules
iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 22,80,443 -m state --state ESTABLISHED -j ACCEPT
iptables --policy INPUT DROP
iptables --policy OUTPUT DROP 

## it is not nesessary, it is configured beause we want to make curl -k https://our-domain.com
iptables -A INPUT -s "${first_domain},${second_domain}" -j ACCEPT
iptables -A OUTPUT -d "${first_domain},${second_domain}" -j ACCEPT
