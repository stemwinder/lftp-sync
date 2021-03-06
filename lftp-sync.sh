#!/bin/bash
########################################################################
#
# lftp-sync:    A simple interface for using lftp to mirror remote data
#               structures based on file modification times.
# Author:       Joshua Smith
# Contact:      <josh@stemwinder.net>
#
# Changelog (sorted newest -> oldest):
#   - 2015-03-01:   Adds support for OS X; Changes config file name; Adds
#                   large changes to README.md
#   - 2015-02-28:   Initial work on timespec syncing and logging
#
########################################################################

# support for `coreutils` on OS X
if [[ $OSTYPE == darwin* ]]; then
    readlink_cmd='greadlink'
    date_cmd='gdate'
else
    readlink_cmd='readlink'
    date_cmd='date'
fi

# set path and name variables
this_path=$("$readlink_cmd" -f $0)  ## Path of this file including filename
dir_name=`dirname ${this_path}`     ## Parent directory of this file WITHOUT trailing slash
myname=`basename ${this_path}`      ## file name of this script

# inlcude default config settings
if [ ! -f "$dir_name/lftp-sync.cfg" ] ; then
    echo "No config file was found. Exiting."
    exit 1
else
    source "$dir_name/lftp-sync.cfg"
fi

# define and display help info to the user
function help {
    echo "
    usage: lftp-sync.sh [options]
    -h      optional  Print this help message
    -s      required  Path to remote source.
            Adding or removing a trailing slash will affect the behaviour.
    -t      required  Path to local target.
            Adding or removing a trailing slash will affect the behaviour.
    -v      optional  Lftp mirror verbosity level
            default is 0, options are 1, 2 and 3
    -m      optional  Number of parallel downloads.
            Smaller files will benefit from more concurrent downloads.
            default is 15
    -n      optional  Number of pget segments per download.
            Larger files will benefit from higher segment counts.
            default is 10
    -u      optional  Total Upload limit
            default is 0 (unlimited)
            This argument is passed directly to lftp
    -d      optional  Total Download limit
            default is 0 (unlimited)
            This argument is passed directly to lftp
    -o      optional  Time override (--newer-than)
            Overrides the default time behaviour of script"
    exit 1
}

# write input to log file
function log {
    echo "[`date`] - ${*}" >> "$dir_name/$log_file"
}

# If no arguments are passed to this script, it should always show the usage info.
# The script will never perform any action unless the necessary parameters are explicitly used.
if [ $# == 0 ] ; then
  help
  exit 1;
fi

# get command line arguements
while getopts hs:t:v:m:n:u:d:o: opt; do
  case $opt in
  s)
      source_path=$OPTARG
      ;;
  t)
      target_path=$OPTARG
      ;;
  v)
      verbosity=$OPTARG
      ;;
  m)
      streams=$OPTARG
      ;;
  n)
      segments=$OPTARG
      ;;
  u)
      ul_limit=$OPTARG
      ;;
  d)
      dl_limit=$OPTARG
      ;;
  o)
      newer_than=$OPTARG
      ;;
  h)
      help
      ;;
  esac
done

# makes paramters accesible by arguement number (eg: $1, $2, ...)
shift $((OPTIND - 1))

# making sure we have both a source and target path
if [[ -z "$source_path" ]] || [[ -z "$target_path" ]]; then
  echo "Error: A source and target path must be specified."
  exit 1;
fi

log "Begin script execution"

# create time logfile if doesn't exist
if [ ! -f "$dir_name/$time_log_file" ] ; then
    touch "$dir_name/$time_log_file"
    log "Time logfile had to be created"
fi

# read last line from time logfile
DONE=false
until $DONE ;do
  read || DONE=true
  [[ ! $REPLY ]] && continue
  TIME_FROM_LOG="$REPLY"
done < "$dir_name/$time_log_file"

# check if we got a timestamp from logfile,
# if not, set TIMESPEC to current datetime in UTC
if [[ -z "$TIME_FROM_LOG" ]]; then
  TIMESPEC="$("$date_cmd" -u +"%Y-%m-%d %H:%M:%S")"
  log "TIMESPEC was set from system time"
else
  TIMESPEC="$TIME_FROM_LOG"
  log "TIMESPEC was set from logfile: $TIMESPEC"
fi

# check for timespec override from command line
if ! [[ -z "$newer_than" ]]; then
  TIMESPEC="$("$date_cmd" -d "$newer_than" -u +"%Y-%m-%d %H:%M:%S")"
  log "TIMESPEC was overriden from command line ($TIMESPEC)"
else
  # write current time to logfile in UTC if timespec wasn't overriden
  echo "$("$date_cmd" -u +"%Y-%m-%d %H:%M:%S")" >> "$dir_name/$time_log_file"
fi

# execute lftp command
log "Start lftp sync"
lftp_command="lftp -c \"connect -u $username,$password sftp://$server:$port; set net:limit-total-rate $dl_limit:$ul_limit; mirror $lftp_mirror_args --verbose=$verbosity --newer-than=\\\"$TIMESPEC\\\" --parallel=$streams --use-pget-n=$segments \\\"$source_path\\\" \\\"$target_path\\\"; quit\""
log $lftp_command
eval $lftp_command 2>&1 | tee "$dir_name/$lftp_log_dir/$("$date_cmd" +"%Y-%m-%d_%H:%M:%S_%Z").log"

# exit script with success code
log "Script execution complete"
exit 0