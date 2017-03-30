#!/bin/bash

# author:  Andy wei < andywei2010@163.com >
# created: 2017/3/25

# 默认项
IS_NEW_IMAGES='no'
IMAGES='nginx-php'
TAG='1.0'
DOCKERFILE_PATH='.'
USER_HTTP_PORT=80
USER_SSH_PORT=22
HOST_IP='172.16.184.188'
HOST_DOMAIN='demo.dev'

# 帮助
if [ x$1 == 'x--help' -o x$1 == 'x-h' ]
then
	echo ""
	echo "该脚本仅支持 -u -p -s [-i] [-d] [-n] [-m] [-t] 8个参数"
	echo ""
	echo "参数说明: "
	echo "-u: 用户名[必填]"
	echo "-p: HTTP容器端口号[必填]"
	echo "-s: SSH 容器端口号[必填]"
	echo "-i: 宿主机 IP [可选](默认值为: $HOST_IP)"
	echo "-d: 宿主机域名[可选](默认值为: $HOST_DOMAIN)"
	echo "-n: 是否创建新镜像[可选](yes || no ; 默认值为: $IS_NEW_IMAGES)"
	echo "-m: 镜像名称[可选](默认值为: $IMAGES)"
	echo "-t: 镜像标签[可选](默认值为: $TAG)"
	echo ""
	echo "使用方法: ./start.sh -u <args...> -p <args...> -s <args...> [-i] [<args...>] [-d] [<args...>] [-n] [<args...>] [-m] [<args...>] [-t] [<args...>]"
	echo ""
	echo "注: 初始化镜像或创建新的镜像, -n 参数值必须是 yes"
	echo "示例(1) : ./start.sh -u andywei -p 8000 -s 22000 -i 172.16.184.188 -d demo.dev -n yes -m nginx-php -t 1.0"
	echo "示例(2) : ./start.sh -u your_name -p 8001 -s 22001 -i 172.16.184.188 -d demo.dev -n no -m nginx-php -t 1.0"
	echo "..."
	echo ""
	exit
fi

# 参数验证
if [ x$1 != 'x-u' -o x$2 == 'x' ]
then
	echo "请填写您的用户名"
	exit
fi

if [ x$3 != 'x-p' -o x$4 == 'x' ]
then
	echo "请填写通过 http 访问您 docker 容器的端口号(默认 $USER_HTTP_PORT 端口除外)"
	exit
fi

if [ x$5 != 'x-s' -o x$6 == 'x' ]
then
	echo "请填写通过 ssh 登录您 docker 容器的端口号(默认 $USER_SSH_PORT 端口除外)"
	exit
fi

while getopts "u:p:s:i:d:n:m:t:" arg
do
	case $arg in
		u)
			USER_NAME="$OPTARG"
			;;
		p)
			USER_HTTP_PORT="$OPTARG"
			;;
		s)
			USER_SSH_PORT="$OPTARG"
			;;
		i)
			HOST_IP="$OPTARG"
			;;
		d)
			HOST_DOMAIN="$OPTARG"
			;;
		n)
			IS_NEW_IMAGES="$OPTARG"
			;;
		m)
			IMAGES="$OPTARG"
			;;
		t)
			TAG="$OPTARG"
			;;
		?)
			echo "unkonw args..."	
		exit 1
		;;
	esac
done

# 定义项
USER_HOME="/home/$USER_NAME"
USER_WORKSPACE="/data/workspace/$USER_NAME"
USER_WWW="$USER_HOME/www"
USER_PWD="$USER_NAME@dev"

CONTAINER_USER_NAME="webserver"
CONTAINER_USER_PWD="$CONTAINER_USER_NAME@dev"
CONTAINER_USER_WWW="/home/$CONTAINER_USER_NAME/www"

CONTAINER_ROOT_NAME="root"
CONTAINER_ROOT_PWD="$CONTAINER_ROOT_NAME@dev"

# 创建用户
if [ ! -d "$USER_HOME" ]
then
	echo "----开始创建宿主机用户：$USER_NAME"
	useradd -m "$USER_NAME"
	echo "$USER_NAME:$USER_PWD" | chpasswd
fi

# 创建工作目录
if [ ! -d "$USER_WORKSPACE" ]
then
	echo "----开始创建用户工作目录：$USER_WORKSPACE"
	mkdir -p "$USER_WORKSPACE"
	ln -s "$USER_WORKSPACE" "$USER_WWW"
	chown -R "$USER_NAME":"$USER_NAME" "$USER_WORKSPACE" "$USER_WWW"
fi

# 删除用户容器
docker rm -f "$USER_NAME"

if [ "$IS_NEW_IMAGES" == 'yes' ]
then
	docker rmi -f "$IMAGES:$TAG"
	echo "----开始创建镜像：$IMAGES:$TAG"
	docker build -t "$IMAGES:$TAG" "$DOCKERFILE_PATH"
fi

echo "----开始创建容器：$USER_NAME"
docker run -d -t -v "$USER_WWW:$CONTAINER_USER_WWW" --name="$USER_NAME" --privileged --add-host="$USER_NAME.$HOST_DOMAIN:$HOST_IP" -p $USER_SSH_PORT:22 -p $USER_HTTP_PORT:80 "$IMAGES:$TAG"
#docker exec -it "$USER_NAME" bash -c "chown -R $CONTAINER_USER_NAME:$CONTAINER_USER_NAME $CONTAINER_USER_WWW"
docker exec -it "$USER_NAME" bash -c "chmod -R 777 $CONTAINER_USER_WWW"

echo ""
echo "----执行完成! 请妥善保管以下属于您私人的专属账号!!!"
echo ""
echo "登录宿主机: ssh $USER_NAME@$HOST_IP; 默认密码为: $USER_PWD"
echo "登录您的容器: ssh $CONTAINER_USER_NAME@$HOST_IP -p $USER_SSH_PORT; 默认密码为: $CONTAINER_USER_PWD"
echo "您的容器 $CONTAINER_ROOT_NAME 密码: $CONTAINER_ROOT_PWD"
echo ""
echo "您还可以通过浏览器访问您容器的项目哦,如:"
echo "$HOST_DOMAIN:$USER_HTTP_PORT"
echo "..."
echo ""



