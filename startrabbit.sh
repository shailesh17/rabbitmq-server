#!/bin/bash

change_default_user() {
	
	if [ -z $RABBITMQ_DEFAULT_USER ] && [ -z $RABBITMQ_DEFAULT_PASS ]; then
		echo "Maintaining default 'guest' user"
	else 
		echo "Removing 'guest' user and adding ${RABBITMQ_DEFAULT_USER}"
		rabbitmqctl delete_user guest
		rabbitmqctl add_user $RABBITMQ_DEFAULT_USER $RABBITMQ_DEFAULT_PASS
		rabbitmqctl set_user_tags $RABBITMQ_DEFAULT_USER administrator
		rabbitmqctl set_permissions -p / $RABBITMQ_DEFAULT_USER ".*" ".*" ".*"
	fi
}

HOSTNAME=`env hostname`

echo "Starting rabbitMQ server..."

if [ -z "$CLUSTERED" ]; then
	# if not clustered then start it normally as if it is a single server
	/usr/sbin/rabbitmq-server &
    echo "Started rabbitMQ pid file is /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid"
	rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
	change_default_user	
    echo "tailing tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log"
	tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
else
	if [ -z "$CLUSTER_WITH" ]; then
		# If clustered, but cluster with is not specified then again start normally, could be the first server in the
		# cluster
		/usr/sbin/rabbitmq-server&
        echo "Started rabbitMQ CLUSTERED pid file is /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid"
		rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
        echo "tailing tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log"
		tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
	else
		/usr/sbin/rabbitmq-server &
        echo "Started rabbitMQ CLUSTER_WITH mode... pid file is /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid"
		rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
		rabbitmqctl stop_app
		if [ -z "$RAM_NODE" ]; then
			rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
		else
			rabbitmqctl join_cluster --ram rabbit@$CLUSTER_WITH
		fi
		rabbitmqctl start_app
                
		# Tail to keep the a foreground process active..
        echo "tailing tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log"
		tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
	fi
fi
