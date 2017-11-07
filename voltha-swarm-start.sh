#!/bin/bash

PROG=$(basename $0)
BASE_DIR=$(pwd)

GREEN='\033[32;1m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

usage() {
    echo >&2 "$PROG: [-d <dir>] [-h]"
    echo >&2 "  -d <dir>        directory in which the 'compose file directory' is located, defaults to '$(pwd)'"
    echo >&2 "  -h              this message"
}

wait_for_service() {
  while true
  do
      COUNT=$(docker service ls | grep $1 | awk '{print $4}')
      if [ ! -z "$COUNT" ]; then
          HAVE=$(echo $COUNT | cut -d/ -f1)
          WANT=$(echo $COUNT | cut -d/ -f2)
          if [ $WANT == $HAVE ]; then
            break
          fi
      fi
      sleep 2
  done
}

OPTIND=1
while getopts d:h OPT; do
    case "$OPT" in
        d) BASE_DIR="$OPTARG";;
        h) usage;
           exit 1;;
        esac
done

# Attempt to count Ready Docker Swarm managers
export SWARM_MANAGER_COUNT=$(docker node ls | grep Ready | egrep '(Leader)|(Reachable)' | wc -l)
hostName=$(hostname)

echo -n "[network] voltha-net ... "
if [ $(docker network ls | grep voltha_net | wc -l) -eq 0 ]; then
    OUT=$(docker network create --driver overlay --subnet=172.29.19.0/24 voltha_net 2>&1)
    #docker network create --driver overlay --subnet=172.29.19.0/24 --opt encrypted=true voltha_net
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: $OUT${NC}"
    else
        echo -e "${GREEN}created${NC}"
    fi
else
    echo -e "${WHITE}verified${NC}"
fi

docker stack deploy -c $BASE_DIR/compose/docker-compose-kafka-cluster.yml kafka
docker stack deploy -c $BASE_DIR/compose/docker-compose-consul-cluster.yml consul
echo -n "Waiting for consul to start ... "
wait_for_service consul_consul
echo -e "${GREEN}done${NC}"

echo -n "Waiting for consul leader election ... "
patience=10
while true
do
        leader=`curl -v http://${hostName}:8500/v1/status/leader 2>/dev/null | sed -e 's/"//g'`
        if [ ! -z "$leader" ] ; then
                echo -e "${GREEN}Leader elected is on ${leader}${NC}"
                break
        fi
        sleep 10
        patience=`expr $patience - 1`
        if [ $patience -eq 0 ]; then
                echo -e "${RED}Consul leader election taking too long... aborting${NC}"
                ./voltha-swarm-stop.sh
                exit 1
        fi
done

docker stack deploy -c $BASE_DIR/compose/docker-compose-fluentd-agg-cluster.yml fluentd

echo -n "Waiting for fluentd aggreation services to start ... "
wait_for_service fluentd_fluentdstby
wait_for_service fluentd_fluentdactv
echo -e "${GREEN}done${NC}"
sleep 2
docker stack deploy -c $BASE_DIR/compose/docker-compose-fluentd-cluster.yml fluentd
docker stack deploy -c $BASE_DIR/compose/docker-compose-onos-swarm.yml onos
docker stack deploy -c $BASE_DIR/compose/docker-compose-voltha-swarm.yml vcore
docker stack deploy -c $BASE_DIR/compose/docker-compose-ofagent-swarm.yml ofagent
docker stack deploy -c $BASE_DIR/compose/docker-compose-envoy-swarm.yml voltha
docker stack deploy -c $BASE_DIR/compose/docker-compose-vcli.yml cli
docker stack deploy -c $BASE_DIR/compose/docker-compose-netconf-swarm.yml netconf
echo -n "[service] tools ... "
if [ $(docker service ls | grep tools | wc -l) -eq 0 ]; then
    OUT=$(docker service create -d --name tools --network voltha_net  --network kafka_net --publish "4022:22" voltha/tools 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}created${NC}"
    else
        echo -e "${RED}ERROR: ${OUT}${NC}"
    fi
else
    echo -e "${WHITE}verified${NC}"
fi

