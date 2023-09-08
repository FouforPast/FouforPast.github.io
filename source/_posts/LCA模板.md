---
title: LCA模板
date: 2023-09-03 23:27:42
tags:
  - 算法模板
---

LCA算法模板，用倍增思路实现，包含建图、求节点的第k个祖先、求LCA等模板

<!--more-->

leetcode链接：

[2846. 边权重均等查询 - 力扣（LeetCode）](https://leetcode.cn/problems/minimum-edge-weight-equilibrium-queries-in-a-tree/)

[2836. 在传球游戏中最大化函数值 - 力扣（LeetCode）](https://leetcode.cn/problems/maximize-value-of-function-in-a-ball-passing-game/description/)

[1483. 树节点的第 K 个祖先 - 力扣（LeetCode）](https://leetcode.cn/problems/kth-ancestor-of-a-tree-node/)

[236. 二叉树的最近公共祖先 - 力扣（LeetCode）](https://leetcode.cn/problems/lowest-common-ancestor-of-a-binary-tree/solutions/238552/er-cha-shu-de-zui-jin-gong-gong-zu-xian-by-leetc-2/)

```python
class TreeAncestor:
    def __init__(self, edges: List[List[int]]):
        n = len(edges) + 1
        m = n.bit_length()
        # 建图
        g = [[] for _ in range(n)]
        for x, y in edges:  # 节点编号从 0 开始
            g[x].append(y)
            g[y].append(x)

        # 一个dfs预处理出所有节点的深度
        depth = [0] * n
        pa = [[-1] * m for _ in range(n)]
        def dfs(x: int, fa: int) -> None:
            pa[x][0] = fa
            for y in g[x]:
                if y != fa:
                    depth[y] = depth[x] + 1
                    dfs(y, x)
        dfs(0, -1)

        # 倍增模板
        # 遍历每一种深度
        for i in range(m - 1):
            # 遍历每个节点
            for x in range(n):
                # 获取x的第2^i个祖先的id
                p = pa[x][i]
                # x的第2^i个祖先存在时，获取它的第2^{i+1}个祖先的id
                if p != -1:
                    pa[x][i + 1] = pa[p][i]
        self.depth = depth
        self.pa = pa

    def get_kth_ancestor(self, node: int, k: int) -> int:
        for i in range(k.bit_length()):
            if (k >> i) & 1:  # k 二进制从低到高第 i 位是 1
                node = self.pa[node][i]
        return node
    
    # 另一种写法，不断去掉 k 的最低位的 1
    def getKthAncestor2(self, node: int, k: int) -> int:
        while k and node != -1:  # 也可以写成 ~node
            lb = k & -k
            node = self.pa[node][lb.bit_length() - 1]
            k ^= lb
        return node

    # 返回 x 和 y 的最近公共祖先
    def get_lca(self, x: int, y: int) -> int:
        # 保证y的深度比x的深度更大
        if self.depth[x] > self.depth[y]:
            x, y = y, x
        # y跳到和x相同深度的节点
        y = self.get_kth_ancestor(y, self.depth[y] - self.depth[x])
        if y == x:
            return x
        for i in range(len(self.pa[x]) - 1, -1, -1):
            px, py = self.pa[x][i], self.pa[y][i]
            if px != py:
                x, y = px, py  # 同时上跳 2**i 步
        # 最后的状态：x和y跳到了LCA的孩子节点
        return self.pa[x][0]
```
