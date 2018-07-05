#!/usr/bin/env bash
    
# ++++++++++++++++++++++++++++++++++++
# desc: 
# use:
# 
# author: hesimincn@gmail.com
# version: 0.1
# ++++++++++++++++++++++++++++++++++++

conf_dir=/opt/consul/conf
mkdir -p ${conf_dir}

svrnodes=(
192.168.51.149
192.168.51.155
192.168.51.153
)
privIP=$(ip addr show dev ${network_dev_name} | sed -n 's/.*inet \(addr:\)\?\([0-9.]\{7,15\}\)\/.*/\2/p')
consul_ver=1.2.0
retry_interval=15s
contain_cli_name=consul_client

if [[ "${svrnodes[@]}" =~ $privIP ]];
then
    echo -e "Current node:${privIP} is configured for server consul, not to run client mode.\n"
    exit
fi

svr_runing=$(docker ps -a | grep "${contain_cli_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} != "" ]];
then
    echo -e "Current container of consul client has been running.\n"
    exit
else
    svr_exists=$(docker ps -a | grep "${contain_cli_name}")
    if [[ ${svr_exists} != "" ]];
    then
        echo -e "Now try to start the container as it stopped...\n"
        docker start ${svr_exists}
        sleep 2
        docker ps -a grep "${contain_cli_name}"
        exit
    fi
fi

echo -e "To start a new container for consul...\n"
echo -e "To initialize configuration...\n"

nodels=""
for host in ${svrnodes[*]}
do
    if [[ $nodels != "" ]];
    then
        nodels=$nodels,
    fi
    nodels=$nodels"\"$host\""
done

config="{\n
\"retry_join\": [${nodels}],\n
\"retry_interval\": \"${retry_interval}\",\n
\"rejoin_after_leave\": true,\n
\"start_join\": [${nodels}],\n
\"server\": false,\n
\"ui\": true,\n
\"node_name\": \"$HOSTNAME\"\n
}\n"

echo $config
echo -e ${config} > ${conf_dir}/client.json
echo -e ${config}

docker run -d -v ${conf_dir}:${conf_dir} \
    --name ${contain_cli_name} \
    --net=host consul:${consul_ver} agent \
    -config-dir=${conf_dir} \
    -client=0.0.0.0 \
    -advertise=${privIP}

sleep 2

svr_runing=$(docker ps -a | grep "${contain_cli_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} == "" ]];
then
    echo -e "\nError: docker-consul client node failed to start...\n"
    exit
fi
echo -e "\nOK: docker-consul has started as a client node.\n"
