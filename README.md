# devops_internship_2023
  * Yulyan Glonti's playground

## configuring ssh

*to generate new ssh key run*
```
ssh-keygen -b 2048 -t rsa -f /path/to/your/key
```
*then you need to copy the key.pub to **/home/your_user/.ssh/authorized_keys** on your server in any way*

*to connect run*
```
ssh your_user@ip_address -i /path/to/your/key.pub
```

## executing scripts

*you need to copy both **1-initial-setup.sh** and **2-configure-nginx.sh** to the server*

*to copy scripts to the server run*
```
sudo scp -i ~/path/to/your/public/key your_scripts your_user@server_ip_address:/home/your_user/
```
*then execute the script running as user with sudo privileges*
```
sudo bash 1-initial-setup.sh 
```
*will be created **nginxuser** to run the second script*

*do not forget setup a password for **nginx** user running*
```
sudo passwd nginxuser
```
*then switch to **nginxuser** and execute the second script*
```
su - nginx
sudo ./2-configure-nginx.sh
```
*will be created two websites on **localhost:80** and **localhost8080***
