#!/usr/bin/env bash

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # promt to input username and password
    read -p "Enter username : " username
    read -s -p "Enter password : " password

    # check if user exists
    egrep "^${username}" /etc/passwd >/dev/null

    # check exit status of last command
    if [ $? -eq 0 ]; then
        echo "${username} exists!"
        exit 1
    else
        # generate encrypted password
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        
        # add new user
        useradd --create-home --groups sudo --shell /bin/bash -p "${pass}" "${username}"
        [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
    fi
else
    echo "You need root privileges to run this script!"
    exit 1
fi