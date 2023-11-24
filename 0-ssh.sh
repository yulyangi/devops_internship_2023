#!/usr/bin/env bash

remote_user=$1
remote_server=$2

ssh-keygen -f "~/.ssh/id_rsa_${remote_user}_key" -t rsa -N ""
# ssh-copy-id -i "~/.ssh/id_rsa_${remote_user}_key" "${remote_user}@${remote_server}"



