#!/bin/bash

#
# find mirror root path
#
function find_mirror_root() {
    local _base_path
    if [ -n "$1" ]; then
        if [ -d "$1" ]; then
            _base_path=$(cd "$1"; pwd)
        else
            _base_path=$(cd "$(dirname "$1")"; pwd)
        fi
    else
        _base_path="$PWD"
    fi

    local _path=$_base_path
    while :; do
        if [ -d "$_path/$MRT_CONFIG_DIR" ]; then
            mirror_path=$_path

            # Gets relative path to mirror root from base_path
            if [ "$mirror_path" = "$_base_path" ]; then
                mirror_path_relative=.
            else
                mirror_path_relative=${_base_path#"$mirror_path/"}
            fi

            break
        fi

        if [ "$_path" = "/" ]; then
            break
        fi

        _path=$(dirname "$_path")
    done
}

#
# Check configurations
#
function check_config() {
    status=0
    dir_exist  $MRT_PATH;            status=`expr $status \| $?`
    dir_exist  $MRT_PATH_CONFIG;     status=`expr $status \| $?`
    dir_exist  $MRT_PATH_LIB;        status=`expr $status \| $?`
    dir_exist  $MRT_PATH_COMMAND;    status=`expr $status \| $?`
    dir_exist  $MRT_PATH_SKELTON;    status=`expr $status \| $?`
    file_exist $MRT_EXCLUDES_COMMON; status=`expr $status \| $?`
    return $status
}

#
# Check existence
#
function exist() {
    if [ -f "$1" ]; then
        return 0
    else
        echo "$CMD_NAME: \"$1\" is not found."
        return 1
    fi
}

#
# Check file existence
#
function file_exist() {
    if [ -f "$1" ]; then
        return 0
    else
        echo "$CMD_NAME: File \"$1\" is not found."
        return 1
    fi
}

#
# Check directory existence
#
function dir_exist() {
    if [ -d "$1" ]; then
        return 0
    else
        echo "$CMD_NAME: Directory \"$1\" is not found."
        return 1
    fi
}

#
# Get configureations
#
function get_config() {
    local _mirror_path=${1%/}
    unset includes excludes remote_path

    if [ -f "$_mirror_path/$MRT_CONFIG_DIR/config" ]; then
        . "$_mirror_path/$MRT_CONFIG_DIR/config"
    fi
    if [ -f "$_mirror_path/$MRT_CONFIG_DIR/includes" ]; then
        includes=$_mirror_path/$MRT_CONFIG_DIR/includes
    fi
    if [ -f "$_mirror_path/$MRT_CONFIG_DIR/excludes" ]; then
        excludes=$_mirror_path/$MRT_CONFIG_DIR/excludes
    fi
    if [ -f "$_mirror_path/$MRT_CONFIG_DIR/remote/$MRT_REMOTE_NAME" ]; then
        read remote_path < "$_mirror_path/$MRT_CONFIG_DIR/remote/$MRT_REMOTE_NAME"
    fi
}

#
# Get rsync filter options
#
function get_rsync_filter_options() {
    if [ -n "$includes" ]; then
        rsync_filter_opt="$rsync_filter_opt --include-from=\"$includes\""
    fi
    if [ -n "$includes_mirror" ]; then
        rsync_filter_opt="$rsync_filter_opt --include-from=\"$includes_mirror\""
    fi

    if [ -n "$excludes" ]; then
        rsync_filter_opt="$rsync_filter_opt --exclude-from=\"$excludes\""
    fi
    if [ -n "$excludes_mirror" ]; then
        rsync_filter_opt="$rsync_filter_opt --exclude-from=\"$excludes_mirror\""
    fi
    if [ -n "$MRT_EXCLUDES_COMMON" ]; then
        rsync_filter_opt="$rsync_filter_opt --exclude-from=\"$MRT_EXCLUDES_COMMON\""
    fi
}
