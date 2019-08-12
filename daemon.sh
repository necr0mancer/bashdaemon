#!/bin/bash

# skeleton of a bash daemon
# (work in progress)

daemonName="DAEMON-NAME"

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

	loop
}

stopDaemon() {

	echo " * Stopping $daemonName"
	log '*** '`date +"%Y-%m-%d"`": $daemonName stopped."
}

statusDaemon() {

	exit 0
}

restartDaemon() {

	stopDaemon
	startDaemon
}

checkDaemon() {

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
	oldPid=`cat "pidFile"`
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
