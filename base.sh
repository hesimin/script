#!/usr/bin/env bash
    
# ++++++++++++++++++++++++++++++++++++
# desc: 
# use:
# 
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

function echo_red(){
    echo -e  "${RED_COLOR}${@:1}${RES}"
}

function echo_yellow(){
    echo -e  "${YELLOW_COLOR}${@:1}${RES}"
}

# +++++++++++++++ 定义变量 +++++++++++++++
log_dir=/var/log

# 参数处理
ARGS=`getopt -o c: --long check: -n 'spring-boot.sh' -- "$@"`
if [ $? != 0 ]; then
    echo_red "the getopt has error，Terminating..."
    exit 1
fi
#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"
while true
do
    case "$1" in
        -c|--check)
            CHECK_CMD=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo_red "Options error!"
            echo_red "<<<<<<<<<<<<<<  Unsupported options: $1  !!!!!!!!!"
            exit 1
            ;;
    esac
done

# +++++++++++++++ 目录创建 +++++++++++++++
[ ! -d ${log_dir} ] && mkdir -p ${log_dir}
