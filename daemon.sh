#!/bin/bash

# skeleton of a bash daemon
# This is a simple skeleton of a bash daemon. To use, just set the daemonName 
# variable and add in commands or outside script to run in the doCommands 
# function. Alter the variables in these top few lines to fit your needs.
#
# (work in progress)

daemonName="DAEMON_NAME"

pidDir="."
pidFile="$pidDir/$daemonName.pid"
pidFile="$daemonName.pid"

logDir="."
# to use a dated log file.
# logFile="$logDir/$daemonName-"`date +"%Y-%m-%d"`".log"
# to use a simple, regular log file
logFile="$logDir/$daemonName.log"

# log maxsize in KB
logMaxSize=1024 # 1mb

runInterval=60 # in seconds

doCommands() {
	# This is where you would put commands you'd like to run.
	echo "Running commands."
}

###############################################################################
# Below is the actual functionality of the daemon.
###############################################################################

myPid=`echo $$`

setupDaemon() {
	# make sure our directories work properly
	if [ ! -d "$pidDir" ]; then
		mkdir "pidDir"
	fi
	if [ ! -d "$logDir" ]; then
		mkdir "logDir"
	fi
	if [ ! -f "$logFile" ]; then
		touch "$logFile"
	else
		# check to see if we need to rotate log files
		size=$((`ls -ls "$logFile" | cut -d " " -f 1`/1024)) # hope my math is correct :P
		if [[ $size -gt $logMaxSize ]]; then
			mv $logFile "logFile.old"
			touch "$logFile"
		fi
	fi
}

startDaemon() {
	# start the daemon
	setupDaemon # first,  make sure directories exist
	if [[ `checkDaemon` = 1 ]]; then
		echo " * \033[31;5;148mError\033[39m; $daemonName is already running."
		exit 1
	fi
	echo " * Starting $daemonName with PID: $myPid."
	echo "$myPid" > "$pidFile"
	log '*** '`date +"%Y-%m-%d"`": Starting up $daemonName."

	# start the loop
	loop
}

stopDaemon() {
	# stop the daemon
	if [ `checkDaemon` -eq 0 ]; then
		echo " * \033[31;5;148mError\033[39m: $daemonName is not running."
		exit 1
	fi
	echo " * Stopping $daemonName"
	log '*** '`date +"%Y-%m-%d"`": $daemonName stopped."

	if [ ! -z `cat $pidFile` ]; then
		kill -9 `cat "$pidFile"` &> /dev/null
	fi
}

statusDaemon() {
	# query and determine if daemon is running
	if [ `checkDaemon` -eq 1 ]; then
		echo " * $daemonName is running."
	else
		echo " * $daemonName isn't running."
	fi

	exit 0
}

restartDaemon() {
	# restart the daemon
	if [[ `checkDaemon` = 0 ]]; then
		# can't restart if it's not running
		echo "$daemonName isn't running."
		exit 1
	fi

	stopDaemon
	startDaemon
}

checkDaemon() {
	# check to see if daemon is running

	# separate function from statusDaemon so that we can utilize it 
	# in other functions
	if [ -z "$oldPid" ]; then
		return 0
	elif [[ `ps aux | grep "$oldPid" | grep -v grep` > /dev/null ]]; then
		if [ -f "$pidFile" ]; then
			if [[ `cat "$pidFile"` = "$oldPid" ]]; then
				# daemon is running.
				return 1
			else
				#daemon isn't running.
				return 0
			fi
		fi
	elif [[ `ps aux | grep "$daemonName" | grep -v grep | grep -v "$myPid" | grep -v "0:00.00"` > /dev/null ]]; then
		# daemon is running but wrong PID, so we restart it
		log '*** '`date +%Y-%m-%d"`": $daemonName running with invalid PID; restarting."
		restartDaemon
		return 1
	else
		# daemon is not running
		return 0
	fi

	return 1
}

loop() {
	# this is our loop that runs forever
	now=`date +%s`

	if [ -z $last ]; then
		last=`date +%s`
	fi

	# do everything that we need the daemon to do (defined above)
	doCommands

	# check to see how long we need to sleep for, if we want to run this once
	# every minute and it's taken more than 60s then we'll just run it anyway
	last=`date +%s`

	# set sleep interval
	if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
		sleep $((now-last+runInterval))
	fi

	# go back to beginning and start over
	loop
}

log() {
	# simple logging
	echo "$1" >> "$logFile"
}


###############################################################################
# Parse runtime command
###############################################################################

if [ -f "$pidFile" ]; then
	oldPid=`cat "$pidFile"`
fi
checkDaemon
case "$1" in
	start)
		startDaemon
		;;
	stop)
		stopDaemon
		;;
	status)
		statusDaemon
		;;
	restart)
		restartDaemon
		;;
	*)
	echo "\033[31;5;148mError\033[39m: usage $0 { start | stop | restart | status }"
	exit 1
esac

exit 0
