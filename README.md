# devops_internship_2023
  * Yulyan Glonti's playground

## grab it

```
git clone https://github.com/yulyangi/devops_internship_2023.git
```

## run it

*move to the **devops_internship_2023** directory*

*you need a user on remote server with enabling password authentication*

*then execute the script running as user without! sudo privileges*

*ssh connection will be configured*
```
bash 0-configure-ssh.sh
```
*copy **1-create-user.sh** and **2-nginx-setup.sh** to the remote server to /tmp directory*
```
scp -i ~/.ssh/your-public-key scripts remote-user@ip-address-remote-server:/tmp
```
*login to the remote server*
```
sudo ssh  -i ~/.ssh/your-public-key remote-user@ip-address-remote-server
```
*on remote server execute **1-create-user.sh**  as user with sudo privileges*

*will be created special restricted user to run nginx script*
```
sudo bash /tmp/1-create-user.sh
```
*switch to new nginx user, move to /tmp and run the last script*
```
su - <new-restricted-user>
cd /tmp
sudo ./2-nginx-setup.sh
```
*to check if web server configured properly run*
```
curl -k https://your-frist-domain.com
curl -k https://your-second-domain.com
```
