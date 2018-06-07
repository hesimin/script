#!/bin/bash

###########################
# desc: 当对docker容器进行资源限制时，获取限制值来做java的内存限制（java默认获取到的内存大小是宿主机的内存大小）
# author: hesimincn@gmail.com
# use: see spring-boot.sh
###########################


limit_in_bytes=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

# 预留内存
if [ ! ${RRESERVED_MEGABYTES} ]; then
	RESERVED_MEGABYTES=$(expr 150*1024*1024)
fi

# If not default limit_in_bytes in cgroup
if [ "$limit_in_bytes" -ne "9223372036854771712" ]
then
    limit_in_megabytes=$(expr ${limit_in_bytes} \/ 1048576)
    heap_size=$(expr ${limit_in_megabytes} - ${RSERVED_MEGABYTES})
    export JAVA_OPTS="-Xmx${heap_size}m $JAVA_OPTS"
    echo JAVA_OPTS=${JAVA_OPTS}
fi

source ./spring-boot.sh
