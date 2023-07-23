---
title: 加入注意力机制的EfficientUnet
tags:
  - CNN
  - 语义分割
catagories:
  - 论文阅读

---

若干EfficientUnet和EfficientNet with attention的论文

<!--more-->

### Multi‑head attention‑based two‑stream EfficientNet for action recognition  

一篇动作识别领域的论文，文章设计了一种双流卷积网络，分别提取视频的空间和光流信息，最后用多头注意力机制融合。骨干网络采用了Efficient-B0。

![image-20221120015633996](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120015633996.png)

### EfficientNet embedded with spatial attention for recognition of multi-label fundus disease from color fundus photographs

一篇医学领域的论文，提出了加入空间注意力的EfficientNet-B4变体结构，用于诊断眼底疾病。

![image-20221120020219313](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120020219313.png)

空间注意力模块其实也包含了通道注意力，整体是CBAM的变体，只是在CBAM的空间注意力模块最后的卷积换成了作者自己定义的一个Conv Module，如下(只看论文有些模糊，如果有代码就一目了然)：

![image-20221120021229669](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120021229669.png)

### EAR-U-Net: EfficientNet and attention-based residual U-Net for automatic liver segmentation in CT  
又是一篇医学领域的论文，目的是进行肝脏分割。

![image-20221120021527242](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120021527242.png)
作者在这里用的注意力机制是attention gate

![image-20221120021815517](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120021815517.png)

attention gate来自于论文Attention U-Net: Learning Where to Look for the Pancreas。

![image-20221120022617524](C:/Users/User/AppData/Roaming/Typora/typora-user-images/image-20221120022617524.png)

EAR-U-Net的不同点在于采取了残差连接和EfficientNet的骨干网络。[作者代码](https://github.com/ZhangXY-123/EAR-Unet/blob/294cce473539f50a33b13e645ae1f50d6272d752/model/EAR-Unet.py)
