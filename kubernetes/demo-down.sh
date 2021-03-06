#!/bin/bash 
#
# Script to stop all the pieces of the cassandra cluster demo with opscenter
#
#-------
# some best practice stuff
unset CDPATH
VERSION="1.0"
function usage
{
    echo "Stops cassandra cluster and opscenter"
    echo ""
    echo "Usage:"
    echo "   demo-down.sh [flags]"
    echo ""
    echo "Flags:"
    echo "  -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "demo-down.sh version $VERSION"
}
#
echo " "
echo "=================================================="
echo "   Attempting to Stop and Delete the"
echo "   Cassandra/Opscenter Kubernetes Demo"
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# process args
#
CLUSTER_LOC="local"
TMP_LOC=$CLUSTER_LOC
while [ "$1" != "" ]; do
    case $1 in
        -c | --cluster )
            shift
            TMP_LOC=$1
            ;;
        -v | --version )
            version
            exit
            ;;
        -h | -? | --help )
            usage
            exit
            ;;
         * )
             usage
             exit 1
    esac
    shift
done
if [ -z "$TMP_LOC" ];then
    echo ""
    echo "ERROR No Cluster Supplied."
    echo ""
    usage
    exit 1
else
    CLUSTER_LOC=$TMP_LOC
fi
echo "Using Kubernetes cluster: $CLUSTER_LOC"
#
# check to see if kubectl has be configured
#
echo " "
echo "Locating kubectl and .kubeconfig..."
SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
cd ${SCRIPTPATH}
DEVBASE=${SCRIPTPATH%/cassandra-container/kubernetes}
echo "DEVBASE ${DEVBASE}"
#
# locate projects...
#
KRAKENDIR=`find ${DEVBASE} -type d -name "kraken" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find the Kraken project."
    exit 1
else
    echo "found: $KRAKENDIR"
fi
#KUBECONFIG=`find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC} -type f -name ".kubeconfig" -print | egrep '.*'`
#if [ $? -ne 0 ];then
#    echo "Could not find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC}/.kubeconfig"
#    exit 1
#else
#    echo "found: $KUBECONFIG"
#fi

KUBECTL=`find /opt/kubernetes/platforms/darwin/amd64 -type f -name "kubectl" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find kubectl."
    exit 1
else
    echo "found: $KUBECTL"
fi

#kubectl_local="/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig"
#kubectl_local="${KUBECTL} --kubeconfig=${KUBECONFIG}"
kubectl_local="${KUBECTL} --cluster=${CLUSTER_LOC}"

CMDTEST=`$kubectl_local version`   
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running?"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
echo "+++++ stopping cassandra services ++++++++++++++++++++++++++++"
$kubectl_local delete services opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Opscenter service already down"
else
    echo "Opscenter service deleted"
fi
$kubectl_local delete services cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra service already down"
else
    echo "Cassandra service deleted"
fi
echo " "
echo "Remaining Services List:"
$kubectl_local get services
echo " "
echo "+++++ stopping cassandra pods ++++++++++++++++++++++++++++"
$kubectl_local resize --replicas=0 rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra pods already down"
else
    echo "Cassandra pods deleted"
fi
$kubectl_local delete rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra Replication Controller already down"
else
    echo "Cassandra Replication Controller deleted"
fi
echo " "
echo "Remaining Replication Controllers:"
$kubectl_local get rc
echo " "
$kubectl_local delete pods opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Opscenter pods already down"
else
    echo "Opscenter pods deleted"
fi
echo " "
echo "Remaining Pods:"
$kubectl_local get pods
echo " "
echo "+++++ cassandra stopped and deleted from Kubernetes ++++++++++++++++++++++++++++"
