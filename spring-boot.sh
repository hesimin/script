#!/bin/bash

######################################
# desc: spring boot start script
# use:
# ./spring-boot start xxx.jar
# ./spring-boot -c "curl --silent --fail http://localhost:12001" start xxx.jar
# author: hesimincn@gmail.com
# version: 0.3
######################################

echo ">>>>>>>>>>>>>>>>>  spring-boot.sh  >>>>>>>>>>>>>>>>"

CURR_DIR=`pwd`
echo "[info] current dir： ${CURR_DIR}"

ARGS=`getopt -o c: --long check: -n 'spring-boot.sh' -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
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
            echo "Options error!"
            exit 1
            ;;
    esac
done


export JAVA_HOME=/usr/local/jdk1.8
export PATH=${JAVA_HOME}/bin:$PATH
export CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar

JAVA_OPTIONS=" -Xms300M -Xmx300M  -XX:+HeapDumpOnOutOfMemoryError "

_JAR_KEYWORDS=" $2"
if [ ! -f ${_JAR_KEYWORDS} ];then
  echo "<<<<<<<<<<<<<<  ${_JAR_KEYWORDS} file not exist !!!!!!! " >&2
  exit 1
fi
#NAME=${APP_JAR%.*}
_JAR_NAME=`echo "$_JAR_KEYWORDS"|grep -oP '[^/| ]+\.(jar)'`
APP_NAME=$2

JAVA_CMD="-jar $JAVA_OPTIONS $_JAR_KEYWORDS"

echo "[info] java_home= $JAVA_HOME"
echo `java -version`
echo "[info] running >  `ps aux | grep ${_JAR_NAME} |grep java`"
echo "[info] JAVA_CMD >   $JAVA_CMD  "

function fun_get_pid {
 PID=$(ps aux | grep ${_JAR_NAME} |grep java| grep -v grep | awk '{print $2}' )
}

function fun_check_running {
 if [ -n "$CHECK_CMD" ]; then
     CHECK_RESULT=`eval ${CHECK_CMD}`
     if [ -n "$CHECK_RESULT" ]; then
         echo -e "\nCHECK_RESULT:\n ${CHECK_RESULT}"
         return 0
     else
         return 1
     fi
 fi

 CHECK_RUNNING_PID=true
 fun_check_running_pid
}

function fun_check_running_pid {
 fun_get_pid
 if [ "$PID" = "" ]; then
   return 1
 else
   return 0
 fi
}

function fun_stop {
    fun_get_pid
    if [ -n "$PID" ]; then
        kill  ${PID}
    else
        return 0
    fi

    echo -ne "Waiting for process to stop: $PID "
    for i in {1..20}; do
        if fun_check_running_pid; then
          echo -ne ". "
          sleep 1
        else
          return 0
        fi
    done

    if fun_check_running_pid; then
     echo -e "Cannot kill process, using kill -9 $PID "
     kill -9 ${PID}
    fi
    for i in {1..10}; do
        if fun_check_running_pid; then
          echo -ne ". "
          sleep 1
        else
          return 0
        fi
    done

    if fun_check_running_pid; then
       echo -e "<<<<<<<<<<<<<<  Cannot stop process  !!!!!!!!!" >&2
       exit 1
    fi
}


case "$1" in
  status)
    if fun_check_running
    then
      echo -e "$APP_NAME is running "
    else
      echo -e "$APP_NAME not running "
    fi
    ;;
  stop)
    if ! fun_check_running_pid
    then
      echo  -e "$APP_NAME  already stopped "
      exit 0
    fi
    fun_stop
    ;;
  start)
    if fun_check_running_pid
    then
      fun_stop
    fi

    nohup java ${JAVA_CMD} >/dev/null 2>&1 &

    echo
    echo -ne "Starting. "
    for i in {1..60}; do
      if ! fun_check_running; then
          echo -ne ". "
          sleep 1
      elif [[ ${CHECK_RUNNING_PID} && ${i} -lt 20 ]] ; then #pid检测的方式，需要等一段时间确认是否启动失败，此不准确
          echo -ne ". "
          sleep 1
      else
          break
      fi
    done

    echo
    if fun_check_running
    then
       echo  -e "<<<<<<<<<<<<<<  $APP_NAME start success ========="
    else
       echo  -e "<<<<<<<<<<<<<<  $APP_NAME  start fail !!!!!!!!!!!" >&2
       exit 1
    fi
    ;;
  restart)
    $0 stop
    if [ $? = 1 ]
    then
      exit 1
    fi
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
esac

exit 0
