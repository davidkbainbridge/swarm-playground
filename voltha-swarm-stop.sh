#!/bin/bash

#docker service rm netconf_netconf
#docker service rm cli_cli
#docker service rm voltha_voltha
#docker service rm ofagent_ofagent
#docker service rm vcore_vcore
#docker service rm tools
#docker stack rm consul
#docker stack rm kafka
#docker stack rm fluentd
#docker stack rm onos
#docker network rm voltha_net

GREEN='\033[32;1m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

SERVICES="netconf_netconf cli_cli voltha_voltha ofagent_ofagent vcore_vcore tools"
STACKS="consul kafka fluentd onos"
NETWORKS="voltha_net"

for s in $SERVICES; do
    echo -n "[service] $s ... "
    if [ $(docker service ls | grep $s | wc -l) -ne 0 ]; then
        OUT=$(docker service rm $s 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}removed${NC}"
        else
            echo -e "${RED}ERROR: $OUT${NC}"
        fi
    else
        echo -e "${WHITE}not found${NC}"
    fi
done

for s in $STACKS; do
    echo -n "[stack] $s ... "
    if [ $(docker stack ls | grep $s | wc -l) -ne 0 ]; then
        OUT=$(docker stack rm $s 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}removed${NC}"
        else
            echo -e "${RED}ERROR: $OUT${NC}"
        fi
    else
        echo -e "${WHITE}not found${NC}"
    fi
done

for n in $NETWORKS; do
    echo -n "[network] $n ... "
    if [ $(docker network ls | grep $n | wc -l) -ne 0 ]; then
        OUT=$(docker network rm $n 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}removed${NC}"
        else
            echo -e "${RED}ERROR: $OUT${NC}"
        fi
    else
        echo -e "${WHITE}not found${NC}"
    fi
done
