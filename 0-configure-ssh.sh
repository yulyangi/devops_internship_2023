#!/usr/bin/env bash

# error handling
set -euo pipefail

script_name=$(basename "$0")
declare remote_user
declare remote_server

function script_usage() {
    cat << EOF
Usage:
     -h|--help      Help
     -u|--user      Remote user
     -s|--server    IP address of remote server (IPv4)
                    Example: ./${script_name} -u user -s 8.8.8.8
                    Key will be created as ~/.ssh/id_rsa_<remote_user>_key
EOF
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

    if [ -z "${remote_user}" ] || [ -z "${remote_server}" ]; then
        echo "Invalid options were provided!" && script_usage && exit 1
    fi
}

function create_ssh_key(){
    # check if file exists
    if [[ -n $(find "/home/${USER}/.ssh/" -type f -name "id_rsa_${remote_user}_key") ]]; then
        echo "File already exists!" && exit 1
    fi
    # generate ssh key
    ssh-keygen -f "/home/${USER}/.ssh/id_rsa_${remote_user}_key" -t rsa -N ""
    chmod 400 "/home/${USER}/.ssh/id_rsa_${remote_user}_key"
    # copy ssh key to remote server
    ssh-copy-id -i "/home/${USER}/.ssh/id_rsa_${remote_user}_key" "${remote_user}@${remote_server}"
}

parse_params "${@}"
create_ssh_key
