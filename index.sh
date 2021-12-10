#!/bin/bash

# Color
red_color="\e[31m"
green_color="\e[32m"

# Version
GO_VERSION=1.17.4
NODEJS_VERSION=16.13.1
# CURL 进度显示
if curl --help | grep progress-bar >/dev/null 2>&1; then # $CURL_BAR
    CURL_BAR="--progress-bar";
fi

# 检测 root 权限
if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n${red_color}请使用root权限运行本脚本" 1>&2
  exit 1;
fi
# 检测 git
if ! command -v git >/dev/null 2>&1; then
  if ! command -v yum >/dev/null 2>&1; then
      yum -y install git
  else
      apt -y install git
  fi
fi

# GCC 检查
if ! command -v gcc >/dev/null 2>&1; then
    if command -v yum >/dev/null 2>&1; then
        yum -y install gcc gcc-c++
    else
        apt-get update
        apt-get -y install gcc g++
    fi
fi

# 安装 golang
echo -e "\r\n${green_color} 安装Go …"
curl -L https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz -o /tmp/go$GO_VERSION.linux-amd64.tar.gz $CURL_BAR
tar -zxvf /tmp/go$GO_VERSION.linux-amd64.tar.gz -C /tmp/go/
mkdir /tmp/go/tmp
export PATH="/tmp/go/bin:$PATH"
export GOPATH="/tmp/go/tmp"

# 根据地域设置 GOPROXY 镜像源
if [ $isCN = "CN" ];then
    export GO111MODULE=on
    export GOPROXY="https://goproxy.cn"
fi

# 安装 nodejs
echo -e "\r\n${green_color} 安装NodeJS …"
if [ $isCN = "CN" ]; then
    curl -L https://npmmirror.com/mirrors/node/v$NODEJS_VERSION_VERSION/node-v$NODEJS_VERSION_VERSION-linux-x64.tar.xz -o /tmp/node-v$NODEJS_VERSION_VERSION-linux-x64.tar.xz $CURL_BAR
else
    curl -L https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION-linux-x64.tar.xz -o /tmp/node-v$NODEJS_VERSION-linux-x64.tar.xz $CURL_BAR
fi

tar xf /tmp/node-v$NODEJS_VERSION-linux-x64.tar.xz -C /tmp/
export PATH="/tmp/node-v$NODEJS_VERSION-linux-x64/bin:$PATH"

# 根据地域设置 npm 镜像源
if [ $isCN = "CN" ];then
    npm config set registry https://registry.npmmirror.com
fi

mkdir alist
cd ./alist
git clone https://github.com/Xhofe/alist
git clone https://github.com/Xhofe/alist-web
echo "* * */3 * * root sh bulid.sh" >> /var/spool/cron/root
sh bulid.sh