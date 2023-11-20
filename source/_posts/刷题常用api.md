---
title: 刷题常用api
date: 2023-11-15 17:08:09
tags:
  - LeetCode
---

鉴于有些api刷题经常用到又常常忘记，遂写下这篇文章进行记录

<!--more-->

### 1. Java

#### 1.1 Array和ArrayList互转

##### 1.1.1 利用Stream

```java
// 非装箱类型
List<Integer> arrayList = new ArrayList<Integer>(){{add(3);add(2);add(4);add(2);add(3);add(5);add(4);add(5);}};
// arrayList转array
int[] array = arrayList.stream().mapToInt(Integer::valueOf).toArray();
// array转arrayList
arrayList = Arrays.stream(array).boxed().collect(Collectors.toCollection(ArrayList::new));

// String类型
List<String> arrayList2 = new ArrayList<String>(){{add("3");add("2");add("4");add("2");add("3");add("5");add("4");add("5");}};
// arrayList转array
String[] array2 = arrayList2.stream().toArray(String[]::new);
// array转arrayList
arrayList2 = Arrays.stream(array2).collect(Collectors.toCollection(ArrayList::new));
```

##### 1.1.2 Arrays.toList和ArrayList.toArray()

这种方法只能用于装箱类型

```java
List<String> arrayList2 = new ArrayList<String>(){{add("3");add("2");add("4");add("2");add("3");add("5");add("4");add("5");}};
// arrayList转array
String[] array2 = arrayList2.toArray(new String[0]); 
//或者String[] array2 = arrayList2.toArray(new String[arrayList2.size()]);
// array转arrayList
ArrayList<String> arrayList3 = new ArrayList<>(Arrays.asList(array2)); //直接使用Arrays.asList(T[] a)赋值，返回的列表大小是固定的
```
