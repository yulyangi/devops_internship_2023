#!/usr/bin/env bash

script_name=$(basename "$0")

function script_usage() {
    cat << EOF
Usage:
     -h|--help      Help
     -u|--user      Remote user
     -s|--server    IP address of remote server
                    Example: ./${script_name} -u user -s 1.2.3.4
EOF
}

function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h | --help)
                script_usage
                exit 0
                ;;
            -u | --user)
                remote_user=$1
                shift
                ;;
            -s | --server)
                remote_server=$1
                shift
                ;;
            *)
                script_exit "Invalid parameter was provided: $param"
                ;;
        esac
    done
}

function create_ssh_key(){
    # generate ssh key
    ssh-keygen -f "/home/${USER}/.ssh/id_rsa_${remote_user}_key" -t rsa -N ""
    # copy ssh key to remote server
    ssh-copy-id -i "/home/${USER}/.ssh/id_rsa_${remote_user}_key" "${remote_user}@${remote_server}"
}

parse_params "${@}"
create_ssh_key "${@}"
