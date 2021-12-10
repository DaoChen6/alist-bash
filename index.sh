#!/bin/bash

# Color
red_color="\e[31m"
green_color="\e[32m"
default_color="\e[0m"

# Version
GO_VERSION=1.17.4
NODEJS_VERSION=16.13.1

# CURL 进度显示
if curl --help | grep progress-bar >/dev/null 2>&1; then # $CURL_BAR
    CURL_BAR="--progress-bar";
fi

# The temp directory must exist
if [ ! -d "/tmp" ];then
    mkdir -p /tmp
fi

remind='\e[34m
==========================================================================
\r\n                        Alist 一键部署脚本\r\n
  Alist是一款阿里云盘的目录文件列表程序，后端基于golang最好的http框架gin\r
  前端使用vue和ant design\r  项目地址：https://github.com/Xhofe/alist\r\n
                                        Script by 道辰 www.iflm.ml\r\n
==========================================================================
\e[0m';

echo -e ${remind}
# 检测 root 权限
if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n${red_color}请使用root权限运行本脚本" 1>&2
  exit 1;
fi

# 获取公网IP
ip_info=`curl -s https://ip.cooluc.com`;
if [[ $disable_mirror = "yes" ]];then
    isCN=NULL
else
    isCN=`echo $ip_info | grep -Po 'country_code\":"\K[^"]+'`;
fi
myip=`echo $ip_info | grep -Po 'ip\":"\K[^"]+'`;

# Github 镜像
if [ $isCN = "CN" ];then
    ping -c 2 github.com.cnpmjs.org > /dev/null 2>&1
    if [ $? -eq 0 ];then
        mirror="https://github.com.cnpmjs.org"
    else
        mirror="https://github.com"
    fi
else
    mirror="https://github.com"
fi

# 检测 git
if ! command -v git >/dev/null 2>&1; then
  if command -v yum >/dev/null 2>&1; then
      yum -y install git
  else
      apt-get update
      apt-get -y install git
  fi
fi

# 根据地域设置 GitHub 代理
if [ $isCN = "CN" ];then
    if [ -f "/root/.gitconfig" ];then
        mv -f /root/.gitconfig /root/.gitconfig.bak >/dev/null 2>&1
    fi
    git config --global url.$mirror.insteadof https://github.com
    echo -e "\r\n${green_color}正在设置临时 GitHub 代理 ...${default_color}"
    cat /root/.gitconfig
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
echo -e "\r\n${green_color} 正在安装Go … ${default_color}"
curl -L https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz -o /tmp/go$GO_VERSION.linux-amd64.tar.gz $CURL_BAR
tar -zxvf /tmp/go$GO_VERSION.linux-amd64.tar.gz -C /tmp/
mkdir -p /tmp/go/tmp
export PATH="/tmp/go/bin:$PATH"
export GOPATH="/tmp/go/tmp"

# 根据地域设置 GOPROXY 镜像源
if [ $isCN = "CN" ];then
    export GO111MODULE=on
    export GOPROXY="https://goproxy.cn"
fi

# 安装 nodejs
echo -e "\r\n${green_color} 正在安装NodeJS … ${default_color}"
if [ $isCN = "CN" ]; then
    curl -L https://npmmirror.com/mirrors/node/v$NODEJS_VERSION/node-v$NODEJS_VERSION-linux-x64.tar.xz -o /tmp/node-v$NODEJS_VERSION-linux-x64.tar.xz $CURL_BAR
else
    curl -L https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION-linux-x64.tar.xz -o /tmp/node-v$NODEJS_VERSION-linux-x64.tar.xz $CURL_BAR
fi

tar xf
 /tmp/node-v$NODEJS_VERSION-linux-x64.tar.xz -C /tmp/
export PATH="/tmp/node-v$NODEJS_VERSION-linux-x64/bin:$PATH"
# 根据地域设置 npm 镜像源
if [ $isCN = "CN" ];then
    npm config set registry https://registry.npmmirror.com
fi

# 安装 yarn
echo -e "\r\n${green_color}正在安装 yarn …${default_color}"
if ! command -v yarn >/dev/null 2>&1; then
    if command -v yum >/dev/null 2>&1; then
        curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
        yum -y install yarn
    else
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    fi
fi

cd ./alist
echo -e "\r\n${green_color}正在clone alist …${default_color}"
git clone https://github.com/Xhofe/alist

echo -e "\r\n${green_color}正在clone alist-web …${default_color}"
git clone https://github.com/Xhofe/alist-web

# crontab
echo "* * */3 * * root sh /root/alist/bulid.sh" >> /var/spool/cron/root
sh ./bulid.sh