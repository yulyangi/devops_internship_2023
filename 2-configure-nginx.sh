#!/usr/bin/env bash

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

# create shell vars
admin_1="first-admin"  # user to administate website "my-first-website.com"
admin_2="second-admin" # user to administate website "my-second-website.com"
private_ip=$(bash -c "ip route get 1 | awk 'NR==1{print \$7}'")
public_ip=$(bash -c "curl ident.me") # we need to make this request before configuring firewall
hostname=$(bash -c "hostname")

# configure iptables
iptables -F # first remove all rules
iptables -A INPUT -p tcp -m multiport --dports 22,80,8080,443 -j ACCEPT # allow only ssh, http(s)
iptables --policy INPUT DROP # block all inbound traffic exept ssh, https(s)

# generate users with permissions only to their website directories
useradd --create-home --gid www-data --shell /bin/bash ${admin_1}
useradd --create-home --gid www-data --shell /bin/bash ${admin_2}

# configuring nginx
# create directories for the domains
mkdir /var/www/html/my-first-website.com
mkdir /var/www/html/my-second-website.com
 
# create config file of "my-first-website.com"
# to configure log rotation change /etc/logrotate.d/nginx file
# now logrotation uses default configuration for all *.log files
cat << EOF > /etc/nginx/sites-available/my-first-website.com.conf
# server {
#     listen 80;
#     server_name localhost;
#     return 301 https://localhost\$request_uri;
# }
server {
    listen 80;
    # listen 443 ssl;
    # ssl_certificate     /etc/ssl/private/localhost.key;
    # ssl_certificate_key /etc/ssl/certs/localhost.crt;
    server_name localhost; 
    root /var/www/html/my-first-website.com;
    index index.html;
    access_log /var/log/nginx/my-first-website.com.local.access.log;
    error_log /var/log/nginx/my-first-website.com.local.error.log error;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# create config file of "my-second-website.com"
cat << EOF > /etc/nginx/sites-available/my-second-website.com.conf
# server {
#     listen 8080;
#     server_name localhost;
#     return 301 https://localhost:44343\$request_uri;
# }
server {
    listen 8080;
    # listen 44343 ssl;
    # ssl_certificate     /etc/ssl/private/localhost.key;
    # ssl_certificate_key /etc/ssl/certs/localhost.crt;
    server_name localhost;
    root /var/www/html/my-second-website.com;
    index index.html;
    access_log /var/log/nginx/my-second-website.com.local.access.log;
    error_log /var/log/nginx/my-second-website.local.error.log error;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# create a simple website content for my-first-website.com
cat << EOF > /var/www/html/my-first-website.com/index.html
<html>
<title>my-first-website.com</title>
<h1>Public IP address: ${public_ip}</h1>
<h1>Private IP address: ${private_ip}</h1>
<h1>Hostname: ${hostname}</h1>
</html>
EOF

# create a website contenst for my-first-website.com the same as default nginx web page
# just copy default index.html file
cp /var/www/html/index.nginx*.html /var/www/html/my-second-website.com/index.html

# change ownership of both websites recursevely
chown -R "${admin_1}":www-data /var/www/html/my-first-website.com
chown -R "${admin_2}":www-data /var/www/html/my-second-website.com

# restrict permissions for these files and directories directories
find /var/www/html/my-first-website.com -type f -exec chmod 644 {} \;
find /var/www/html/my-first-website.com -type d -exec chmod 755 {} \;
find /var/www/html/my-second-website.com -type f -exec chmod 644 {} \;
find /var/www/html/my-second-website.com -type d -exec chmod 755 {} \;

# enable virtual hosts
unlink /etc/nginx/sites-enabled/default # disable default index.html page
ln -s /etc/nginx/sites-available/my-first-website.com.conf /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/my-second-website.com.conf /etc/nginx/sites-enabled/

# reload configuration
systemctl reload nginx
