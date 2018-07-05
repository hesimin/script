#!/usr/bin/env bash
    
# ++++++++++++++++++++++++++++++++++++
# desc: 
# use:
#     eg: ./consul.sh (server|client) --server_nodes=192.168.1.8,192.168.1.9 --network_dev_name=eth0
#     see the list of consul member: docker exec -it consul_server consul members
# author: hesimincn@gmail.com
# version: 0.1
# ++++++++++++++++++++++++++++++++++++

# +++++++++++++++ 初始化颜色设置 +++++++++++++++
RED_COLOR='\E[1;31m'   #红
GREEN_COLOR='\E[1;32m' #绿
YELLOW_COLOR='\E[1;33m' #黄
BLUE_COLOR='\E[1;34m'  #蓝
PINK='\E[1;35m'        #粉红
RES='\E[0m'            #关闭

function echo_err(){
    echo -e  "${RED_COLOR}[error] ${@:1}${RES}"
}

function echo_warn(){
    echo -e  "${YELLOW_COLOR}[warn] ${@:1}${RES}"
}

function echo_info(){
    echo -e  "${GREEN_COLOR}[info] ${@:1}${RES}"
}
function echo_base(){
    echo -e  "${@:1}"
}

# +++++++++++++++ 参数处理 +++++++++++++++
ARGS=`getopt -o h --long help,server_nodes::,network_dev_name:: -n '$0' -- "$@"`
if [ $? != 0 ]; then
    echo_err "the getopt has error，Terminating..."
    exit 1
fi
#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"
while true
do
    case "$1" in
        -h|--help)
            echo "option: server|client"
            shift
            ;;
        --server_nodes)
            arg_server_nodes=$2
            shift 2
            ;;
        --network_dev_name)
            arg_network_dev_name=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo_err "Options error!"
            echo_err "<<<<<<<<<<<<<<  Unsupported options: $1  !!!!!!!!!"
            exit 1
            ;;
    esac
done

arg_start_type=$1
#[ ${arg_start_type} == "server" ] && { is_server=true; echo_info "start type: server";} || { is_server=false; echo_info "start type: client";}
if [ "${arg_start_type}" == "server" ] ;then
    is_server=true;
    echo_info "start type: server";
elif [ "${arg_start_type}" == "client" ] ;then
    is_server=false;
    echo_info "start type: client";
else
    echo_err "arg error: server|client"
    exit 1
fi

# +++++++++++++++ 定义变量 +++++++++++++++
conf_dir=/opt/consul/conf

server_nodes=(
192.168.51.149
192.168.51.155
192.168.51.153
)
if [ -n "${arg_server_nodes}" ];then
   server_nodes=(${arg_server_nodes//,/ });
fi
# 网卡名
network_dev_name=enp0s3
if [ -n "${arg_network_dev_name}" ];then
   network_dev_name=${arg_network_dev_name};
fi
consul_ver=1.2.0
retry_interval=15s
node_name=$HOSTNAME
${is_server} && contain_name=consul_server || contain_name=consul_client

# 获取网卡 的ip
privIP=$(ip addr show dev ${network_dev_name} | sed -n 's/.*inet \(addr:\)\?\([0-9.]\{7,15\}\)\/.*/\2/p')
if [ -z "${privIP}" ]; then
    echo_err "Con't get to IP.(${network_dev_name})"
    exit 1
else
    echo_info "use ip of network dev(${network_dev_name}): ${privIP}"
fi

#节点名不能重复，取ip最后一位做后缀
node_name=${node_name}'-'`echo ${privIP}|awk -F '.' '{print $4;}' `

# +++++++++++++++ 目录创建 +++++++++++++++
[ ! -d ${conf_dir} ] && mkdir -p ${conf_dir}

# +++++++++++++++ 节点校验 +++++++++++++++
if ${is_server} ; then
    if [[ !("${server_nodes[@]}" =~ $privIP) ]];
    then
        echo_err "Current node:${privIP} not in configured server nodes.\n"
        exit 1
    fi
else
    if [[ "${server_nodes[@]}" =~ $privIP ]];
    then
        echo_err "Current node:${privIP} is configured for server consul, not to run client mode.\n"
        exit 1
    fi
fi

svr_runing=$(docker ps -a | grep "${contain_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} != "" ]];
then
    echo_err "Current container of ${contain_name} has been running.\n"
    exit
else
    svr_exists=$(docker ps -a | grep "${contain_name}")
    if [[ ${svr_exists} != "" ]];
    then
        echo_info "Now try to start the container as it stopped...\n"
        docker start ${svr_exists}
        sleep 2
        docker ps -a grep "${contain_name}"
        exit
    fi
fi

echo_info "To start a new container for consul...\n"
echo_info "To initialize configuration...\n"

nodels=""
for host in ${server_nodes[*]}
do
    if [[ $nodels != "" ]];
    then
        nodels=$nodels,
    fi
    nodels=$nodels"\"$host\""
done

if ${is_server} ; then
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
        --name ${contain_name} \
        --net=host consul:${consul_ver} agent \
        -config-dir=${conf_dir} \
        -client=0.0.0.0 \
        -bind=${privIP} \
        -advertise=${privIP}
else
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
        --name ${contain_name} \
        --net=host consul:${consul_ver} agent \
        -config-dir=${conf_dir} \
        -client=0.0.0.0 \
        -advertise=${privIP}
fi

sleep 2

svr_runing=$(docker ps -a | grep "${contain_name}" | egrep "Up [About]|[0-9]{1,}")
if [[ ${svr_runing} == "" ]];
then
    echo_err "\nError: docker-consul failed to start...contain_name:${contain_name}\n"
    exit
fi
echo_info "\nOK: docker-consul has started as background server.contain_name:${contain_name}\n"
