#!/usr/bin/env bash

# check if you are a root
if [ "${UID}" -eq 0 ]; then
    # promt to input username and password
    read -p -r "Enter username : " username
    read -s -p -r "Enter password : " password

    # check exit status of last command
    if grep -e "^${username}" /etc/passwd >/dev/null; then
        echo "${username} exists!"
        exit 1
    else
        # generate encrypted password
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
        
        # add new user
        if useradd --create-home --groups sudo --shell /bin/bash -p "${pass}" "${username}"; then
            echo "User has been added to system!"
        else
            echo "Failed to add a user!"
        fi
    fi
else
    echo "You need root privileges to run this script!"
    exit 1
fi