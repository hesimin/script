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

function echo_err(){
    echo -e  "${RED_COLOR}`date +'%F %T'` [error] ${@:1}${RES}"
}

function echo_warn(){
    echo -e  "${YELLOW_COLOR}`date +'%F %T'` [warn] ${@:1}${RES}"
}

function echo_info(){
    echo -e  "${GREEN_COLOR}`date +'%F %T'` [info] ${@:1}${RES}"
}
function echo_base(){
    echo -e  "${@:1}"
}
# +++++++++++++++ 参数处理 +++++++++++++++
#ARGS=`getopt -o ab:c:: --long along,blong:,clong:: -n 'example.sh' -- "$@"`
#-o或--options选项后面接可接受的短选项，如ab:c::，表示可接受的短选项为-a -b -c，其中-a选项不接参数，-b选项后必须接参数，-c选项的参数为可选的
#-l或--long选项后面接可接受的长选项，用逗号分开，冒号的意义同短选项。
#-n选项后接选项解析错误时提示的脚本名字
ARGS=`getopt -o h --long help -n "$0" -- "$@"`
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
            echo "help option"
            shift
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

# +++++++++++++++ 定义变量 +++++++++++++++
WORK_DIR=$(cd $(dirname $0); pwd)

log_dir=/var/log


# +++++++++++++++ 目录创建 +++++++++++++++
[ ! -d ${log_dir} ] && mkdir -p ${log_dir}

# +++++++++++++++ do +++++++++++++++
