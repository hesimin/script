一、安装Jenkins

    docker run --name jenkins -d -p 8080:8080 -p 50000:50000 \
    -v /home/ucn/jenkins:/var/jenkins_home \
    -v /home/ucn/jenkins/.m2:/var/jenkins_home/.m2 \
    -v /usr/local/jdk1.8:/usr/local/jdk1.8 \
    -v /usr/local/maven3:/usr/local/maven3 \
    -v /usr/local/node:/usr/local/node \
    --restart=always \
    jenkins/jenkins:lts
    
然后进行 Jenkins 配置：JDK、maven、git ...

二、Jenkins 集成sonar 

1、sonar 安装

    docker-compose -f docker-compose-sonar.yml up -d

2、Jenkins 安装插件： SonarQube Scanner for Jenkins 

3、Jenkins 配置 SonarQube servers （系统管理->系统设置->SonarQube servers）

4、项目配置 sonar 扫描

在构建过程中添加 Execute SonarQube Scanner

Analysis properties：

    sonar.projectKey=uwarehouse  
    sonar.projectName=uwarehouse  
    sonar.projectVersion=1.0  
    sonar.sources=.  
    sonar.java.binaries=.  
    sonar.language=java  
    sonar.sourceEncoding=UTF-8  
    
或者
    
    # 多模块
    sonar.projectKey=uwarehouse  
    sonar.projectName=uwarehouse  
    sonar.projectVersion=$branchs  
    # Set modules IDs  
    sonar.modules=uwarehouse-controller,uwarehouse-service
    
    # Modules inherit properties set at parent level  
    sonar.sources=src/main/java  
    sonar.tests=src/test/java  
    sonar.java.binaries=target  
    sonar.language=java  