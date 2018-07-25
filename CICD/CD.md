## 一、docker环境（CentOS）

//修改时区为上海  
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

//禁用seliunx  
vi /etc/selinux/config

//将SELINUX=enforcing改为SELINUX=disabled 重启机器即可  
//修改服务器hostName,这里修改成内网IP便于理解 xxx-xxx-xxx-xxx 不可以用"."  
hostnamectl --static set-hostname

//关闭firewall  
//停止firewall  
systemctl stop firewalld.service

//禁止firewall开机启动  
systemctl disable firewalld.service

//查看默认防火墙状态（关闭后显示notrunning，开启后显示running）  
firewall-cmd --state

//创建docker软链接,映射数据盘,系统默认空间是不足的。  
cd /data/ mkdir docker ln -s /data/docker /var/lib/docker

//安装docker  
https://docs.docker.com/install/linux/docker-ce/centos/

//增加docker国内镜像加速站点与私有镜像库地址,json格式{}  
vi /etc/docker/daemon.json

//增加"registry-mirrors": ["https://registry.docker-cn.com"]  
//增加http方式镜像库  
vi /etc/docker/daemon.json

//增加"insecure-registries":["你镜像库的IP:你镜像库的端口"]  
//添加完成如下,重启docker生效  
//{"registry-mirrors": ["https://registry.docker-cn.com"],"insecure-registries":["192.168.51.200:5000"]}  
service docker restart

//docker环境交付完毕

## 二、交付私有镜像库
docker run -d -p 5000:5000 --name registry registry:2

//拉取一个nginx镜像测试推送至私有镜像库
docker pull nginx

//docker tag 地址:端口/名称:版本
docker tag nginx 192.168.51.200:5000/nginx:test

docker push 192.168.51.200:5000/nginx:test

//推送完毕代表镜像库已经交付

## 三、docker集群管理

docker swarm mode、k8s