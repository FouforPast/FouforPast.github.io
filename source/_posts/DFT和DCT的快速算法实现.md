---
title: DFT和DCT的快速算法实现
date: 2024-04-20 15:06:58
tags:
  - 算法
---

傅里叶变换和离散余弦变换的几种快速算法与代码实现

完整代码详见[Digital-Image-Process/fdt.cpp at main · FouforPast/Digital-Image-Process (github.com)](https://github.com/FouforPast/Digital-Image-Process/blob/main/fdt.cpp)

<!--more-->

## 1. 傅里叶变换

### 1.1 朴素傅里叶变换算法

![image-20240129133007100](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20240129133007100.png)

利用上述公式计算的DFT如下：

```cpp
/*
朴素二维离散傅里叶变换
args:
    src: 输入图像
    dst: 输出图像
    sx: 补齐的行数
    sy: 补齐的列数
    shift: 是否进行频谱中心化
*/
void dftNaive(Mat& src, Mat& dst, int sx, int sy, bool shift)
{
    Mat input = src.clone();
    pad(input, sx, sy);
    int M = input.rows;
    int N = input.cols;

    if (src.type() != 0) { // CV_8U
        throw std::invalid_argument("only CV_8U is accepted");
    }

    Mat res = Mat(M, N, CV_32FC2, Scalar::all(0));
    float* ptr_res = (float*)res.data;

    for (int u = 0; u < M; ++u) {
        for (int v = 0; v < N; ++v) {
            float* ptr_src = (float*)input.data;
            for (int x = 0; x < M; ++x) {
                for (int y = 0; y < N; ++y) {
                    double tmp = ((double)u * x / (double)M + (double)v * y / (double)N) * 2 * M_PI;
                    int factor = shift & (x + y) & 1 ? -1 : 1; // 是否乘以-1
                    res.at<Vec2f>(u, v)[0] += input.at<uchar>(x, y) * cos(-tmp) * factor;
                    res.at<Vec2f>(u, v)[1] += input.at<uchar>(x, y) * sin(-tmp) * factor;
                }
            }
            
        }
    }
    res.copyTo(dst);
}
```



朴素算法的算法复杂度是$O(M^2 N^2)$，复杂度较高，实用性较低。利用DFT的可分离性，可以将二维DFT的计算转化为一维DFT的计算。优化一维DFT就可以达到优化二维DFT的目的。

```cpp
// 利用可分离性原地计算离散傅里叶变换和逆变换（unscaled）
void helpFFT(float* real, float* imag, int M, int N, bool inverse)
{
    // 对行进行FFT
    for (int i = 0; i < M; ++i) {
        dft1d(real + N * i, imag + N * i, N, inverse);
    }
    // 对列进行傅里叶变换
    for (int j = 0; j < N; ++j) {
        complex<float>* col = new complex<float>[M];
        float* real_ = new float[M];
        float* imag_ = new float[M];
        for (int i = 0; i < M; ++i) {
            real_[i] = real[i * M + j];
            imag_[i] = imag[i * M + j];
        }
        dft1d(real_, imag_, M, inverse);
        for (int i = 0; i < M; ++i) {
            real[i * M + j] = real_[i];
            imag[i * M + j] = imag_[i];
        }
    }
}
```

其中朴素一维DFT如下：

```cpp
// 朴素一维傅里叶变换和逆变换（unscaled）
void dft1dNaive(float* real, float* imag, unsigned L, bool inverse)
{
    if (L == 1) {
        return;
    }
    int fact = inverse ? 1 : -1;
    vector<double> real_(L, 0), imag_(L, 0);
    for (int i = 0; i < L; ++i) {
        double real0 = cos(2 * M_PI * i / L), imag0 = fact * sin(2 * M_PI * i / L);
        double real1 = 1, imag1 = 0;
        for (int j = 0; j < L; ++j) {
            real_[i] += real[j] * real1 - imag[j] * imag1;
            imag_[i] += real[j] * imag1 + imag[j] * real1;
            real1 = real1 * real0 - imag1 * imag0;
            imag1 = real1 * imag0 + imag1 * real0;
        }
    }
    for (int i = 0; i < L; ++i) {
        real[i] = real_[i];
        imag[i] = imag_[i];
    }
}
```

### 1.2 Cooley-Tukey算法

Cooley-Turkey算法的前提是信号长度N不是质数，即N可以分解$N=nm$。该算法采用分治的思想，将N个数据分成m组，每组n个(按照下标对m取模的值分组)。根据消去引理，设单位复根$w_N^t=\exp⁡(\frac{-j2πt}{N})$，则$w_{kN}^{kt}=w_N^t$。所以一维DFT
$$
\begin{aligned}
F(u) &=∑_{x=0}^{N-1} f(x) \exp⁡(\frac{-j2πux}{N})\\
&= ∑_{x=0}^{N-1} f(x) w_N^{ux}  \\
     &= ∑_{a=0}^{m-1} ∑_{b=0}^{n-1} f(bm+a) w_{nm}^{u(bm+a)}  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} ∑_{b=0}^{n-1} f(bm+a) w_{nm}^{ubm} \\  
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} ∑_{b=0}^{n-1} f(bm+a) w_n^{ub} \\ 
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} \text{DFT}(\{f(bm+a), b=0,1,...,n-1\})  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{ua} X_{(a,u)} \quad (0≤u<n)
\end{aligned}
$$
对每组长度为n的数据进行DFT，得到的结果为$X_{a,u}$(表示第a组数据DFT的结果中下标为u的数据)，很容易证明$X_{a,u}=X_{a,u+n}$，进而
$$
\begin{aligned}
G(k) &= F(u+kn)  \\
&= ∑_{a=0}^{m-1} w_{nm}^{(u+kn)a} X_{(a,u+kn)}  \\
     &= ∑_{a=0}^{m-1} w_{nm}^{(u+kn)a} X_{(a,u)}  \\
     &= ∑_{a=0}^{m-1} w_m^{ka} (w_{nm}^{ua} X_{(a,u)})  \\
     &= \text{DFT}(\{w_{nm}^{ua} X_{(a,u)},a=0,1,...,m-1\})\\&k=0,1,...,m
\end{aligned}
$$
因此，要计算$F(u+kn)$，取出每组得到的DFT结果中下标均为u的数据，将其乘以$w_{nm}^{au}$ ，然后再对这些数据做DFT即可。

```cpp
// CooleyTukey算法计算当L是2,3,5的倍数时的一维傅里叶变换和逆变换
void fft1dCooleyTukey(float* real, float* imag, unsigned L, bool inverse) {
    if (L == 1) {
        return;
    }
    int fact = inverse ? 1 : -1;
    // 确定分组数目
    int num;
    if (L % 2 == 0) {
		num = 2;
	}
	else if (L % 3 == 0) {
		num = 3;
	}
	else {
		num = 5;
	}
    // 分组
    unsigned newL = L / num;
    float** groupReal = new float* [num];
    float** groupImag = new float* [num];

    for (int i = 0; i < num; ++i) {
        groupReal[i] = new float[newL];
        groupImag[i] = new float[newL];
    }
    for (int i = 0; i < L; ++i) {
        groupReal[i % num][i / num] = real[i];
        groupImag[i % num][i / num] = imag[i];
    }

    // 对每组数据进行DFT
    for (int i = 0; i < num; ++i) {
        dft1d(groupReal[i], groupImag[i], newL, inverse);
    }
    float real0 = cos(2 * M_PI / L), imag0 = fact * sin(2 * M_PI / L);
    float real1 = 1, imag1 = 0;
    for (int i = 0; i < newL; ++i) {
        if (num == 2) {
            float tmpReal = real1 * groupReal[1][i] - imag1 * groupImag[1][i];
            float tmpImag = imag1 * groupReal[1][i] + real1 * groupImag[1][i];
            real[i] = groupReal[0][i] + tmpReal;
            imag[i] = groupImag[0][i] + tmpImag;
            real[i + newL] = groupReal[0][i] - tmpReal;
            imag[i + newL] = groupImag[0][i] - tmpImag;
        }
        else {
            float* tempReal = new float[num];
            float* tempImag = new float[num];
            float real2 = 1, imag2 = 0;
            for (int j = 0; j < num; ++j) {
                tempReal[j] = groupReal[j][i] * real2 - groupImag[j][i] * imag2;
                tempImag[j] = groupImag[j][i] * real2 + groupReal[j][i] * imag2;
                auto tmpReal2 = real2;
                real2 = real2 * real1 - imag2 * imag1;
                imag2 = tmpReal2 * imag1 + imag2 * real1;
            }
            // 长度是3或5直接调用朴素DFT算法
            dft1dNaive(tempReal, tempImag, num, inverse);
            for (int j = 0; j < num; ++j) {
                real[i + newL * j] = tempReal[j];
                imag[i + newL * j] = tempImag[j];
            }
        }
        auto tmpReal1 = real1;
        real1 = real1 * real0 - imag1 * imag0;
        imag1 = tmpReal1 * imag0 + imag1 * real0;
    }
}
```



### 1.3 基2FFT算法

如果信号的长度N是2的幂次，此时采用Cooley–Tukey算法就是最常见的基2快速傅里叶算法，这种情况下按照下标的奇偶性将对信号分成两组。对于基2的DCT算法，既可以采用递归形式实现，也可以采用迭代形式实现，如果采用递归实现，调用过程中会占用大量系统堆栈，效率不高，因此一般是迭代形式实现。

由下面的递归树可知，只需要事先对原始数据排好序，然后对其进行归并即可。

![N=8时的递归树](https://gitee.com/FouforPast/md_picture/raw/master/typora/image-20240129134316403.png)

观察N=8时的例子，排好序后的顺序，实际上是原来下标的二进制表示翻转得到的。

以$a_6$为例，6的二进制表示是110，将其翻转得到011，011就是3，也就是排好序后$a_6$所处的位置。

```cpp
// 翻转数字的bit
size_t reverseBits(size_t val, int width) {
	size_t result = 0;
	for (int i = 0; i < width; i++, val >>= 1)
		result = (result << 1) | (val & 1U);
	return result;
}

// 迭代形式的基2一维傅里叶变换和逆变换（unscaled）
void fft1dIterRadix2(float* real, float* imag, unsigned L, bool inverse)
{
    if (L & (L - 1)) {
        throw std::invalid_argument("invalid length, make sure L is positive and a power of 2");
    }
    int n = log2n(L);
    int fact = inverse ? 1 : -1;
    // 交换原始数据的位置
    for (int i = 0; i < L; ++i) {
        size_t y = reverseBits(i, n);
        if (y > i) {
            swap(real[i], real[y]);
            swap(imag[i], imag[y]);
        }
    }
    // 预处理Wn表
    float* _real = new float[L >> 1];
    float* _imag = new float[L >> 1];

    for (int i = 0; i < (L >> 1); ++i) {
        _real[i] = cos(2 * M_PI * i / L);
        _imag[i] = fact * sin(2 * M_PI * i / L);
    }
    // 蝶形运算
    for (int i = 2; i <= L; i <<= 1) {             // 小序列长度
        for (int j = 0; j < L; j += i) {           // 小序列起始坐标
            for (int k = 0; k < (i >> 1); ++k) {   // 计算小序列的dft
                int idx1 = j + k;
                int idx2 = idx1 + (i >> 1);
                float tmpReal = real[idx2] * _real[k * L / i] - imag[idx2] * _imag[k * L / i];
                float tmpImag = imag[idx2] * _real[k * L / i] + real[idx2] * _imag[k * L / i];
                real[idx2] = real[idx1] - tmpReal;
                imag[idx2] = imag[idx1] - tmpImag;
                real[idx1] += tmpReal;
                imag[idx1] += tmpImag;
            }
        }
    }
}
```

### 1.4 Bluestein算法

当信号f(x)的长度N是质数时，CT算法不再适应，此时可以使用Bluestein算法。
$$
\begin{aligned}
F(u) &= \sum_{x=0}^{N-1} f(x) w_N^{ux} \\
     &= \sum_{x=0}^{N-1} f(x) w_N^{\frac{-(u-x)^2 + u^2 + x^2}{2}} \\
     &= w_N^{u^2/2} \sum_{x=0}^{N-1} f(x) w_N^{x^2/2} w_N^{-(u-x)^2/2} \\
     &= w_N^{u^2/2} \sum_{x=0}^{N-1} g(x) \cdot h(u-x),
\end{aligned}
$$

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

```cpp
// Bluestein算法计算一维傅里叶变换和逆变换（unscaled）
void fft1dBluestein(float* real, float* imag, complex<float>* table, unsigned L, bool inverse)
{
    // 补齐到2的幂次
    int N = 1 << (log2n(L * 2) + 1);
    int fact = inverse ? 1 : -1;
    // 预处理中间向量
    float* realA = new float[N]();
    float* realB = new float[N]();    
    float* imagA = new float[N]();
    float* imagB = new float[N]();

    complex<float>* a = new complex<float>[N];
    complex<float>* b = new complex<float>[N];
    for (int i = 0; i < L; ++i) {
        realA[i] = real[i] * table[i].real() - imag[i] * table[i].imag();
        imagA[i] = imag[i] * table[i].real() + real[i] * table[i].imag();

    }
    for (int i = 1; i < L * 2 - 1; ++i) {
        if (i < L) {
            imagB[i] = -table[L - i - 1].imag();
            realB[i] = table[L - i - 1].real();
        }
        else {
            imagB[i] = -table[i + 1 - L].imag();
            realB[i] = table[i + 1 - L].real();
        }
    }
    // 卷积
    float** conv = convolve(realA, imagA, realB, imagB, N);

    for (int i = 0; i < L; ++i) {
        real[i] = conv[0][i + L] * table[i].real() - conv[1][i + L] * table[i].imag();
        imag[i] = conv[1][i + L] * table[i].real() + conv[0][i + L] * table[i].imag();
    }
}

// 获取Bluestein算法的三角函数表格
complex<float>* getBluesteinTable(unsigned L, bool inverse)
{
    int fact = inverse ? 1 : -1;
    complex<float>* table = new complex<float>[L];
    for (int i = 0; i < L; ++i) {
        uintmax_t temp = static_cast<uintmax_t>(i) * i;
        temp %= static_cast<uintmax_t>(L) * 2;
        double angle = M_PI * temp / L * fact;
        table[i].real(cos(angle));
        table[i].imag(sin(angle));
    }
    return table;
}

// 使用FFT实现卷积
float** convolve(float* real1, float* imag1, float* real2, float* imag2, unsigned L)
{
    fft1dIterRadix2(real1, imag1, L, false);
    fft1dIterRadix2(real2, imag2, L, false);

    float** dst = new float*[2]();
    dst[0] = new float[L];
    dst[1] = new float[L];
    for (int i = 0; i < L; ++i) {
        dst[0][i] = real1[i] * real2[i] - imag1[i] * imag2[i];
        dst[1][i] = imag1[i] * real2[i] + real1[i] * imag2[i];
    }

    fft1dIterRadix2(dst[0], dst[1], L, true);
    for (int i = 0; i < L; ++i) {
        dst[0][i] /= L;
        dst[1][i] /= L;
    }
    return dst;
}
```



### 1.5 实际采用的FFT算法

上面几种FFT算法中，算法性能大致是基2FFT>CT>Bluestein算法，所以实际使用时，根据序列的长度N设计如下算法：

- 如果N是2的幂次，采用基2FFT算法
- 否则如果N是2的倍数或5的倍数，采用一般形式的CT算法
- 否则采用Bluestein算法

```cpp
void dft1d(float* real, float* imag, unsigned L, bool inverse)
{
    //dft1dNaive(real, imag, L, inverse);
    //return;
    if (L == 1) {
        return;
    }
    else if ((L & (L - 1)) == 0) {                      // 2的幂次的情形调用基2傅里叶变换
        fft1dIterRadix2(real, imag, L, inverse);
    }
    else {
        if (L % 5 == 0 || L % 3 == 0 || L % 2 == 0) {   // 如果是2或者3或者5的倍数，调用CooleyTukey算法
            fft1dCooleyTukey(real, imag, L, inverse);
        }
        else {                                          // 其他情形，调用BluesteinTable算法
            long tmp = inverse ? -1 * L : L;
            if (mem.count(tmp) == 0) {
                mem[tmp] = getBluesteinTable(L, inverse);
            }
            fft1dBluestein(real, imag, mem[tmp], L, inverse);
        }
    }
}
```



## 2. 离散余弦变换（DCT）

二维离散余弦变换同样具备可分离性，因此只需要考虑如果优化一维DCT。

实际上，一维DCT可以利用一维FFT实现。可以构造这样一个信号$g(x)$，它通过在原始信号$f(x)$的末尾补N个0得到。
$$
\begin{aligned}
F(u)&=\alpha(u) \sum_{x=0}^{N-1} f(x) \cos \frac{(2 x+1) \pi u}{2 N}\\&=\alpha(u) \sum_{x=0}^{2 N-1} g(x) \cos \frac{(2 x+1) \pi u}{2 N}\\
& =\alpha(u) \sum_{x=0}^{2 N-1} g(x) \operatorname{Real}\left(\exp -\frac{j(2 x+1) \pi u}{2 N}\right)\\
&=\alpha(u) \operatorname{Real}\left(\sum_{x=0}^{2 N-1} g(x) \exp -\frac{j(2 x+1) \pi u}{2 N}\right) \\
& =\alpha(u) \operatorname{Real}\left(\exp \frac{j \pi u}{2 N} \sum_{x=0}^{2 N-1} g(x) \exp -\frac{j 2 \pi u x}{2 N}\right)\\&
=\alpha(u) \operatorname{Real}\left(\exp \frac{j \pi u}{2 N} F F T(g(x))\right)
\end{aligned}
$$
这样就可以利用FFT算法计算DCT。

```cpp
// 快速二维离散余弦变换
void myfdct(Mat& src, Mat& dst, int sx, int sy)
{
    Mat input = src.clone();
    pad(input, sx, sy);
    int M = input.rows;
    int N = input.cols;

    if (src.type() != 5) {    // CV_32F
        throw std::invalid_argument("only CV_32F is accepted");
    }

    Mat res = Mat(M, N, CV_32F, Scalar::all(0));
    float* ptr_res = (float*)res.data;
    // 对行进行DCT
    for (int i = 0; i < M; ++i) {
        dct1d((float*)src.ptr(i), (float*)res.ptr(i), N);
    }
    // 对列进行DCT
    for (int j = 0; j < N; ++j) {
        float* col = new float[M];
        for (int i = 0; i < M; ++i) {
            col[i] = *(ptr_res + N * i + j);
        }
        float* tmp = new float[M];
        dct1d(col, tmp, M);
        for (int i = 0; i < M; ++i) {
            *(ptr_res + N * i + j) = tmp[i];
        }
    }
    res.copyTo(dst);
}

// 一维离散余弦逆变换
void dct1d(float* src, float* dst, int N)
{
    dct1dNaive(src, dst, N);
}

// 基于FFT的一维DCT快速算法
void fdctfft1d(float* src, float* dst, int N) {
    float* imag = new float[2 * N];
    float* real = new float[2 * N];
    memset(imag, 0, N * 2);
    memset(real, 0, N * 2);
    for (int i = 0; i < N; i++) {
        real[i] = src[i];
    }
    dft1d(real, imag, N * 2, false);
    for (int i = 0; i < N; i++) {
        double tmp = i * M_PI / (2 * N);
        dst[i] = (real[i] * cos(tmp) + imag[i] * sin(tmp)) * c(i, N);
    }
}
```

## 3.性能测试

| **图像尺寸**             | **opencv DFT+IDFT** | **朴素**DFT+IDFT | **自编**FFT+IFFT | **opencv DCT+IDCT** | **朴素**DCT+IDCT | **自编**FDCT+IFDCT |
| ------------------------ | ------------------- | ---------------- | ---------------- | ------------------- | ---------------- | ------------------ |
| 256×256  （2的幂次）     | 0.97ms              | 170514ms         | 29.5ms           | 0.46ms              | 83422ms          | 61ms               |
| 257×257  （质数）        | 3.65ms              | 170916ms         | 86.15ms          | 2.29ms              | 93993ms          | 170ms              |
| 240×240  （2,3,5的倍数） | 0.98ms              | 133231ms         | 32.87ms          | 2.29ms              | 81342ms          | 73ms               |

