#!/bin/bash

# Copyright (c) 2005, 2006 Miek Gieben
# See LICENSE for the license
#
# Print a filelist suitable for Restore a entire backed up directory
# +MONTHDAY (restore to MONTHDAY's state)

set -o nounset

monthday=0
max=0
min=99
prevfile=""
name=""
PROGNAME=$0
# previous vars
pmode=""
puid=""
pgid=""
ppsize=""
pfsize=""

_echo2() {
        echo "** $PROGNAME: $1" > /dev/fd/2
}

cleanup() {
        _echo2 "Signal received while processing \`$path', exiting" 
        exit 1
}
# trap at least these
trap cleanup SIGINT SIGPIPE

usage() {
        echo "$PROGNAME [OPTIONS] [+DAY]"
        echo
        echo print a list suitable for restoring
        echo
        echo +DAY - restore up to this month day
        echo
        echo OPTIONS:
        echo " -h        this help"
}

reset_vars() {
        # don't you love these implicit globals
        pmode=$mode
        puid=$uid
        pgid=$gid 
        ppsize=$psize
        pfsize=$fsize
        prevfile="$name"
}

while getopts "h" o; do
        case $o in
                h) usage && exit;;
                \?) usage && exit;;
        esac
done
shift $((OPTIND - 1))

if [[ $# -eq 1 ]]; then
        # we have a + argument
        if [[ $1 =~ "\\+(.+)" ]]; then
                monthday=${BASH_REMATCH[1]}
                if [[ ! $monthday =~ "[0-9]+" ]]; then
                        _echo2 "+DAY must be numerical"
                        exit 1
                fi
        else
                _echo2 "Need a +DAY argument"
                exit 1
        fi
fi

if [[ $monthday -lt 0 || $monthday -gt 31 ]]; then
        _echo2 "+DAY out of bounds [0..31]"
        exit 1
fi

i=0
declare -a n    # filename
declare -a d    # version day
declare -a m    # version min
declare -a s    # version sec
declare -a path
while read mode uid gid psize fsize path
do
        if [[ "$path" =~ "(.+)\\+(..)\\.(..):(..)$" ]]; then
                name=${BASH_REMATCH[1]}
                n[$i]=${BASH_REMATCH[1]}
                d[$i]=$((10#${BASH_REMATCH[2]})) # force base 10
                m[$i]=$((10#${BASH_REMATCH[3]})) # force base 10
                s[$i]=$((10#${BASH_REMATCH[4]})) # force base 10

                if [[ ${d[$i]} -gt $max ]]; then
                        max=${d[$i]}
                fi
                if [[ ${d[$i]} -lt $min ]]; then
                        min=${d[$i]}
                fi
                i=$((i + 1))
        else 
                name="$path"
        fi

        if [[ "$prevfile" != "$name" ]]; then
                # new name
                d[$i]=99    # guardian

                # a lot of if's here to extract the correct file wrt the
                # monthday given on the cmd line - we need to check the
                # interval of the files we got in the backup and extract
                # the correct one
                        
                if [[ $min -gt $max || $monthday -eq 0 ]]; then
                        # no versions where seen, use the last one if defined
                        echo -n "$mode $uid $gid $psize $fsize "
                        echo "$name"
                else
                        if [[ $monthday -lt $min ]]; then
                                # before any of the versions, use $min
                                echo -n "$pmode $puid $pgid $ppsize $pfsize "
                                printf "%s+%02d.%02d:%02d\n" "${n[0]}" $min ${m[0]} ${s[0]}
                                reset_vars
                                max=0; min=99
                                i=0
                                continue
                        fi

                        if [[ $monthday -gt $max ]]; then
                                # after any of the versions, use the
                                # plain one
                                echo -n "$pmode $puid $pgid $ppsize $pfsize "
                                echo "$prevfile"
                                reset_vars
                                max=0; min=99
                                i=0
                                continue
                        fi
                        
                        # still alive, our day number must be in
                        # the array, check for a match, assume an
                        # ordered array!
                        i=0
                        for j in ${d[@]}; do 
                                if [[ $j -eq 99 ]]; then
                                        break 
                                fi
                                if [[ $j -eq $monthday ]]; then
                                        echo -n "$pmode $puid $pgid $ppsize $pfsize "
                                        printf "%s+%02d.%02d:%02d\n" "${n[$i]}" ${d[$i]} ${m[$i]} ${s[$i]}
                                        break
                                fi
                                if [[ $j -gt $monthday ]]; then
                                        # previous one
                                        i=$(($i - 1))
                                        echo -n "$pmode $puid $pgid $ppsize $pfsize "
                                        printf "%s+%02d.%02d:%02d\n" "${n[$i]}" ${d[$i]} ${m[$i]} ${s[$i]} 
                                        break 
                                fi
                                i=$(($i + 1))
                        done
                fi
                max=0; min=99
                i=0
        fi
        reset_vars
done