#!/bin/bash

USAGE="usage: ${CMD_NAME} [-s|--set <remote_path>] [-r|--remote <remote_name>] [file...]"

# Gets options
opt=$($MRT_GETOPT_CMD -o r:s: -l remote:,set: -- "$@")
if [ $? -ne 0 ]; then
    echo $USAGE 1>&2
    exit 1
fi
eval set -- $opt
while [ -n "$1" ]; do
    case $1 in
        -s|--set)    _set=1; remote_path="$2"; shift; shift;;
        -r|--remote) MRT_REMOTE_NAME="$2"; shift; shift;;
        --)          shift; break;;
        *)           echo "$CMD_NAME: Unknown option($1) used."; exit 1;;
    esac
done

# Set remote setting
if [ -n "$_set" ]; then
    # Check .mrt directory
    find_mirror_root "$1"
    if [ -z "$mirror_path" ]; then
        echo "${CMD_NAME}: Current directory isn't in a mirror."
        exit 1
    fi

    # Convert $remote_path to the absolute path if $remote_path is a local directory.
    if [ -d "$remote_path" ]; then
        remote_path=$(cd "$remote_path"; pwd)
    else
        remote_path=${1%/}
    fi

    echo "$remote_path" > "$mirror_path/$MRT_CONFIG_DIR/remote/$MRT_REMOTE_NAME"

# Get remote paths using remote setting
else
    if [ $# -eq 0 ]; then
        # Get remote path of current mirror if any argments are not provided.

        # Check .mrt directory
        find_mirror_root
        if [ -z "$mirror_path" ]; then
            echo "${CMD_NAME}: Current directory isn't in a mirror."
            exit 1
        fi

        # Gets configurations
        get_config "$mirror_path"
        if [ -z "$remote_path" ]; then
            echo "$CMD_NAME: Remote '$MRT_REMOTE_NAME' is not defined."
            exit 1
        fi

        echo $remote_path/
    else
        # Get remote path of each files if file argments are provided.
        _ret=0
        for mirror_file in "$@"; do
            # Check .mrt directory
            mirror_path=""
            find_mirror_root "$mirror_file"
            if [ -z "$mirror_path" ]; then
                echo "${CMD_NAME}: \"$mirror_file\" isn't in a mirror."
                _ret=1
                continue
            fi

            if [ "$mirror_path" != "$mirror_path_prev" ]; then
                # Gets configurations
                get_config "$mirror_path"
                if [ -z "$remote_path" ]; then
                    echo "$CMD_NAME: Remote '$MRT_REMOTE_NAME' is not defined."
                    _ret=1
                    continue
                fi
                mirror_path_prev=$mirror_path
            fi

            # Constructs remote path
            if [ -z "$mirror_path_relative" -o "$mirror_path_relative" == "." ]; then
                relative_path=""
            else
                relative_path=$mirror_path_relative/
            fi
            if [ -d "$mirror_file" ]; then
                echo $remote_path/$relative_path
            else
                echo $remote_path/$relative_path$(basename "$mirror_file")
            fi
        done
        exit $_ret
    fi
fi
