#!/bin/bash

CMD_OUTPUT_DEST="/dev/null"
STATHAT_UPDATE_INTERVAL=15
#ETCD_UPDATE_INTERVAL=3
#GRNDS_METRICS_DIR='/grnds/metrics'
STATHAT_METRICS_PREFIX='host'

declare -A g_metrics

echo "frequently noisy output is going to ${CMD_OUTPUT_DEST}"

define()
{
    IFS='\n' read -r -d '' ${1} || true
}

update_metrics()
{
    g_metrics[load1]=$(cat /proc/loadavg | cut -f1 -d' ')
    g_metrics[load5]=$(cat /proc/loadavg | cut -f2 -d' ')
    g_metrics[load15]=$(cat /proc/loadavg | cut -f3 -d' ')

    if cat /proc/meminfo | grep -q MemAvailable ; then
        g_metrics[memavailable]=$(($(cat /proc/meminfo | grep MemAvailable | cut -d: -f2 | tr -d 'kB' | tr -d ' ') * 1024))
    else
        g_metrics[memavailable]=0
    fi

    g_metrics[memfree]=$(($(cat /proc/meminfo | grep MemFree | cut -d: -f2 | tr -d 'kB' | tr -d ' ') * 1024))
    g_metrics[memtotal]=$(($(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | tr -d 'kB' | tr -d ' ') * 1024))
    g_metrics[diskfree_root]=$(df -B1 / | tail -1 | awk '{print $4}')

    if df -B1 /dev/xvdh ; then
        g_metrics[diskfree_xvdh]=$(df -B1 /dev/xvdh | tail -1 | awk '{print $4}')
    else
        g_metrics[diskfree_xvdh]=0
    fi

    g_metrics[ncpus]=$(cat /proc/cpuinfo | grep processor | wc -l)

    #echo "load: ${g_metrics[load1]} ${g_metrics[load5]} ${g_metrics[load15]}  memfree: ${g_metrics[memfree]}B  diskfree: ${g_metrics[diskfree]}GB"
}

send_stathat_metrics()
{
    echo "sending metrics to StatHat every ${STATHAT_UPDATE_INTERVAL}s"

    while true; do
        update_metrics

        define JSON <<EOF
{
    "ezkey": "${STATHAT_EZ_KEY}",
    "data": [
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME load1", "value": ${g_metrics[load1]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME load5", "value": ${g_metrics[load5]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME load15", "value": ${g_metrics[load15]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME ncpus", "value": ${g_metrics[ncpus]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME memavailable", "value": ${g_metrics[memavailable]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME memfree", "value": ${g_metrics[memfree]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME memtotal", "value": ${g_metrics[memtotal]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME diskfree /", "value": ${g_metrics[diskfree_root]}},
        {"stat": "$STATHAT_METRICS_PREFIX $METRICS_HOSTNAME diskfree /dev/xvdh", "value": ${g_metrics[diskfree_xvdh]}}
    ]
}
EOF

        echo "sending metrics to StatHat"
        JSON=`echo $JSON | tr '\n' ' '`
        #echo "curl -s -X POST -H \"'Content-Type: application/json'\" https://api.stathat.com/ez -d\"'$JSON'\" > $CMD_OUTPUT_DEST"
        eval curl -s -H "'Content-Type: application/json'" -d"'$JSON'" -X POST https://api.stathat.com/ez > $CMD_OUTPUT_DEST

        sleep $STATHAT_UPDATE_INTERVAL
    done
}

#send_etcd_metrics()
#{
    #echo "sending metrics to etcd every ${ETCD_UPDATE_INTERVAL}s"

    #while true; do
        #update_metrics

        #define JSON <<EOF
#{
    #"memfree": ${g_metrics[memfree]},
    #"memavailable": ${g_metrics[memavailable]},
    #"memtotal": ${g_metrics[memtotal]},
    #"diskfree": ${g_metrics[diskfree]},
    #"load1": "${g_metrics[load1]}",
    #"load5": "${g_metrics[load5]}",
    #"load15": "${g_metrics[load15]}",
    #"ncpus": ${g_metrics[ncpus]}
#}
#EOF

        #JSON=`echo $JSON | tr '\n' ' ' | sed -e 's/ +/ /g'`
        ##echo "etcdctl set --ttl 60 /grnds/metrics/$MACHINE_ID \"$JSON\" > $CMD_OUTPUT_DEST"
        #etcdctl set --ttl 60 $GRNDS_METRICS_DIR/$MACHINE_ID "$JSON" > $CMD_OUTPUT_DEST

        #sleep $ETCD_UPDATE_INTERVAL
    #done
#}

main()
{
    #echo etcdctl mkdir $GRNDS_METRICS_DIR
    #etcdctl mkdir $GRNDS_METRICS_DIR

    send_stathat_metrics &
    #send_etcd_metrics &

    while true; do
        sleep 1
    done
}

main
