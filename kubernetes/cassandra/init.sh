#!/bin/bash

# Setup Cassandra
CONFIG=/etc/cassandra/
IP=${LISTEN_ADDRESS:-`hostname --ip-address`}
#perl -pi -e "s/%%ip%%/$(hostname -I)/g" /etc/cassandra/cassandra.yaml
perl -pi -e "s/%%ip%%/$IP/g" $CONFIG/cassandra.yaml
#
# seems to be root:root at this point..needs to be cassandra:cassandra
#
chown cassandra:cassandra $CONFIG/cassandra.yaml

# Start Monitor Agent
#
# NOTE: opscenter MUST be running first so we can pull the IP of the container from the env vars...
#
# NOTE: assumes opcenter container is named opscenter
# TODO: make more generic based on ports alone
#
# NOTE: last sed creates a CSV list.. should never be needed here
#
STOMP=`env | grep OPSCENTER_PORT_61620_TCP_ADDR | sed 's/OPSCENTER_PORT_61620_TCP_ADDR=//g' | sed -e :a -e N -e 's/\n/,/' -e ta`
DCONFIG=/var/lib/datastax-agent/conf
if [ -n "$STOMP" ]; then
    echo "stomp_interface: $STOMP" | sudo tee -a $DCONFIG/address.yaml
fi
echo "local_interface: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "agent_rpc_interface: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "jmx_host: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "hosts: [ $IP ]" | sudo tee -a $DCONFIG/address.yaml
#
# seems to be root:root at this point..needs to be cassandra:cassandra
#
chown cassandra:cassandra $DCONFIG/address.yaml
#
# HACK HACK for kubernetes volumes.  createa a root:root (and may be shared), so no way to chown it.
# attempt this here, but not good in the long run
#
chown cassandra:cassandra /cassandra_data
#
# for custom kubernetes seed 
#
export CLASSPATH=/kubernetes-cassandra.jar

#
# debug env for kub...in case of sudden death
#
env | sort
#
ls -l /

echo "Starting Datastax Agent... stomp: $STOMP"
sudo service datastax-agent start

# Start Cassandra
# NOTE: this will hang in the foreground (-f) so the container does not go away...
echo Starting Cassandra...
cassandra -f -p /var/run/cassandra.pid
# just to lock up the container in case of a cassandra error
tail -f /var/log/lastlog
