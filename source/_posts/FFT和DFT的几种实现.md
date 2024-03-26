---
title: FFT和DFT的几种实现
date: 2024-01-29 13:22:48
tags:
  - 算法
---

傅里叶变换和离散余弦变换的几种快速算法与代码实现

<!--more-->

## 1. 傅里叶变换

### 1.1 朴素傅里叶变换算法

![image-20240129133007100](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20240129133007100.png)

朴素算法的算法复杂度是$O(M^2 N^2)$，复杂度较高，实用性较低。利用DFT的可分离性，可以将二维DFT的计算转化为一维DFT的计算。优化一维DFT就可以达到优化二维DFT的目的。

### 1.2 Cooley-Tukey算法

Cooley-Turkey算法的前提是信号长度N不是质数，即N可以分解$N=nm$。该算法采用分治的思想，将N个数据分成m组，每组n个(按照下标对m取模的值分组)。根据消去引理，设单位复根$w_N^t=\exp⁡(\frac{-j2πt}{N})$，则$w_{kN}^{kt}=w_N^t$。所以一维DFT
$$
\begin{aligned}
F(u) &= ∑_{x=0}^{N-1} f(x) w_N^{ux}  \\
     &= ∑_{a=0}^{m-1} ∑_{b=0}^{n-1} f(bm+a) w_{nm}^{u(bm+a)}  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} ∑_{b=0}^{n-1} f(bm+a) w_{nm}^{ubm} \\  
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} ∑_{b=0}^{n-1} f(bm+a) w_n^{ub} \\ 
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} \text{DFT}(f(bm+a))  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} X_{(a,u)} \quad (0≤u<n)
\end{aligned}
$$
对每组长度为n的数据进行DFT，得到的结果为$X_{a,u}$(表示第a组数据DFT的结果中下标为u的数据)，很容易证明=$X_{a,u}=X_{a,u+n}$，进而
$$
\begin{aligned}
G(k) &= F(u+kn)  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{(u+kn)a} X_{(a,u)}  \\
     &= ∑_{a=0}^{m-1} w_m^ka (w_{nm}^{ua} X_{(a,u)})  \\
     &= \text{FFT}(w_{nm}^{ua} X_{(a,u)})
\end{aligned}
$$
因此，要计算$F(u+kn)$，取出每组得到的DFT结果中下标均为u的数据，将其乘以$w_{nm}^{au}$ ，然后再对这些数据做DFT即可。

### 1.3 基2FFT算法

如果信号的长度N是2的幂次，此时采用Cooley–Tukey算法就是最常见的基2快速傅里叶算法，这种情况下按照下标的奇偶性将对信号分成两组。对于基2的CT算法，既可以采用递归形式实现，也可以采用迭代形式实现，如果采用递归实现，调用过程中会占用大量系统堆栈，效率不高，因此一般是递归形式实现。

由下面的递归树可知，只需要事先对原始数据排好序，然后对其进行归并即可。

![N=8时的递归树](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20240129134316403.png)

观察N=8时的例子，排好序后的顺序，实际上是原来下标的二进制表示翻转得到的。

以$a_6$为例，6的二进制表示是110，将其翻转得到011，011就是3，也就是排好序后$a_6$所处的位置。

### 1.4 Bluestein算法


以下是将所述的Bluestein算法的公式转换为Markdown格式，并进行适当的对齐：
$$
\begin{aligned}
F(u) &= \sum_{x=0}^{N-1} f(x) w_N^{ux} \\
     &= \sum_{x=0}^{N-1} f(x) w_N^{-(u-x)^2/2 + u^2 + x^2/2} \\
     &= w_N^{u^2/2} \sum_{x=0}^{N-1} f(x) w_N^{x^2/2} w_N^{-(u-x)^2/2} \\
     &= w_N^{u^2/2} \sum_{x=0}^{N-1} g(x) \cdot h(u-x),
\end{aligned}
$$


```

```

其中，$g(x) = f(x) w_N^{x^2/2}$，$h(x) = w_N^{-x^2/2}$，则
$$
\begin{aligned}
F(u) &= w_N^{u^2/2} \sum_{x=0}^{N-1} g(x) \cdot h(u-x) \\
     &= w_N^{u^2/2} g(x)*h(x),
\end{aligned}
$$
然后使用卷积定理，并补零到2的幂次：

$$
\begin{aligned}
F(u) &= w_N^{u^2/2} \sum_{x=0}^{N-1} g(x) \cdot h(u-x) \\
     &= w_N^{u^2/2} \text{IFFT}_2\left(\text{FFT}_2(\text{pad}(g)) \cdot \text{FFT}_2(\text{pad}(h'))\right),
\end{aligned}
$$


其中 `pad` 表示补零操作，`FFT_2` 和 `IFFT_2` 分别表示基2的迭代形式FFT算法和逆FFT算法。这里，`h'` 是 `h` 在对称中心进行延拓后得到的信号。
