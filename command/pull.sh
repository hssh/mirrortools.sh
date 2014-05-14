#!/bin/bash

USAGE="usage: ${CMD_NAME} [-v|--verbose] [-n|--dry-run] [-d|--delete] [-b|--backup] [-r|--remote <remote_name>] [file]"

# Gets options
opt=$($MRT_GETOPT_CMD -o vndbfr: -l verbose,dry-run,delete,backup,force,remote: -- "$@")
if [ $? -ne 0 ]; then
    echo $USAGE 1>&2
    exit 1
fi
eval set -- $opt
while [ -n "$1" ]; do
    case $1 in
        -v|--verbose) rsync_opt="$rsync_opt --verbose"; shift;;
        -n|--dry-run) rsync_opt="$rsync_opt --dry-run"; shift;;
        -d|--delete)  rsync_opt="$rsync_opt --delete"; shift;;
        -b|--backup)  rsync_opt="$rsync_opt --backup --suffix=.`date +%Y%m%d`"; shift;;
        -f|--force)   force_pull=1; shift;;
        -r|--remote)  MRT_REMOTE_NAME="$2"; shift; shift;;
        --)           shift; break;;
        *)            echo "$CMD_NAME: Unknown option($1) used."; exit 1;;
    esac
done

# Check .mrt directory
find_mirror_root "$1"
if [ -z "$mirror_path" ]; then
    if [ -n "$1" ]; then
        echo "${CMD_NAME}: \"$1\" isn't in a mirror."
    else
        echo "${CMD_NAME}: Current directory isn't in a mirror."
    fi
    exit 1
fi

# Gets configurations
get_config "$mirror_path"
if [ -z "$remote_path" ]; then
    echo "$CMD_NAME: Remote '$MRT_REMOTE_NAME' is not defined."
    exit 1
fi

# Constructs source & destination path
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        destination=${1%/}/
    else
        destination=$1
    fi

    source=$($MRT_PATH_BIN/mrt remote --remote "$MRT_REMOTE_NAME" "$1")
else
    destination=$mirror_path/
    source=$($MRT_PATH_BIN/mrt remote --remote "$MRT_REMOTE_NAME")
    get_rsync_filter_options
fi

# Check the allowance
if [ ! -z "$MRT_DENY_PULL" -a -z "$force_pull" ]; then
    echo "$CMD_NAME: Pull is denied." 1>&2
    exit 1
fi

# Executes rsync command
cmd="$MRT_RSYNC_CMD $MRT_RSYNC_OPT$rsync_opt$rsync_filter_opt \"$source\" \"$destination\""
echo $cmd
eval $cmd
