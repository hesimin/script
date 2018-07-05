#!/usr/bin/env bash
    
# ++++++++++++++++++++++++++++++++++++
# desc: 
# use:
# 
# author: hesimincn@gmail.com
# version: 0.1
# ++++++++++++++++++++++++++++++++++++

# script config
conf_dir=/opt/consul/conf
mkdir -p ${conf_dir}

nodes=(
192.168.51.149
192.168.51.155
192.168.51.153
)
network_dev_name=enp0s3
consul_ver=1.2.0
retry_interval=15s
contain_svr_name=consul_server
node_name=$HOSTNAME

# 获取网卡 eth0 的ip
privIP=$(ip addr show dev ${network_dev_name} | sed -n 's/.*inet \(addr:\)\?\([0-9.]\{7,15\}\)\/.*/\2/p')
echo -e "use ip of network dev:${privIP}\n"

#节点名不能重复，取ip最后一位做后缀
node_name=$node_name'-'`echo $privIP|awk -F '.' '{print $4;}' `

if [[ !("${nodes[@]}" =~ $privIP) ]];
then
    echo -e "Current node:${privIP} not in configured server nodes.\n"
    exit
fi

svr_runing=$(docker ps -a | grep "${contain_svr_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} != "" ]];
then
    echo -e "Current container of consul server has been running.\n"
    exit
else
    svr_exists=$(docker ps -a | grep "${contain_svr_name}")
    if [[ ${svr_exists} != "" ]];
    then
        echo -e "Now try to start the container as it stopped...\n"
        docker start ${svr_exists}
        sleep 2
        docker ps -a grep "${contain_svr_name}"
        exit
    fi
fi

echo -e "To start a new container for consul...\n"
echo -e "To initialize configuration...\n"

nodels=""
for host in ${nodes[*]}
do
    if [[ $nodels != "" ]];
    then
        nodels=$nodels,
    fi
    nodels=$nodels"\"$host\""
done

config="{\n
\"datacenter\": \"dctest\",\n
\"retry_join\": [${nodels}],\n
\"retry_interval\": \"${retry_interval}\",\n
\"rejoin_after_leave\": true,\n
\"start_join\": [${nodels}],\n
\"bootstrap_expect\": 3,\n
\"server\": true,\n
\"ui\": true,\n
\"dns_config\": {\"allow_stale\": true, \"max_stale\": \"5s\"},\n
\"node_name\": \"${node_name}\"\n
}\n"

echo $config
echo -e ${config} > ${conf_dir}/server.json
echo -e ${config}

docker run -d -v ${conf_dir}:${conf_dir} \
    --name ${contain_svr_name} \
    --net=host consul:${consul_ver} agent \
    -config-dir=${conf_dir} \
    -client=0.0.0.0 \
    -bind=${privIP} \
    -advertise=${privIP}

sleep 2

svr_runing=$(docker ps -a | grep "${contain_svr_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} == "" ]];
then
    echo -e "\nError: docker-consul failed to start...\n"
    exit
fi
echo -e "\nOK: docker-consul has started as background server.\n"
