# Arthas - Java 线上问题定位处理的终极利器

## Arthas 介绍

- [arthas 开源地址](https://github.com/alibaba/arthas)
- [Arthas 用户文档](https://alibaba.github.io/arthas/)

## Arthas 怎么用

### web console

Arthas 目前支持 Web Console，在成功启动连接进程之后就已经自动启动，可以直接访问 `http://127.0.0.1:8563/` 访问，页面上的操作模式和控制台完全一样。

### 常用命令

| 命令        | 说明                                                                   |
|-------------|------------------------------------------------------------------------|
| dashboard   | 当前系统的实时数据面板                                                 |
| **thread**  | 查看当前 JVM 的线程堆栈信息                                            |
| **watch**   | 方法执行数据观测                                                       |
| **trace**   | 方法内部调用路径，并输出方法路径上的每个节点上耗时                     |
| **stack**   | 输出当前方法被调用的调用路径                                           |
| **tt**      | 记录下指定方法调用的入参和返回信息，并能对这些不同的时间下调用进行观测 |
| **monitor** | 方法执行监控                                                           |
| jvm         | 查看当前 JVM 信息                                                      |

### 退出

**调用 `shutdown` 退出自动重置所有类**

## 常用操作

### 模拟代码

```java
import java.util.HashSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * <p>
 * Arthas Demo
 */
public class Arthas {

    private static HashSet<String> hashSet = new HashSet<String>();
    /** 线程池，大小1*/
    private static ExecutorService executorService = Executors.newFixedThreadPool(1);

    public static void main(String[] args) {
        // 模拟 CPU 过高，这里注释掉了，测试时可以打开
        // cpu();
        // 模拟线程阻塞
        thread();
        // 模拟线程死锁
        deadThread();
        // 不断的向 hashSet 集合增加数据
        addHashSetThread();
    }

    /**
     * 不断的向 hashSet 集合添加数据
     */
    public static void addHashSetThread() {
        // 初始化常量
        new Thread(() -> {
            int count = 0;
            while (true) {
                try {
                    hashSet.add("count" + count);
                    Thread.sleep(10000);
                    count++;
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

    public static void cpu() {
        cpuHigh();
        cpuNormal();
    }

    /**
     * 极度消耗CPU的线程
     */
    private static void cpuHigh() {
        Thread thread = new Thread(() -> {
            while (true) {
                System.out.println("cpu start 100");
            }
        });
        // 添加到线程
        executorService.submit(thread);
    }

    /**
     * 普通消耗CPU的线程
     */
    private static void cpuNormal() {
        for (int i = 0; i < 10; i++) {
            new Thread(() -> {
                while (true) {
                    System.out.println("cpu start");
                    try {
                        Thread.sleep(3000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }).start();
        }
    }

    /**
     * 模拟线程阻塞,向已经满了的线程池提交线程
     */
    private static void thread() {
        Thread thread = new Thread(() -> {
            while (true) {
                System.out.println("thread start");
                try {
                    Thread.sleep(3000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });
        // 添加到线程
        executorService.submit(thread);
    }

    /**
     * 死锁
     */
    private static void deadThread() {
        /** 创建资源 */
        Object resourceA = new Object();
        Object resourceB = new Object();
        // 创建线程
        Thread threadA = new Thread(() -> {
            synchronized (resourceA) {
                System.out.println(Thread.currentThread() + " get ResourceA");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread() + "waiting get resourceB");
                synchronized (resourceB) {
                    System.out.println(Thread.currentThread() + " get resourceB");
                }
            }
        });

        Thread threadB = new Thread(() -> {
            synchronized (resourceB) {
                System.out.println(Thread.currentThread() + " get ResourceB");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread() + "waiting get resourceA");
                synchronized (resourceA) {
                    System.out.println(Thread.currentThread() + " get resourceA");
                }
            }
        });
        threadA.start();
        threadB.start();
    }
}
```

### dashboard

输入 `dashboard` 可以看到有两个线程处于 `BLOCKED` 的状态

>11      Thread-1                main             5       `BLOCKED` 6       0:0     false   false
><br/>
>12      Thread-2                main             5       `BLOCKED` 2       0:0     false   false

### thread

>通过输入 `thread` 我们可以看到，有一个线程的 CPU 占用非常高

```
Threads Total: 27, NEW: 0, RUNNABLE: 8, BLOCKED: 2, WAITING: 4, TIMED_WAITING: 13, TERMINATED: 0
ID      NAME                    GROUP            PRIORIT STATE   %CPU    TIME    INTERRU DAEMON
10      pool-1-thread-1         main             5       RUNNABL 99      2:34    false   false
```

>所以我们可以通过输入 `thread 10` 来查看线程的方法执行信息

```
[arthas@10521]$ thread 10
"pool-1-thread-1" Id=10 RUNNABLE
    at java.io.FileOutputStream.writeBytes(Native Method)
    at java.io.FileOutputStream.write(FileOutputStream.java:326)
    at java.io.BufferedOutputStream.flushBuffer(BufferedOutputStream.java:82)
    at java.io.BufferedOutputStream.flush(BufferedOutputStream.java:140)
    -  locked java.io.BufferedOutputStream@33e489d2
    at java.io.PrintStream.write(PrintStream.java:482)
    -  locked java.io.PrintStream@13580aea
    at sun.nio.cs.StreamEncoder.writeBytes(StreamEncoder.java:221)
    at sun.nio.cs.StreamEncoder.implFlushBuffer(StreamEncoder.java:291)
    at sun.nio.cs.StreamEncoder.flushBuffer(StreamEncoder.java:104)
    -  locked java.io.OutputStreamWriter@25569289
    at java.io.OutputStreamWriter.flushBuffer(OutputStreamWriter.java:185)
    at java.io.PrintStream.write(PrintStream.java:527)
    -  locked java.io.PrintStream@13580aea
    at java.io.PrintStream.print(PrintStream.java:669)
    at java.io.PrintStream.println(PrintStream.java:806)
    -  locked java.io.PrintStream@13580aea
    at Arthas.lambda$cpuHigh$1(Arthas.java:59)
    at Arthas$$Lambda$1/303563356.run(Unknown Source)
    at java.lang.Thread.run(Thread.java:748)
    at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
    at java.util.concurrent.FutureTask.run(FutureTask.java:266)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
    at java.lang.Thread.run(Thread.java:748)

    Number of locked synchronizers = 1
    - java.util.concurrent.ThreadPoolExecutor$Worker@6ce253f1

Affect(row-cnt:0) cost in 17 ms.
```

>通过 thread -n [显示的线程个数] ，就可以排列出 CPU 使用率 Top N 的线程。

#### 线程池线程状态

- RUNNING
- TIMED_WAITING ： 限时等待
- WAITING：永久等待，直到因为接收到其他信号而激活
- BLOCKED

#### 查看死锁线程

`thread -b` 直接查看死锁线程 

### jad

>假设这是一个线程环境，当怀疑当前运行的代码不是自己想要的代码时，可以直接反编译出代码，也可以选择性的查看类的字段或方法信息。

```bash
jad Arthas

# 只反编译一个方法
jad Arthas deadThread
```

```java
ClassLoader:
+-sun.misc.Launcher$AppClassLoader@2a139a55
  +-sun.misc.Launcher$ExtClassLoader@5f479456

Location:
/Users/dhy/code/hangyudu/note/006/

private static void deadThread() {
	// ...
}

Affect(row-cnt:5) cost in 281 ms.
```

### ognl

>执行 ognl 表达式

- [Arthas 的一些特殊用法文档说明](https://github.com/alibaba/arthas/issues/71)
- [OGNL 表达式官方指南](https://commons.apache.org/proper/commons-ognl/language-guide.html)

```bash
# 调用静态方法
ognl '@java.lang.System@out.println("hello")'

# 获取静态类的静态字段
ognl '@demo.MathGame@random'

# 获取 java.home 和 java.runtime.name 的值并返回
ognl '#value1=@System@getProperty("java.home"), #value2=@System@getProperty("java.runtime.name"), {#value1, #value2}'
```

### sc

>**“Search-Class”** 的简写，查看 JVM 已加载的类信息

### sm

>**“Search-Method”** 的简写,查看已加载类的方法信息

### heapdump

>dump java heap, 类似 jmap 命令的 heap dump 功能。

### mc, redefine

- mc: memory compiler, 编译.java文件生成.class
- redefine: **加载外部的.class文件，redefine jvm 已加载的类。**

1. redefine 后的原来的类不能恢复，redefine 有可能失败
2. `reset` 命令的 `redefine` 的类无效。如果想重置，需要redefine原始的字节码。
3. redefine命令和jad/watch/trace/monitor/tt等命令会冲突。执行完redefine之后，如果再执行上面提到的命令，则会把redefine的字节码重置。 原因是 jdk 本身 redefine 和 Retransform 是不同的机制，同时使用两种机制来更新字节码，只有最后修改的会生效。

>配合 jad 命令，我们甚至可以动态的修改代码。
><br/>
>我们先通过 jad 反编译一个 Ognl.class 到 Ognl.java，随后编辑 Ognl.java 文件。
><br/>
>编辑完成之后，使用 mc 编译并生成 Ognl.class
><br/>
>redfine 重新加载 Ognl.class

### monitor

>对匹配 **class-pattern／method-pattern** 的类、方法的调用进行监控。

### watch

>方法执行数据观测

1. 能观察到的范围为：返回值、抛出异常、入参，通过编写 OGNL 表达式进行对应变量的查看。

### trace

>方法内部调用路径，并输出方法路径上的每个节点上耗时

trace 命令能主动搜索 **class-pattern／method-pattern** 对应的方法调用路径，渲染和统计整个调用链路上的所有性能开销和追踪调用链路。

### stack

>输出当前方法被调用的调用路径

很多时候我们都知道一个方法被执行，但这个方法被执行的路径非常多，或者你根本就不知道这个方法是从那里被执行了，此时你需要的是 stack 命令。

### tt

>方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测

watch 虽然很方便和灵活，但需要提前想清楚观察表达式的拼写，这对排查问题而言要求太高，因为很多时候我们并不清楚问题出自于何方，只能靠蛛丝马迹进行猜测。

```bash
# 首先通过 tt 来采样我们的观察结果
# 输出 Ognl 的 sayHello 方法调用时间超过 0.1ms 的方法调用
tt -t Ognl sayHello '#cost > 0.1' -n 2

# 根据 index 查看方法的详细调用情况
tt -i 1004
```

```
 INDE  TIMESTAMP      COST(m  IS-R  IS-E  OBJECT     CLASS                 METHOD
 X                    s)      ET    XP
-------------------------------------------------------------------------------------------------
 1004  2020-02-09 23  1.1390  true  fals  0x7d4991a  Ognl                  sayHello
       :08:51         28            e     d



[arthas@27681]$ tt -i 1004
 INDEX         1004
 GMT-CREATE    2020-02-09 23:08:51
 COST(ms)      1.139028
 OBJECT        0x7d4991ad
 CLASS         Ognl
 METHOD        sayHello
 IS-RETURN     true
 IS-EXCEPTION  false
 RETURN-OBJ    @Integer[0]
Affect(row-cnt:1) cost in 7 ms.
```

#### 重载方法

>我们可以通过 OGNL 表达式来观察重载方法

#### 检索调用记录 


```bash
# 查看调动记录
tt -l

 INDEX   TIMESTAMP            COST(ms)  IS-RET  IS-EXP   OBJECT         CLASS                          METHOD
-------------------------------------------------------------------------------------------------------------------------------------
 1000    2018-12-04 11:15:38  1.096236  false   true     0x4b67cf4d     MathGame                       primeFactors
 1001    2018-12-04 11:15:39  0.191848  false   true     0x4b67cf4d     MathGame                       primeFactors
 1002    2018-12-04 11:15:40  0.069523  false   true     0x4b67cf4d     MathGame                       primeFactors
 1003    2018-12-04 11:15:41  0.186073  false   true     0x4b67cf4d     MathGame                       primeFactors
 1004    2018-12-04 11:15:42  17.76437  true    false    0x4b67cf4d     MathGame                       primeFactors
                              9
 1005    2018-12-04 11:15:43  0.4776    false   true     0x4b67cf4d     MathGame                       primeFactors
Affect(row-cnt:6) cost in 4 ms.

# 搜索调用记录
tt -s 'method.name=="primeFactors"'
```

#### 重做一次调用 

tt 命令由于保存了当时调用的所有现场信息，所以我们可以自己主动对一个 INDEX 编号的时间片自主发起一次调用，从而解放你的沟通成本。此时你需要 -p 参数。通过 --replay-times 指定 调用次数，通过 --replay-interval 指定多次调用间隔 (单位 ms, 默认 1000ms)

### **profile**

>使用 [async-profiler](https://github.com/jvm-profiling-tools/async-profiler) 生成火焰图

```bash
# 启动采样
profiler start

# 获取已采集的 sample 的数量 
profiler getSamples

# 查看 profiler 状态 
profiler status

# 停止 profiler 并生成 svg 格式结果
profiler stop
```

#### 也可以分析出除了 CPU 之外的其他数据

```bash
# 分析 alloc
profiler start --event alloc
```
