#!/usr/bin/env bash

# error handling
set -eo pipefail

script_name=$(basename "$0")
declare remote_user
declare remote_server
declare key_name

function script_usage() {
    cat << EOF
Usage:
     -h|--help      Help
     -k|--key       Key name
     -u|--user      Remote user
     -s|--server    IP address of remote server (IPv4)
                    Example: ./${script_name} -k keyname -u user -s 8.8.8.8
                    Key will be created as ~/.ssh/keyname
EOF
}

function create_ssh_key(){
    # generate ssh key
    ssh-keygen -f "/home/${USER}/.ssh/${key_name}" -t rsa -N ""
    chmod 400 "/home/${USER}/.ssh/${key_name}"
    # copy ssh key to remote server
    ssh-copy-id -i "/home/${USER}/.ssh/${key_name}" "${remote_user}@${remote_server}"
}

function parse_params() {
    local param
    local ip="((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}"
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case "${param}" in
            -h | --help)
                script_usage && exit 0
                ;;
            -k | --key)
                key_name=$1
                # check if file exists
                if [[ -n $(find "/home/${USER}/.ssh/" -type f -name "${key_name}") ]]; then
                    echo "File already exists!" && exit 1
                fi
                shift
                ;;
            -u | --user)
                remote_user=$1
                shift
                ;;
            -s | --server)
                remote_server=$1
                if [[ ! "${remote_server}" =~ $ip ]]; then 
                    echo "Invalid IP was provided!" && exit 1
                fi
                shift
                ;;
            *)
                printf "%s\n" "Invalid parameter was provided: ${param}" && exit 1
                ;;
        esac
    done
}

parse_params "${@}"

# main condition
if [[ -z "${key_name}" || -z "${remote_user}" || -z "${remote_server}" ]]; then 
    echo "No args were provided!"
    script_usage && exit 1
else 
    create_ssh_key
fi
