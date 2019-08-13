#!/bin/bash

# skeleton of a bash daemon
# (work in progress)

daemonName="DAEMON_NAME"

pidDir="."
pidFile="$pidDir/$daemonName.pid"
pidFile="$daemonName.pid"

logDir="."
logFile="$logDir/$daemonName.log"
logMaxSize=1024

runInterval=60

doCommands() {
	echo "Running commands."
}

###############################################################################
# Below is the skeleton functionality of the daemon.
###############################################################################

myPid=`echo $$`

setupDaemon() {
	if [ ! -d "$pidDir" ]; then
		mkdir "pidDir"
	fi
	if [ ! -d "$logDir" ]; then
		mkdir "logDir"
	fi
	if [ ! -f "$logFile" ]; then
		touch "$logFile"
	else
		# check to see if we need to rotate the logs
		#size=$((`ls -l "$logFile" | cut -d " " -f 8`/1024)) # hope my math is correct :P
		size=$((`ls -ls "$logFile" | cut -d " " -f 1`/1024)) # hope my math is correct :P
		if [[ $size -gt $logMaxSize ]]; then
			mv $logFile "logFile.old"
			touch "$logFile"
		fi
	fi
}

startDaemon() {
	setupDaemon # make sure directories are there first
	if [[ `checkDaemon` = 1 ]]; then
		echo " * \033[31;5;148mError\033[39m; $daemonName is already running."
		exit 1
	fi
	echo " * Starting $daemonName with PID: $myPid."
	echo "$myPid" > "$pidFile"
	log '*** '`date +"%Y-%m-%d"`": Starting up $daemonName."

	loop
}

stopDaemon() {
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
	if [ `checkDaemon` -eq 1 ]; then
		echo " * $daemonName is running."
	else
		echo " * $daemonName isn't running."
	fi

	exit 0
}

restartDaemon() {
	if [[ `checkDaemon` = 0 ]]; then
		echo "$daemonName isn't running."
		exit 1
	fi

	stopDaemon
	startDaemon
}

checkDaemon() {

	if [ -z "$oldPid" ]; then
		return 0
	elif [[ `ps aux | grep "$oldPid" | grep -v grep` > /dev/null ]]; then
		if [ -f "$pidFile" ]; then
			if [[ `cat "$pidFile"` = "$oldPid" ]]; then
				# daemon is running.
				# echo 1
				return 1
			else
				#daemon isn't running.
				return 0
			fi
		fi
	elif [[ `ps aux | grep "$daemonName" | grep -v grep | grep -v "$myPid" | grep -v "0:00.00"` > /dev/null ]]; then
		# daemon is running but wrong PID, so restart it
		log '*** '`date +%Y-%m-%d"`": $daemonName running with invalid PID; restarting."
		restartDaemon
		return 1
	else
		# daemon not running
		return 0
	fi

	return 1
}

loop() {

	now=`date +%s`

	if [ -z $last ]; then
		last=`date +%s`
	fi

	doCommands

	last=`date +%s`

	if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
		sleep $((now-last+runInterval))
	fi

	loop
}

log() {

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
