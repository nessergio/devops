#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Syntax: $0 <action>" 
    echo "Possible actions: container-up, container-down, worker-up, worker-down"
    exit 1
fi

docker exec -i $(docker ps -qf "name=stack-prometheus-alertmanager-1") \
  amtool --alertmanager.url=http://localhost:9093/ \
    alert add alertname="test" severity="critical" \
    job="test-alert" instance="$1" doaction="true" action="$2"
