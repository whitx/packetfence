#!/bin/bash

#Get the log for the current day

DATE=now

if [ "$#" != "0"  ]; then
    DATE="$@"
fi

PATTERN1="$(date --date="$DATE" +'%b %d').*"

PATTERN2="$(date --date="$DATE" +'\[%a %b %d').*"

PATTERN3=".*?$(date --date="$DATE" +'\[%d/%b/%Y').*"

PATTERN4="$(date --date="$DATE" +'%a %b %d').*"

LOGDIR=/usr/local/pf/logs

TEMPDIR=$(mktemp -d)

TEMPLOGDIRNAME="logs-$(date +'%Y%m%d%H%M%S')"

TEMPLOGDIR=$TEMPDIR/$TEMPLOGDIRNAME
mkdir $TEMPLOGDIR

extract_log() {
    PATTERN=$1
    shift
    while [ "$#" != "0" ];do
        LOGNAME="$1"
        LOG="$LOGDIR/$LOGNAME"
        grep -P -A"$(wc -l $LOG  | cut -d' ' -f1)" "$PATTERN1" "$LOG" > "$TEMPLOGDIR/$LOGNAME"
        shift
    done
}

extract_log "$PATTERN1" catalyst.log packetfence.log
extract_log "$PATTERN2" admin_error_log portal_error_log webservices_error_log
extract_log "$PATTERN3" admin_access_log portal_access_log  webservices_access_log
extract_log "$PATTERN4" radius.log

tar -C"$TEMPDIR" -zcf $TEMPLOGDIRNAME.tar.gz $TEMPLOGDIRNAME

rm -rf $TEMPDIR
