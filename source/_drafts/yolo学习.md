---
title: yolo学习
tags:
  - YOLO
catagories:  
  - 目标检测
---

Yolov系列学习

<!---more--->

YOLO网络是十分重要的one-stage目标检测算法。下面记录一下自己的学习记录。

## YOLOv1

YOLOv1对原图分割成$S\times S$大小的网格，每个网格预测B个bbox，每个bbox对应5个参数，分别是$x_{center},y_{center},w,h,confidence$， $x_{center},y_{center}$表示bbox的中心相对于网格左上角的偏移坐标（ 用网格的大小做归一化处理），$w,h$表示预测的bbox的宽和高，$confidence$表示网格是否包含目标的置信度，如果有GT的中心坐标落在该网格内，confidence就为1，否则为0，每个网格还要预测类别，所以最终输出的特征图大小为$S\times S\times(B*5+C)$。

![image-20221127212412105](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20221127212412105.png)

#### 网络结构分析

![image-20221127212130622](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20221127212130622.png)

YOLOv1的结构比较简单，骨干网络都是DarkNet-19，通过若干卷积层后最终输出$S\times S\times(B*5+C)$的特征图。

训练时，作者首先在ImageNet数据集上预训练了骨干网络（前20个卷积层），然后添加上检测头，并把网络的输入尺寸从$224×224$改为$448×448$（这一步是因为作者认为检测一般需要细粒度的视觉信息）。

#### 损失函数

下面重点分析一下损失函数

![image-20221127214449017](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20221127214449017.png)

前两行是定位损失，第三行和第四行是置信度损失，最后一行是分类损失。

$1_{ij}^{obj}$表示第i个网格的第j个bbox是否用来预测目标，如果该bbox和目标有着最高的IOU，$1_{ij}^{obj}=1$，否则为0。定位损失采用L1损失，对于$w,h$的预测是对它们的平方根计算L1损失，这样是为了加大相同的w或h的差值在bbox较小时的损失权重。

置信度的预测也采用L1损失。公式中的$\lambda_{coord}$是为了平衡定位损失和分类损失，因为此处二者采用的都是L1损失，如果不加权重相当于认为二者对于检测任务是同等重要的，然而前者是一个8维向量的L1损失，后者是一个20维向量的L1损失，显然不加权重平衡是不合理的，的如果分类损失采用交叉熵损失就不需要加了。$\lambda_{noobj}$是为了平衡包含bbox的bbox和不包含目标的bbox之间的权重，因为那些没有目标的网格的bbox的置信度会在训练过程中变为0，目标较少的图片容易overpowering。

分类损失采用L1损失，此处注意是每个网格对应一个分类损失。$1_{i}^{obj}$表示是否有目标的中心落在第i个网格。

#### 局限

每个网格只能有一个类别，只能有B个bbox，因此难以预测小物体；第二个是难以预测具有不同寻常纵横比的目标；没有先验anchor，预测较差。

