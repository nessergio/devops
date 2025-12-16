#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Syntax: $0 <action>" 
    echo "Possible actions: up, down"
    exit 1
fi
N=$(docker ps | grep service-a | wc -l)
case $1 in
  up)
    if [ $N -lt 10 ]; then ((N++)); fi
    ;;
  down)
    if [ $N -gt 1 ]; then ((N--)); fi
    ;;
  *)
    echo "unknown action"
    exit 1
    ;;
esac
docker compose up service-a --scale service-a=$N -d
echo $N