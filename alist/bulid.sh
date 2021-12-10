#!/bin/bash

# Color
red_color="\e[31m"
green_color="\e[32m"
default_color="\e[0m"

# 构建alist前端
cd /root/alist/alist-web
git pull
echo -e "\r\n${green_color}正在编译 alist-web …${default_color}"
yarn && yarn build
mv ./dist/* ../alist/public/

# 构建alist后端 生成二进制文件
cd ../alist
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