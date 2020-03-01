#!/bin/bash

# 第一次安装时初始化
function deploy_tomcat(){
    echo '正在执行部署 jenkins 环境'
    ls /opt/deploy
    # 解压组件
    mkdir -p /tomcat
    # 不管是什么样版本的tomcat,在这里统统命名为 tomcat
    tar -xvf /opt/deploy/*tomcat*.tar.gz -C /tomcat --strip-components 1

}

# 启动tomcat和nginx
function startup(){
    nginx &&
    # 启动tomcat
    bash /tomcat/bin/startup.sh &&

    tail -f /tomcat/logs/catalina.out
}

# 安装必要的组件
function instll_component(){
    # 更换apt-get源
    mv /opt/deploy/sources.list /etc/apt/sources.list &&

    # 更新源
    apt-get update &&

    # 安装nginx 和其他的组件
    apt-get install -y git curl nginx &&  rm -rf /var/lib/apt/lists/*

    # 替换nginx 配置文件
    cp /opt/deploy/nginx.conf /etc/nginx/ 

    ## 检查nginx 是否正常 
    nginx -t 

    # 添加hosts解析
    echo '127.0.0.1 updates.jenkins-ci.org' >> /etc/hosts
}

# 校验版本是否发生改变
function check_sum(){
    
    if [ ! -f "/opt/jenkins/jenkins.war" ];then
        # 如果不存在的话,证明没有发生版本变更
        return true
    fi

    if [ `cat /opt/deploy/jenkins.md5` = `md5sum /opt/jenkins/jenkins.war | awk '{print$1}'` ];then
       return true
    fi
    return false
}

# 重新装载版本
function reload(){
    # 清除不必要的项目
    rm -rf /tomcat/webapps/*
    # 将jenkins 添加到到tomcat容器中
    mkdir -p /tomcat/webapps/ROOT &&  cd /tomcat/webapps/ROOT  && jar -xvf /opt/deploy/jenkins.war &&
    # 给tomcat的执行文件赋予执行权限
    chmod +x /tomcat/bin/*.sh 
    # 计算当前这个包的md5
    md5sum /opt/deploy/jenkins.war | awk '{print$1}' > jenkins.md5
    # 清除发布的版本
    rm -rf /opt/jenkins/jenkins.war
}


if [ -d "/tomcat" ];then
    # 已经初始化过了
    echo '重新启动'
    if [ ! check_sum ];then
        # 版本发生了更新
        reload
    fi
    startup
else
    # 第一次初始化
    echo '这是第一次初始化'
    instll_component
    deploy_tomcat
    reload
    startup
fi