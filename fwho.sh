#!/bin/bash
# =========================================================================
# fwho.sh
# Author:   Chris W.
# Date:     2026-03-13
# Last rev: 2026-03-13
# Description: Displays information about users currently logged in to the system.
# Also allows for option to kick active users from system.
# To Do: Add functionality to kick active users from system.
# =========================================================================

# colored text constants
RESET="\e[0m"
DEFAULT="\e[0m"
CYAN="\e[36m"
MAGENTA="\e[31m"
YELLOW="\e[38;5;228m"
PURPLE="\e[38;5;141m"
RED="\e[38;5;141m"
GREEN="\e[38;5;43m"
BLUE="\e[38;5;26m"
LTPURP="\e[38;5;219m"
ORANGE="\e[38;5;216m"

# Error check - root
if [[ $(whoami) != "root" ]]; then
    printf $PURPLE
    printf " _> Error! Must run as root!\n"
    printf " _> Try again...\n\n"
    printf $RESET
    exit 1
fi
# ==> end of error checks
 
# adjust default user name length display
# (default is 8)
export PROCPS_USERLEN="12"
name=""      # needs to be global for function calls
 
function current_logins () {
    # get info with 'w' command;
    # pack it into $curr
    curr=$(w -ih)
    i=0
 
    # get current date
    current_date=$(date | tr -s " " | cut -d" " -f1-3)
    current_time=$(date | awk '{print $4}' | cut -d: -f1,2)
 
    # heading info
    printf $LTPURP
    printf "\n CURRENT LOGINS (%s - %s)\n" "$current_date" "$current_time"
    printf "===========================================\n"
    printf "USER               FROM              LOGIN@\n"
    printf "===========================================\n"
    printf $GREEN
 
    # main loop (parse input and display)
    while read -r user tty from t idle jcpu pcpu what
    do
        rname=$(grep -E $user /etc/passwd | cut -d":" -f5 \
        | sed -E "s/([-a-zA-Z]+), ([a-zA-Z]+)( [A-Z]\.)?,([ 0-9]+)/\2 \1/")
 
        printf "%-12s %-20s %-16s %-8s\n" $user "${rname:0:20}" $from $t
        # ${rname:0:20} truncates long user names
 
        ((i++))
 
        # alternate output colors (QOL)
        if (( i % 2 ))
        then
            printf $PURPLE
        else
            printf $GREEN
        fi
    done <<< $curr
 
    # summary info
    printf $LTPURP
    printf "=================================================================\n"
    printf " $i USERS LOGGED IN\n"
    printf "=================================================================\n\n"
    printf $RESET
    sleep 1s
}
 
# kicks logged in user
function kick_user () {
    # get user name
    read -p " _> Username? " name </dev/tty
    echo
 
    # double check that username is still logged in/exists
    # possiblity of typos or user may log out before kicking
    # if so, kill it
    if [[ $(who | grep -Eo "\b$name\b") ]]; then
        # friendly warning
        write $name <<< "\n  *** Logging you out! Bye now... ***\n"
        sleep 2s
 
        # pkill kills all user processes, including login
        pkill -9 -u $name
        sleep 1s
 
        # check for success
        if [[ $? ]]; then
            printf $RED
            printf " _> User $name kicked!\n\n"
            printf $RESET
        else  # if pkill fails, for some reason
            printf $RED
            printf " _> Error! Couldn't kick $name\n\n"
            printf $RESET
        fi
    else # if username not found with who
        printf $RED
        printf " _> Error! User $name not found/not logged in\n\n"
        printf $RESET
    fi
 
    sleep 1s    # pause for one second (QOL)
}
 
# Disable user account
# ToDo (2025-04-28): shouldn't be called if kick_user fails
function disable_account () {
    printf $ORANGE
    read -n1 -p " _> Disabling $1: Are you sure [y/N]? " reply </dev/tty
    echo
 
    if [[ $reply =~ [yY] ]]; then
        usermod -L -e 1 "$1" &>/dev/null
 
        if [[ $? ]]; then
            printf $RED
            printf "\n _> User account, $1, disabled!\n\n"
            printf $RESET
        else
            printf $RED
            printf " _> Error! Could not disable account $1\n"
            printf $RESET
        fi
    else
        printf " _> User account, $1, NOT disabled\n"$RESET
    fi
 
    sleep 1s
    return 0
}
 
# main (initial display)
clear
current_logins   # Display current logged in users
 
printf $ORANGE
read -n1 -p " _> Kick user [y/N]? " kick </dev/tty
echo
 
# if user answers 'y'
if [[ $kick =~ [yY] ]]; then
    kick_user
 
    # ToDo: Move this into kick_user function
    printf $ORANGE
    read -n1 -p " _> Disable user account $name [y/N]? " dis </dev/tty
    echo
 
    if [[ $dis =~ [yY] ]]; then
        disable_account $name
    else
        printf $GREEN
        printf " _> User account, $name, not disabled\n"
        printf $RESET
    fi
else # if user enters 'n' (or anything other than 'y')
    printf $GREEN
    printf " _> Ok ... no kicking today :(\n\n"
    printf $RESET
fi
 
printf $RESET
exit 0