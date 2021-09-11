#!/bin/sh

# Config-file location for this script
CONFIG='/etc/transmission.conf'

config()
{
	# Reading config-file
	if test -f $CONFIG
	then
		. /etc/transmission.conf
	else
		echo -n "No config-file! "
	fi

	# Config-files directory for daemon and remote utility
	# /root/.config/transmission/ by default
	CONFIG_DIR=${CONFIG_DIR:-'/root/.config/transmission/'}

	# PID-file of daemon
	# /var/run/transmission.run by default
	PIDFILE=${PIDFILE:-'/var/run/transmission.run'}

	# Socket-file of daemon
	# /tmp/transmission.socket
	SOCKET=${SOCKET:-'/tmp/transmission.socket'}

	# Follow - options, that remote utility transmit to daemon trough socket-file

	# Used encryption type (required|preffered|tolerated):
	# required - peers without encryption support is denied
	# preffered - use encrypted connection if peer support it
	# tolerated - allowed any connections
	ENCRYPTION=${ENCRYPTION:-'required'}

	# Download and upload speed limit in Kb/s
	# unlimited by default
	DOWNLOAD=${DOWNLOAD:-'unlimited'}
	UPLOAD=${DOWNLOAD:-'unlimited'}

	# Exchanging information about peers (enable|disable):
	# enable by default
	PEER_EXCHANGE=${PEER_EXCHANGE:-'enable'}

	# Directory for torrent-files
	# $CONFIG_DIR/torrents by default
	TORRENT_DIR=${TORRENT_DIR:-$CONFIG_DIR'/torrents/'}

	# Use nat-pmp and upnp protocol if we are behind the gateway (enable|disable):
	# enable by default
	PORT_MAPPING=${PORT_MAPPING:-'enable'}

	# Listen tcp port for incoming connections
	# 51413 by default
	PORT=${PORT:-51413}

	# User and group - owner of socket
	# root by default
	USER=${USER:-'root'}
	GROUP=${GROUP:-'root'}
}

# Building options for remote utility
build()
{
	ARGS=''

	ARGS=${ARGS}' -c '$ENCRYPTION

	if test x$DOWNLOAD == xunlimited
	then
		ARGS=$ARGS' -D'
	else
		ARGS=$ARGS' -d '$DOWNLOAD
	fi

	if test x$UPLOAD == xunlimited
	then
		ARGS=$ARGS' -U'
	else
		ARGS=$ARGS' -u '$UPLOAD
	fi

	if test x$PEER_EXCHANGE == xenable
	then
		ARGS=$ARGS' -e'
	else
		ARGS=$ARGS' -E'
	fi

	ARGS=$ARGS' -f '$TORRENT_DIR

	ARGS=$ARGS' -g '$CONFIG_DIR

	if test x$PORT_MAPPING == xenable
	then
		ARGS=$ARGS' -m'
	else
		ARGS=$ARGS' -M'
	fi

	ARGS=$ARGS' -p '$PORT
}

start()
{
	if test -f $PIDFILE
	then
		echo -n "Pidfile found! "
	else
		transmission-daemon -g $CONFIG_DIR -p $PIDFILE -s $SOCKET
		sleep 1
		chown $USER:$GROUP $SOCKET
		transmission-remote $ARGS
	fi
}

stop()
{
	if test ! -f $PIDFILE
	then
		echo -n "No pidfile found! "
	else
		transmission-remote -g $CONFIG_DIR -q
		while test -f $PIDFILE
		do
			sleep 1
			echo -n "."
		done
	fi
}

case $1 in
	start)
		echo -n "Starting torrent client: "
		config
		build
		start
		echo "transmission-daemon."
		;;
	stop)
		echo -n "Stopping torrent client: "
		config
		stop
		echo "transmission-daemon."
		;;
	restart)
		echo -n "Stopping torrent client: "
		config
		stop
		echo "transmission-daemon."
		echo -n "Starting torrent client: "
		build
		start
		echo "transmission-daemon."
		;;
	*)
		echo "Usage: $0 start|stop|restart"
		;;
esac

