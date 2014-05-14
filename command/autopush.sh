#!/bin/bash

USAGE="usage: ${CMD_NAME} [push options] [mirror_parent_path]"

# Gets options
push_opt=""
opt=$($MRT_GETOPT_CMD -o ivndbfr: -l verbose,dry-run,delete,backup,force -- "$@")
if [ $? -ne 0 ]; then
    echo $USAGE 1>&2
    exit 1
fi
eval set -- $opt
while [ -n "$1" ]; do
    case $1 in
        -i) confirm="yes"; shift;;
        --) shift; break;;
        *)  push_opt="$push_opt $1"; shift;;
    esac
done

if [ -n "$1" ]; then
    mirror_parent_path="$1"
else
    mirror_parent_path="$PWD"
fi

if [ ! -d "$mirror_parent_path" ]; then
    echo "${CMD_NAME}: Path of mirror parent must be directory."
    echo $USAGE 1>&2
    exit 1
fi

IFS=$'\n'
mirror_pathes=$(find "$mirror_parent_path" -name $MRT_CONFIG_DIR)
for i in ${mirror_pathes[@]}; do
    mirror_path=$(cd "$(dirname "$i")"; pwd)
    if [ -n "$confirm" ]; then
        echo -n "push \"$mirror_path\"? [Y/n]: "
        read ans
    else
        ans="y"
    fi
    if [ -z "$ans" -o "$ans" = "y" -o "$ans" = "Y" ]; then
        echo "exec 'mrt push $push_opt' on $mirror_path"
        eval "cd $mirror_path; $MRT_PATH_BIN/mrt push $push_opt"
    fi
done
