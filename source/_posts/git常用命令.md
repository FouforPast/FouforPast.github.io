---
title: git常用命令
tags:
  - linux
  - git
catagory:
  - 计算机
date: 2023-07-16 11:13:14

---

hexo和git常用命令

<!--more-->


### hexo常见操作

```sh
# 部署操作
hexo clean
hexo generate
hexo deploy

hexo new [layout] <title> # lauout：page，post，draft
hexo server --draft  # 预览
hexo publish draft <title>  # 将draft发布到post中
```



### git常见操作

参考[Git使用教程,最详细，最傻瓜，最浅显，真正手把手教 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/30044692)

git的工作流程

![img](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/v2-3bc9d5f2c49a713c776e69676d7d56c5_720w.png)

```sh
# 设置用户信息
git config --global user.name "name"
git config --global user.email "email"

# 创建版本库
git init
# 添加文件
git add <file>
# 提交
git commit -m "msg"
# 查看状态
git status
# 查看修改内容
git diff <file>

# 版本回退
git log [--pretty=oneline] # 查看日志
git reflog # 可以查看回退的日志
git reset [--hard] HEAD^ # 回退到上个版本
git reset [--hard] HEAD~N # 回退到前N个版本
git reset [--hard] <commit> # 回退到特定版本，彻底修改分支历史和状态，会删除更改和提交，不会修改工作目录和暂存区的内容，因此之前的更改仍然存在，并且处于待提交状态
git reset --soft <commit> # 将分支指针移动到指定提交，但保留重置点之后的更改
git checkout <commit> # 回退到特定版本，进入一个“分离头指针”（detached HEAD）状态，临时查看特定提交的代码，不会修改分支或删除更改

# 撤销修改
git checkout -- <file> # 仅取消暂存的更改，还可能覆盖未暂存的修改，恢复到最近的提交状态
git restore --staged <file> # 取消已暂存的文件更改，只影响暂存区
git reset <file> # 取消已暂存的文件，相当于git restore --staged <file>
git reset [--mixed] # 取消所有已暂存的文件


# 远程仓库
ssh-keygen -t rsa-C "email" # 创建ssh key
git remote -v # 查看远程仓库状态
git remote add <name> <url> # 将一个新的远程仓库添加到本地仓库。<name>是远程仓库的名称，<url>是远程仓库的UR
git branch -M main # 当前的分支重命名为"main"
git push [-u] <name> <branch> # 提交到远程仓库
git fetch # 从远程仓库中获取最新的提交、分支和标签信息，但不修改
git pull # 从远程仓库拉取并合并到当前分支，相当于git fetch + git merge
git checkout -b <new-branch> <start-point> # 创建并切换到一个新的分支，将其起点设置为远程仓库的start-point(e.g. origin/dev)分支


# 创建和合并分支
git branch # 查看分支
git branch <branch_name> # 创建分支
git checkout <branch_name> # 切换分支
git checkout -b <branch_name> # 相当于上面两条命令
git merge <branch_name> # 将branch_name分支合并到当前分支
git branch -d <branch_name> # 删除分支


# 隐藏分支
git stash # 隐藏当前分支
git stash list # 查看隐藏的分支
git stash apply # 恢复隐藏的分支但不删除
git stash drop # 删除隐藏分支
git stash pop # 恢复并删除隐藏分支

```

