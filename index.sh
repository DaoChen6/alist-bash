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

# 检测 root 权限
if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n${red_color}请使用root权限运行本脚本" 1>&2
  exit 1;
fi

#remind='\e[34m
#==========================================================================
#\r\n                        Alist 一键部署脚本\r\n
#  Alist是一款阿里云盘的目录文件列表程序，后端基于golang最好的http框架gin\r
#  前端使用vue和ant design\r  项目地址：https://github.com/Xhofe/alist\r\n
#                                        Script by 道辰 www.iflm.ml\r\n
#==========================================================================
#\e[0m';
#echo -e ${remind}

echo -e "${green_color}正在初始化……${default_color}"

# The temp directory must exist
if [ ! -d "/tmp" ];then
    mkdir -p /tmp
fi

if [ ! -d "/opt/alist" ];then
    mkdir -p /opt/alist
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
if [ $isCN = "CN" ]; then
    ping -c 2 github.com.cnpmjs.org > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        mirror="https://github.com.cnpmjs.org"
    else
        mirror="https://github.com"
    fi
else
    mirror="https://github.com"
fi

bulid_install() {
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
if [ $isCN = "CN" ]; then
    if [ -f "/root/.gitconfig" ]; then
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
curl -L https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go${GO_VERSION}.linux-amd64.tar.gz ${CURL_BAR}
tar zxf /tmp/go${GO_VERSION}.linux-amd64.tar.gz -C /tmp/
mkdir -p /tmp/go/tmp
export PATH="/tmp/go/bin:$PATH"
export GOPATH="/tmp/go/tmp"
rm -rf /tmp/go${GO_VERSION}.linux-amd64.tar.gz

# 根据地域设置 GOPROXY 镜像源
if [ $isCN = "CN" ]; then
    export GO111MODULE=on
    export GOPROXY="https://goproxy.cn"
fi

# 安装 nodejs
echo -e "\r\n${green_color} 正在安装NodeJS … ${default_color}"
if [ $isCN = "CN" ]; then
    curl -L https://npmmirror.com/mirrors/node/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz -o /tmp/node-v${NODEJS_VERSION}-linux-x64.tar.xz ${CURL_BAR}
else
    curl -L https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz -o /tmp/node-v${NODEJS_VERSION}-linux-x64.tar.xz ${CURL_BAR}
fi

tar xf /tmp/node-v${NODEJS_VERSION}-linux-x64.tar.xz -C /tmp/
mv /tmp/node-v${NODEJS_VERSION}-linux-x64 /tmp/nodejs
export PATH="/tmp/nodejs/bin:$PATH"
rm -rf /tmp/node-v${NODEJS_VERSION}-linux-x64.tar.xz

# 根据地域设置 npm 镜像源
if [ $isCN = "CN" ]; then
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

# git clone alist项目
mkdir /tmp/alist-build
cd /tmp/alist-build
echo -e "\r\n${green_color}正在clone alist …${default_color}"
git clone https://github.com/Xhofe/alist

echo -e "\r\n${green_color}正在clone alist-web …${default_color}"
git clone https://github.com/Xhofe/alist-web

# 构建alist前端
cd /tmp/alist-build/alist-web
git pull
echo -e "\r\n${green_color}正在编译 alist-web …${default_color}"
yarn && yarn build
mv /tmp/alist-build/alist-web/dist/* /tmp/alist-build/alist/public/

# 构建alist后端 生成二进制文件
cd /tmp/alist-build/alist
git pull
echo -e "\r\n${green_color}正在编译 alist …${default_color}"
appName="alist"
builtAt="$(date +'%F %T %z')"
goVersion=$(go version | sed 's/go version //')
gitAuthor=$(git show -s --format='format:%aN <%ae>' HEAD)
gitCommit=$(git log --pretty=format:"%h" -1)
gitTag=$(git describe --long --tags --dirty --always)
ldflags="\
-w -s \
-X 'github.com/Xhofe/alist/conf.BuiltAt=$builtAt' \
-X 'github.com/Xhofe/alist/conf.GoVersion=$goVersion' \
-X 'github.com/Xhofe/alist/conf.GitAuthor=$gitAuthor' \
-X 'github.com/Xhofe/alist/conf.GitCommit=$gitCommit' \
-X 'github.com/Xhofe/alist/conf.GitTag=$gitTag' \
"
go build -ldflags="$ldflags" alist.go

mv alist /opt/alist/alist-start

# 守护进程
echo -e "[Unit]
Description=alist
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/alist
ExecStart=/opt/alist/alist-start -conf data/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/alist.service

systemctl daemon-reload
systemctl restart alist
systemctl status alist
}

# 配置Caddy反向代理
caddy_config() {
echo -e "\r\n${green_color} 正在安装Caddy … ${default_color}"
if command -v yum >/dev/null 2>&1; then
    yum -y install yum-plugin-copr
    yum -y copr enable @caddy/caddy
    yum -y install caddy
else
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt install -y caddy
fi

echo -e ":80 {
reverse_proxy 127.0.0.1:5244
}
" > /etc/caddy/Caddyfile
systemctl restart caddy
}

cron_bulid() {
# crontab
echo "* * */3 * * root curl -fsSL https://cdn.jsdelivr.net/gh/DaoChen6/alist-bash/index.sh | bash -s build" >> /var/spool/cron/root
}

show_menu() {
  echo -e "
  ${green_color}Alist 一键部署脚本${default_color}
  ---https://github.com/DaoChen6/alist-bash---
  ${green_color}0.${default_color}退出脚本
  ————————————————
  ${green_color}1.${default_color}编译安装
  ${green_color}2.${default_color}二进制安装
  ${green_color}3.${default_color}暂无
  ${green_color}4.${default_color}暂无
  ${green_color}5.${default_color}暂无
  ${green_color}6.${default_color}暂无
  ————————————————
  ---定时更新---
  ${green_color}7.${default_color}编译安装
  ${green_color}8.${default_color}二进制安装
  ————————————————
  ${green_color}9.${default_color}Caddy反向代理配置
  "
echo && read -p "请选择[0-9]：" num
case "${num}" in
  0) exit 0;;
  1) bulid_install;;
  2) binaries;;
  7) cron_bulid;;
  8) cron_binaries;;
	9) caddy_config;;
  *) echo -e "${red_color}请输入正确数字 [0-9]${default_color}";;
esac
}

# show
if [[ $# -gt 0 ]]; then
		case $1 in
		"build") bulid_install;;
		"twobuild") binaries;;
		*) echo -e "${red_color}请输入正确命令${default_color}"
		esac
else
		show_menu
fi