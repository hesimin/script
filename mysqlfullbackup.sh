#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Script：                                                               +
#      mysqlfullbackup.sh                                                 +
#                                                                         +
#  Description：                                                          +
#      using mysqldump command to backup the database.                    +
#                                                                         +
#  Author:                                                                +
#      WuJianJian, DBA Leader,2017.06.01                                  +
#                                                                         +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 0.初始化颜色设置
RED_COLOR='\E[1;31m'   #红
GREEN_COLOR='\E[1;32m' #绿
YELOW_COLOR='\E[1;33m' #黄
BLUE_COLOR='\E[1;34m'  #蓝
PINK='\E[1;35m'        #粉红
RES='\E[0m'            #关闭

function echo_red(){
    echo -e  "${RED_COLOR}${@:1}${RES}"
}

function echo_green(){
    echo -e  "${GREEN_COLOR}${@:1}${RES}"
}

function echo_yelow(){
    echo -e  "${YELOW_COLOR}${@:1}${RES}"
}

function echo_blue(){
    echo -e  "${BLUE_COLOR}${@:1}${RES}"
}

function echo_pink(){
    echo -e  "${PINK}${@:1}${RES}"
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 1.定义变量
mysqlcommand=/usr/local/mysql/bin/mysql
backupcommand=/usr/local/mysql/bin/mysqldump
binlogcommand=/usr/local/mysql/bin/mysqlbinlog
backuphost=localhost
backupuser=dbbackup
backuppwd=dbbackuppwd
backupport=3306
backupdbs=`$mysqlcommand -h $backuphost -u $backupuser -p$backuppwd -P $backupport -e "show databases"|grep -Ev "Database|information_schema|performance_schema|mysql|test|sys"`
backupdir=/data/mysqlbackup
backupbinlogdir=/data/mysqlbackup/binlogs
logdir=/data/mysqlbackup/logs
backuptime=`date +%Y%m%d`
mkdircommand=`which mkdir`
findcommand=`which find`
pvcommand=`which pv`
gzipcommand=`which gzip`
cpcommand=`which cp`
binlogdir=/data/mysql/mysql3306/logs


# 2.判断目录存在与否
[ ! -d $backupdir ] && $mkdircommand -p $backupdir
[ ! -d $logdir ] && $mkdircommand -p $logdir

# 3. 删除过期备份，默认只保留7天
$findcommand $backupdir -name "*.gz" -type f -mtime +7 |xargs rm -rf

# 4.全备,pv限流,并且压缩
for db in $backupdbs
do
  echo -e "${BLUE_COLOR}${db}${RES} database backup beginning at $(date +"%Y-%m-%d %H:%M:%S")." >>$logdir/mysqlfullbackup.log
  $backupcommand -h $backuphost -u $backupuser -p$backuppwd -P $backupport $db --single-transaction --master-data=2 --flush-logs -R -E --add-drop-database --opt --set-gtid-purged=OFF | $pvcommand -q -L 10M| $gzipcommand -9 > $backupdir/$db.$backuptime.gz
  if [ $? -eq 0 ];then
    echo -e "${BLUE_COLOR}${db}${RES} database backup ${YELOW_COLOR}successfully${RES} ending at $(date +"%Y-%m-%d %H:%M:%S")." >>$logdir/mysqlfullbackup.log
  else
    echo_red "$db database backup failed !!!" >>$logdir/mysqlfullbackup.log
  fi
done

# 5.binlog 增备
cd $binlogdir
binlogs=`cat mysql-bin.index`
lognums=`cat mysql-bin.index|wc -l`
counter=0
for logfile in $binlogs
do
  binlogname=`basename $logfile`
  counter=$(expr $counter + 1)
  if [ $counter -eq $lognums ];then
    `$mysqlcommand -h $backuphost -u $backupuser -p$backuppwd -P $backupport -e "purge binary logs before date(now() - interval 1 day)"`
    echo_yelow "Skip the lastest binlog file $binlogname !!!" >/dev/null
  else
    existlogfile=$backupbinlogdir/$binlogname
    if [ -e $existlogfile ];then
      echo_green "The binlog file $binlogname already backuped !!!" >/dev/null
    else
     $cpcommand $binlogname $backupbinlogdir
     if [ $? -eq 0 ];then
       echo -e "Backup mysql binlog file ${BLUE_COLOR}${binlogname}${RES} ${YELOW_COLOR}successfully${RES} at $(date +"%Y-%m-%d %H:%M:%S")." >>$logdir/mysqlfullbackup.log
     else
       echo_red "Backup mysql binlog file $binlogname failed !!!" >>$logdir/mysqlfullbackup.log
     fi
    fi
  fi
done
echo "" >>$logdir/mysqlfullbackup.log