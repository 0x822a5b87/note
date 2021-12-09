# window

## reference

[Sliding Vs Tumbling Windows](https://stackoverflow.com/questions/12602368/sliding-vs-tumbling-windows)
[Flink 原理与实现：Window 机制](http://wuchong.me/blog/2016/05/25/flink-internals-window-mechanism/)

## Sliding Vs Tumbling Windows 

1. Tumbling repeats at a non-overlapping interval.
2. Hopping is simlar to tumbling, but hopping generally has an overlapping interveral.
3. Time Sliding triggers at regular interval.
4. Eviction Sliding triggers on a count.

Below is a graphical representation showing different types of Data Stream Management System (DSMS) window - tumbling, hopping, timing policy sliding, and eviction policy(count) sliding. I used the above example to create the image (making assumptions).

![mm06A](./mm06A.jpeg)

## Flink 原理与实现：Window 机制

>窗口可以是时间驱动的（Time Window，例如：每30秒钟），也可以是数据驱动的（Count Window，例如：每一百个元素）。一种经典的窗口分类可以分成：翻滚窗口（Tumbling Window，无重叠），滚动窗口（Sliding Window，有重叠），和会话窗口（Session Window，活动间隙）。


![TB1bwsTJVXXXXaBaXXXXXXXXXXX](./TB1bwsTJVXXXXaBaXXXXXXXXXXX.png)
