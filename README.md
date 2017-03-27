# Centos-7-Dockerfiles
基于 Docker + Centos-7 + Nginx + PHP + SSH + Supervisord + Shell 的开发环境搭建



#### 写在前面：
> Docker 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的 Linux 机器上，也可以实现虚拟化。



## 为什么使用 Docker

#### 1. 高效
> 研发部有新人入职，几乎不需要新人花时间和精力搭建开发环境。只需要通过一条简单的命令即刻完成。

#### 2. 环境统一（dev \ testing \ prod）
> 可以有效地避免开发过程中遇到的奇葩问题，如：“我在我本地是运行是 OK 的，为什么提交到测试环境就报错了”，但很大程度上是因为开发环境和测试环境不一致而导致的。

#### 3. 远程工作
> 比如哪天 PC 机出状况了，而开发环境以及代码都在本地（Local）。即使临时找了台 PC 机就可以开始工作吗？我想答案是 NO.
>
> 再比如说，哪天心血来潮在家办公（其实是代码出 BUG 了，哈哈），而开发环境和 PC 机在公司，家里的 PC 又没有开发环境，怎么办？没事儿啊，我可以远程登录开发机进行工作啊。除非你公司的电脑不关机，这样在家还能远程控制桌面，那就无话可说了。

#### 4. 方便迁移
> 比如所有研发人员都在一台机器上开发（开发机A），由于某种原因要把开发机 A 的环境以及代码迁移到 开发机 B 上面去。也只需要简单的一两条命令即刻完成。



## 理解 Docker

可以把 Docker 想像成一个大仓库（Docker registeries）里面放着许多各种各样的大盒子（Docker images），而每一个大盒子里又装着无数个相互之间没有联系的小盒子(Docker containers)。

而 Docker 内部构建，主要理解以下三种部件：

* Docker 镜像 - Docker images
* Docker 仓库 - Docker registeries
* Docker 容器 - Docker containers



## 使用 Docker 一键搭建开发环境（Nginx + PHP7）

#### 使用前准备：

1. 准备一台装有 Centos 系统的 PC 或 Server（这里简称宿主机）。
2. 在宿主机上安装 [Docker](https://docs.docker.com/engine/installation/linux/centos/) 应用并从云端拉取 Centos-7 镜像，`docker pull docker.io/centos`（请使用代理）
3. `git clone https://github.com/andywei2010/Centos-7-Dockerfiles.git` 至您的 Centos 系统

这里以内网测试机（172.16.184.188）为例，这里简称宿主机。在此基础上安装了 Docker 应用。您要想构建属于自己的开发环境，只需要登录宿主机 Centos-7-Dockerfiles 目录下执行以下命令，即刻完成。

`$ ./start.sh`

#### 使用该命令前，您得查看一下命令所需要的参数，如下：

`$ ./start.sh -h`

> 该脚本仅支持 -u -p -s [-i][-d] [-n][-m] [-t] 8个参数

> -u: 企业邮箱用户名[必填]

> -p: HTTP 容器端口号[必填]

> -s: SSH 容器端口号[必填]

> -i: 宿主机 IP [可选]（默认值为: 172.16.184.188）

> -d: 宿主机域名[可选]（默认值为: demo.dev）

> -n: 是否创建新镜像[可选]（yes || no ; 默认值为: no）

> -m: 镜像名称[可选]（默认值为: nginx-php）

> -t: 镜像标签[可选]（默认值为: 1.0）

#### 使用方法: 
`./start.sh -u <args...> -p <args...> -s <args...> [-i] [<args...>] [-d] [<args...>] [-n] [<args...>] [-m] [<args...>] [-t] [<args...>]`

注: 初始化镜像或创建新的镜像, -n 参数值必须是 yes

示例(1) : 

`./start.sh -u andywei -p 8000 -s 22000 -i 172.16.184.188 -d demo.dev -n yes -m nginx-php -t 1.0`

示例(2) : 

`./start.sh -u andywei_1 -p 8001 -s 22001`

> ----执行完成! 请妥善保管以下属于您私人的专属账号!!!

> 登录宿主机: ssh andywei@172.16.184.188; 默认密码为: andywei@dev
>
> 登录您的容器: ssh webserver@172.16.184.188 -p 22000; 默认密码为: webserver@dev

> 您还可以通过浏览器访问您容器的项目哦,如:
>
> demo.dev:8000
>
> ...

#### 搭建完成：

##### 1. 熟悉您的开发环境（容器）

* Nginx 启动：`/etc/init.d/nginx`

* Nginx 关闭 || 重新生成配置：`/etc/init.d/nginx -s stop || reload`

* Nginx 安装目录：`/usr/local/opt/nginx`

* Nginx 配置文件目录：`/usr/local/etc/nginx`

* Nginx 日志目录：`/usr/local/var/log/nginx`

* Nginx 虚拟主机目录：`/usr/local/etc/nginx/webconfig`

* Nginx 虚拟主机工作目录（家目录）：`/home/webserver/www`

  ​

* PHP 启动：`/etc/init.d/php-fpm`

* PHP 关闭：`kill -9 $(ps aux|grep php|grep -v grep |awk '{print $2}')`

* PHP 安装目录：`/usr/local/opt/php`

* PHP 配置文件目录：`/usr/local/etc/php`

* PHP 日志目录：`/usr/local/var/log/php`

* PHP 扩展目录：`/usr/local/etc/php/7.1/conf.d`

##### 2. SVN 或 Git 仓库 PHP 代码检出到本地 PC（没有请忽略此条）

##### 3. 安装并配置 sftp 插件，同步本地代码到宿主机（安装 Docker 的机器）

示例配置如下（可根据自己的方式配置）：
>
> "host": "172.16.184.188",  //宿主机地址
>
> "user": "andywei",  //您的宿主机 ssh 账号
>
> "password": "andywei@dev", //密码
>
> "upload_on_save": true, //保存本地文件自动代码同步到远程
>
> "remote_path": "/home/andywei/www",  //您的工作目录（代码）

## Done, Thanks!


