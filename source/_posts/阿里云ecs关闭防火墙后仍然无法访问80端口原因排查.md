---
title: 阿里云ecs关闭防火墙后仍然无法访问80端口原因排查
date: 2024-05-05 23:01:39
tags:
  - debug
---

<!--more-->

阿里云ECS放行80端口，防火墙已关闭的情况下还是无法访问从外部访问80端口，而本地则可以正常访问80端口，这让我初始时以为是外部不能访问到服务器端口的原因。尝试了以下几种方法

### nmap查看端口是否开放

![image-20240505230536376](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage/img/image-20240505230536376.png)

结果如上图所示，由于阿里云防火墙的存在，实际上访问哪个端口都会出现`open|filtered`的状态。

### iptables增加放行规则

```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -nL
```

[阿里云ECS服务器无法访问端口（防火墙在关闭状态也启作用）_阿里云ubuntu 防火墙已关闭还需要设置端口吗-CSDN博客](https://blog.csdn.net/qyhua/article/details/135364619)

实测不行

### 启动firewalld并增加放行规则

```bash
systemctl start firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
```

[linux关闭防火墙了，但端口还是访问不了_华为麒麟系统防火墙已关闭,但ip能ping通 端口不通-CSDN博客](https://blog.csdn.net/qq_39176597/article/details/111939051)

实测不行

### 最终办法

我一直在纠结端口能不能访问到的问题，实际上我还同时放开了Mysql的3306和Redis的6379端口，而我在本机利用nvicat和tiny rdm都是可以正常访问远程服务器的。所以其实前面我的修改方向一直错了。

上面用nmap查看端口是否能访问到的方法有缺陷，对于80端口，正确的查看能否被访问的办法是`curl`命令（这个命令最好在linux客户端下运行）

[测试Linux端口的是否可访问的四种方法_linux测试接口是否可以调用-CSDN博客](https://blog.csdn.net/fengzelun/article/details/118338128)

```bash
curl ip:port
```

![image-20240505231806523](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage/img/image-20240505231806523.png)

我测试的结果如上，可见并不是不能访问，而是没有权限。

最终解决办法是给前端资源文件夹加上权限。

```bash
#修改文件类型权限
find ./ -type f|xargs chmod 644
#修改文件夹类型权限
find ./ -type d|xargs chmod 755
```

[阿里云Nginx配置站点403Forbidden问题_阿里云配置nginx老是403-CSDN博客](https://blog.csdn.net/lxh_worldpeace/article/details/108610499)
