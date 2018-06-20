#!/usr/bin/env bash

######################################
# desc: spring boot start script
# use: see spring-boot.sh
# author: hesimincn@gmail.com
# version: 0.1
######################################


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
    export JAVA_OPTIONS="-Xmx${heap_size}m $JAVA_OPTIONS"
    echo JAVA_OPTIONS=${JAVA_OPTIONS}
fi

source ./spring-boot.sh
