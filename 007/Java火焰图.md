# Java 火焰图

- [Java 火焰图](https://colobu.com/2016/08/10/Java-Flame-Graphs/)
- [Java Flame Graphs(Java火焰图英文版原文)](http://www.brendangregg.com/blog/2014-06-12/java-flame-graphs.html)
- [CPU Flame Graphs](http://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html)
- [Saving 13 Million Computational Minutes per Day with Flame Graphs](https://netflixtechblog.com/saving-13-million-computational-minutes-per-day-with-flame-graphs-d95633b6d01f)
- [Java in Flames](https://netflixtechblog.com/java-in-flames-e763b3d32166)
- [FlameGraph github](https://github.com/brendangregg/FlameGraph)

## Java 火焰图 and Java Flame Graphs

- [Java 火焰图](https://colobu.com/2016/08/10/Java-Flame-Graphs/)
- [Java Flame Graphs(Java火焰图英文版原文)](http://www.brendangregg.com/blog/2014-06-12/java-flame-graphs.html)

1. Y 轴是栈的深度 (stack depth)，X 轴是所有的采样点的集合，每个方框代表一个栈帧 (stack frame)。 颜色没有意义，只是随机的选取的。左右顺序也不重要。
2. 可以看到，图里 JavaScript 的引擎 Rhino 占用了 40% 的 CPU，其实 vert.x 是不需要 Rhino 引擎的，所以我们去掉这个引擎可以直接提升接近一倍的性能。

## [CPU Flame Graphs](http://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html)

1. Profiling data can be thousands of lines long, and difficult to comprehend. Flame graphs are a visualization for sampled stack traces,  **which allows hot code-paths to be identified quickly**. 

### Problem

>[Problem] 解释了直接使用 perf（linux）命令会带来的问题： **Too Much Data**；

### Description

- Each box represents a function in the stack
- The y-axis shows stack depth (number of frames on the stack).  **The top box shows the function that was on-CPU.**
- The x-axis spans the sample population. 
- The width of the box shows the total time it was on-CPU or part of an ancestry that was on-CPU (based on sample count).

### Example

>使用 DTrace 采样分析 mysql

```bash
# tcik-10s 表示采样 10s
dtrace -x ustackframes=100 -n 'profile-997 /execname == "mysqld"/ {
    @[ustack()] = count(); 
} tick-10s { exit(0);  }'
```

>后面的还是对比火焰图和 DTrace 的输出

### C

1. 编译器对栈指针寄存器的优化可能会破坏基于帧指针的堆栈遍历，导致无法正常的优化：
	- 编译时开启 `-fno-omit-frame-pointer`
	- On Linux: install debuginfo for the software with DWARF data and use perf's DWARF stack walker.

### C++

同 C

### Java

#### Background

1. 对 Java 生成火焰图的时候，可以通过两种：
	- 系统调用 profiler：这种会跟踪系统层面的函数调用
	- JVM profiler：跟踪 Java 的方法调用
2. linux 的 `perf` 命令不能跟踪 Java 的栈调用，`DTrace` 可以跟踪栈调用，但是也存在其他的问题
3. When running flamegraph.pl I used --color=java, which uses different hues for different types of frames. Green is Java, yellow is C++, orange is kernel, and red is the remainder (native user-level, or kernel modules).
	- 可以看到，火焰图中的 write 调用是黄色的， write 调用完之后的所有 frame 都是橙色的

## [Java in Flames](https://netflixtechblog.com/java-in-flames-e763b3d32166)

![example Flame Graphs](https://miro.medium.com/max/2400/1*-RGVVUyBIdiQo0vvQJNWTA.png)

1. Java mixed-mode flame graphs provide a complete visualization of CPU usage and have just been made possible by a new JDK option: `-XX:+PreserveFramePointer`.
2. example:
	- On the top right you can see a peak of kernel code (colored red) for performing a TCP send (which often leads to a TCP receive while handling the send).
	- Beneath it (colored green) is the Java code responsible. In the middle (colored green) is the Java code that is running on-CPU.
	- **And in the bottom left, a small yellow tower shows CPU time spent in GC.**
3. [How to Read Flame Graphs](http://www.slideshare.net/brendangregg/blazing-performance-with-flame-graphs/40)

## [Saving 13 Million Computational Minutes per Day with Flame Graphs](https://netflixtechblog.com/saving-13-million-computational-minutes-per-day-with-flame-graphs-d95633b6d01f)


