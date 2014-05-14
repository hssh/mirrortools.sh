#!/bin/bash

USAGE="usage: ${CMD_NAME} [-v|--verbose] [-n|--dry-run] [-d|--delete] [-b|--backup] remote [mirror]"

# Gets options
opt=$($MRT_GETOPT_CMD -o vndb -l verbose,dry-run,delete,backup -- "$@")
if [ $? -ne 0 ]; then
    echo $USAGE 1>&2
    exit 1
fi
eval set -- $opt
while [ -n "$1" ]; do
    case $1 in
        -v|--verbose) rsync_opt="$rsync_opt --verbose"; shift;;
        -n|--dry-run) rsync_opt="$rsync_opt --dry-run"; dry_run=1; shift;;
        -d|--delete)  rsync_opt="$rsync_opt --delete"; shift;;
        -b|--backup)  rsync_opt="$rsync_opt --backup --suffix=.`date +%Y%m%d`"; shift;;
        --)           shift; break;;
        *)            echo "$CMD_NAME: Unknown option($1) used."; exit 1;;
    esac
done

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

# Constructs mirror path
if [ -n "$2" ]; then
    mirror_path=${2%/}
else
    mirror_path=$(basename "$(echo $remote_path | cut -d: -f2)")
fi

# Setup mirror directory from skelton
if [ ! -d "$mirror_path/$MRT_CONFIG_DIR" ] ; then
    rsync --recursive "$MRT_PATH_SKELTON/" "$mirror_path/"
    echo "$remote_path" > "$mirror_path/$MRT_CONFIG_DIR/remote/$MRT_REMOTE_NAME"
fi

# Gets configurations
get_config "$mirror_path"
if [ -z "$remote_path" ]; then
    echo "$CMD_NAME: Remote of the mirror is not defined."
    exit 1
fi

# Executes rsync command
source=$remote_path/
destination=$mirror_path/
get_rsync_filter_options
cmd="$MRT_RSYNC_CMD $MRT_RSYNC_OPT$rsync_opt$rsync_filter_opt \"$source\" \"$destination\""
echo $cmd
eval $cmd
