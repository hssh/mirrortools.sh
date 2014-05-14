#!/bin/bash

USAGE="usage: ${CMD_NAME} remote [mirror]"

# Gets remote path
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        remote_path=$(cd "$1"; pwd)
    else
        remote_path=${1%/}
    fi
else
    echo "${CMD_NAME}: The path of remote is not provided." 1>&2
    echo $USAGE 1>&2
    exit 1
fi

# Gets mirror path
if [ -n "$2" ]; then
    mirror_path=${2%/}
else
    mirror_path=$(basename "$(echo $remote_path | cut -d: -f2)")
fi

# Setup mirror directory from skelton
if [ ! -d "$mirror_path/$MRT_CONFIG_DIR" ] ; then
    rsync --recursive "$MRT_PATH_SKELTON/" "$mirror_path/"
    echo "$remote_path" > "$mirror_path/$MRT_CONFIG_DIR/remote/$MRT_REMOTE_NAME"
else
    echo "\"$mirror_path/$MRT_CONFIG_DIR\" aleady exists.";
fi
