# java profile

## [jstat](https://docs.oracle.com/javase/7/docs/technotes/tools/share/jstat.html)

>jstat - Java Virtual Machine Statistics Monitoring Tool

### SYNOPSIS

jstat [ generalOption | outputOptions vmid [interval[s|ms] [count]] ]

### EXAMPLES

#### Using the gcutil option

```bash
jstat -gcutil 21891 250 7
```

```
  S0     S1     E      O      P     YGC    YGCT    FGC    FGCT     GCT

 12.44   0.00  27.20   9.49  96.70    78    0.176     5    0.495    0.672

 12.44   0.00  62.16   9.49  96.70    78    0.176     5    0.495    0.672

 12.44   0.00  83.97   9.49  96.70    78    0.176     5    0.495    0.672

  0.00   7.74   0.00   9.51  96.70    79    0.177     5    0.495    0.673

  0.00   7.74  23.37   9.51  96.70    79    0.177     5    0.495    0.673

  0.00   7.74  43.82   9.51  96.70    79    0.177     5    0.495    0.673

  0.00   7.74  58.11   9.51  96.71    79    0.177     5    0.495    0.673
```

This example attaches to lvmid 21891 and takes 7 samples at 250 millisecond intervals and displays the output as specified by the -gcutil option.

**The output of this example shows that a young generation collection occurred between the 3rd and 4th sample**. The collection took **0.001 seconds(0.177 - 0.176)** and promoted objects from the eden space (E) to the old space (O), resulting in an increase of old space utilization from 9.49% to 9.51%. Before the collection, the survivor space was 12.44% utilized, but after this collection it is only 7.74% utilized.

#### Repeating the column header string

```bash
jstat -gcnew -h3 21891 250
```

```
 S0C    S1C    S0U    S1U   TT MTT  DSS      EC       EU     YGC     YGCT

  64.0   64.0    0.0   31.7 31  31   32.0    512.0    178.6    249    0.203

  64.0   64.0    0.0   31.7 31  31   32.0    512.0    355.5    249    0.203

  64.0   64.0   35.4    0.0  2  31   32.0    512.0     21.9    250    0.204

 S0C    S1C    S0U    S1U   TT MTT  DSS      EC       EU     YGC     YGCT

  64.0   64.0   35.4    0.0  2  31   32.0    512.0    245.9    250    0.204

  64.0   64.0   35.4    0.0  2  31   32.0    512.0    421.1    250    0.204

  64.0   64.0    0.0   19.0 31  31   32.0    512.0     84.4    251    0.204

 S0C    S1C    S0U    S1U   TT MTT  DSS      EC       EU     YGC     YGCT

  64.0   64.0    0.0   19.0 31  31   32.0    512.0    306.7    251    0.204
```

This example attaches to lvmid 21891 and takes samples at 250 millisecond intervals and displays the output as specified by -gcutil option. In addition, it uses the -h3 option to output the column header after every 3 lines of data.

In addition to showing the repeating header string, this example shows that **between the 2nd and 3rd samples, a young GC occurred**. Its duration was **0.001 seconds(0.204 - 0.203)**. The collection found enough live data that the survivor space 0 utilization (S0U) would would have exceeded the desired survivor Size (DSS). As a result, objects were promoted to the old generation (not visible in this output), and the tenuring threshold (TT) was lowered from 31 to 2.

Another collection occurs between the 5th and 6th samples. This collection found very few survivors and returned the tenuring threshold to 31.

1. S0C 和 S1C 是两个 survivor 的容量，它们永远是一致的；
2. S0U 和 S1U 是两个 survivor 的使用情况，它们应该是在使用中，另外一个为 0；
3. DSS 是 32.0，所以当 S0U 可能会超过这个值的时候会出发一次 YGC。为什么是 32.0 呢？ **因为默认的 SurvivorRation 是 50%**。[Java GC: How is “Desired Survivor Size” calculated?](https://stackoverflow.com/questions/25887715/java-gc-how-is-desired-survivor-size-calculated)
4. [JVM Survivor 行为一探究竟](https://www.jianshu.com/p/f91fde4628a5): 当一个 S 区中各个 age 的对象的总 size 大于或等于 Desired survivor size (TargetSurvivorRatio * S0 / 100)，则重新计算 age，以 age 和 MaxTenuringThreshold 两者的最小值为准；

[Tenuring Threshold](https://www.jianshu.com/p/7602c0032e3a)

### JVM Survivor

```java
public class GcSurvivorTest {

    public static void main(String[] args) throws InterruptedException {

        // 这两个对象不会被回收, 用于在s0和s1不断来回拷贝增加age直到达到PretenureSizeThreshold晋升到old
        byte[] byte1m_1 = new byte[1 * 512 * 1024];
        byte[] byte1m_2 = new byte[1 * 512 * 1024];

        // YoungGC后, byte1m_1 和 byte1m_2的age为1
        youngGc(1);
        Thread.sleep(3000);

        // 再次YoungGC后, byte1m_1 和 byte1m_2的age为2
        youngGc(1);
        Thread.sleep(3000);

        // 第三次YoungGC后, byte1m_1 和 byte1m_2的age为3
        youngGc(1);
        Thread.sleep(3000);

        // 这次再ygc时, 由于byte1m_1和byte1m_2的年龄已经是3，且MaxTenuringThreshold=3, 所以这两个对象会晋升到Old区域,且ygc后, s0(from)和s1(to)空间中的对象被清空
        youngGc(1);
        Thread.sleep(3000);

        // main方法中分配的对象不会被回收, 不断分配是为了达到TargetSurvivorRatio这个比例指定的值, 即5M*60%=3M(Desired survivor size)，说明: 5M为S区的大小，60%为TargetSurvivorRatio参数指定，如下三个对象分配后就能够达到Desired survivor size
        byte[] byte1m_4 = new byte[1 * 1024 * 1024];
        byte[] byte1m_5 = new byte[1 * 1024 * 1024];
        byte[] byte1m_6 = new byte[1 * 1024 * 1024];

        // 这次ygc时, 由于s区已经占用达到了60%(-XX:TargetSurvivorRatio=60), 所以会重新计算对象晋升的age，计算公式为：min(age, MaxTenuringThreshold) = 1
        youngGc(1);
        Thread.sleep(3000);

        // 由于前一次ygc时算出age=1, 所以这一次再ygc时, byte1m_4, byte1m_5, byte1m_6就会晋升到Old区, 而不需要等MaxTenuringThreshold这么多次, 此次ygc后, s0(from)和s1(to)空间中对象再次被清空, 对象全部晋升到old
        youngGc(1);
        Thread.sleep(3000);

        System.out.println("hello world");
    }

    private static void youngGc(int ygcTimes){
        for(int i=0; i<ygcTimes*40; i++) {
            byte[] byte1m = new byte[1 * 1024 * 1024];
        }
    }
}
```

>代码配套的 JVM 参数 (Eden: 40M, S0/S1: 5M, Old: 150M):
><br/>
>-verbose:gc -Xmx200M -Xmn50M -XX:TargetSurvivorRatio=60 -XX:+PrintTenuringDistribution -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:MaxTenuringThreshold=3

1. MaxTenuringThreshold 表示最多而不是一定，也就是说某个对象的 age 其实并不是一定要达到这个值才会晋升到 Old 的
2. 在上面的例子中，byte1m_1 和 byte1m_2 是因为回收次数达到了 TT 而被提升到老年代；
3. byte1m_4, byte1m_5, byte1m_6 是因为，占用的数量超过了 TargetSurvivorRatio，但是又没有达到提升到老年代的 TT。所以 GC 为了减少 survivor 区的内存占用到 TargetSurvivorRatio，就只有暂时的先降低 TT，当 survivor 区的内存占用少于 TargetSurvivorRatio 之后，GC 又会还原 TT 到设置的值。

>总结一下就是，有两种情况下 GC 会将 survivor 区的提升到老年代：
><br/>
>1. survivor 区中的对象的 age 达到了 TenuringThreshold；
><br/>
>2. survivor 区中的对象的 age 没有达到 TenuringThreshold，但是 survivor 区中的内存占用已经超过了 TenuringThreshold。这个时候 GC 为了降低 survivor 区的内存占用，就必须先临时的降低 TenuringThreshold，这样可以将 survivor 区的部分对象提升到老年代，当这些对象提升到老年代了之后， survivor 区又空出来了，那么 GC 会将 TenuringThreshold 还原到 MaxTenuringThreshold

## [jhat](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jhat.html)

>[OpenJDK 9: Life Without HPROF and jhat](https://www.infoq.com/news/2015/12/OpenJDK-9-removal-of-HPROF-jhat/)
><br/>
>**HPROF was not intended to be a production tool; it has been superseded by various other alternatives as documented below:**
><br/>
>According to JEP 241, jhat is an experimental, unsupported, and out-of-date tool. Although the JEP doesn’t specify any particular replacement tool, InfoQ would once again point users to Java `VisualVM` for heap dump creation, visualization and analysis.

---

**According to JEP 240, this functionality is superseded by the same functionality in the JVM by using the command line utilities such as ‘jcmd’ and ‘jmap’ as shown below:**

```bash
jcmd GC.heap_dump filename=<filename>
```

or

```bash
jmap [option] <pid>

where <option>:

-dump:<dump-options> to dump java heap in hprof binary format

            dump-options:

             live         dump only live objects; if not specified,

                          all objects in the heap are dumped.

             format=b     binary format

             file=<file>  dump heap to <file>

Example: jmap -dump:live,format=b,file=heap.bin <pid>
```

### Synopsis

```bash
jhat [ options ] heap-dump-file
```

>heap-dump-file
><br/>
>Java binary heap dump file to be browsed. For a dump file that contains multiple heap dumps, you can specify which dump in the file by appending #<number> to the file name, for example, myfile.hprof#3.

### Description

The `jhat` command parses a Java heap dump file and starts a web server. The jhat command lets you to browse heap dumps with your favorite web browser. 

There are several ways to generate a Java heap dump:

1. Use the `jmap -dump` option to obtain a heap dump at runtime.
2. Heap dump is generated when an **OutOfMemoryError** is thrown by specifying the `-XX:+HeapDumpOnOutOfMemoryError` Java Virtual Machine (JVM) option.
3. Use the `hprof` command. See the [HPROF](https://docs.oracle.com/javase/8/docs/technotes/samples/hprof.html): A Heap/CPU Profiling Tool at

## [jmap](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jmap.html)

>Prints shared object memory maps or heap memory details for a process, core file, or remote debug server. This command is experimental and unsupported.
><br/>
>**['Shared Object Memory' vs 'Heap Memory' - Java](https://stackoverflow.com/questions/6855112/shared-object-memory-vs-heap-memory-java)**

### Synopsis

- jmap [ options  ] pid
- jmap [ options  ] executable core
- jmap [ options  ] [ pid  ] server-id@ ] remote-hostname-or-IP

### Options

| option                                | desc                                                                                                                                                                                                                                                                                   |
|---------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| no option                           | When no option is used, the jmap command prints shared object mappings. For each shared object loaded in the target JVM, the start address, size of the mapping, and the full path of the shared object file are printed. This behavior is similar to the Oracle Solaris pmap utility. |
| -dump:[live,] format=b, file=filename | Dumps the Java heap in `hprof` binary format to filename. The live suboption is optional, but when specified, only the active objects in the heap are dumped. **To browse the heap dump, you can use the jhat(1) command to read the generated file.**                                 |
| -heap                                 | Prints a heap summary of the **garbage collection used**, the head configuration, and generation-wise heap usage. In addition, the number and size of interned Strings are printed. |
| histo | Prints a histogram of the heap. **For each Java class, the number of objects, memory size in bytes, and the fully qualified class names are printed**. The JVM internal class names are printed with an asterisk (*) prefix. If the live suboption is specified, then only active objects are counted. |

#### -heap

```
using thread-local object allocation.
Parallel GC with 4 thread(s)

Heap Configuration:
   MinHeapFreeRatio = 0
   MaxHeapFreeRatio = 100
   MaxHeapSize      = 2147483648 (2048.0MB)
   NewSize          = 1310720 (1.25MB)
   MaxNewSize       = 17592186044415 MB
   OldSize          = 5439488 (5.1875MB)
   NewRatio         = 2
   SurvivorRatio    = 8
   PermSize         = 21757952 (20.75MB)
   MaxPermSize      = 85983232 (82.0MB)
   G1HeapRegionSize = 0 (0.0MB)

Heap Usage:
PS Young Generation
Eden Space:
   capacity = 34603008 (33.0MB)
   used     = 1384360 (1.3202285766601562MB)
   free     = 33218648 (31.679771423339844MB)
   4.000692656545928% used
From Space:
   capacity = 5242880 (5.0MB)
   used     = 0 (0.0MB)
   free     = 5242880 (5.0MB)
   0.0% used
To Space:
   capacity = 5242880 (5.0MB)
   used     = 0 (0.0MB)
   free     = 5242880 (5.0MB)
   0.0% used
PS Old Generation
   capacity = 89128960 (85.0MB)
   used     = 0 (0.0MB)
   free     = 89128960 (85.0MB)
   0.0% used
PS Perm Generation
   capacity = 22020096 (21.0MB)
   used     = 2647888 (2.5252227783203125MB)
   free     = 19372208 (18.474777221679688MB)
   12.024870372953869% used

678 interned Strings occupying 44104 bytes.
```

#### histo

1. [What kind of Java type is “\[B”?](https://stackoverflow.com/questions/4606864/what-kind-of-java-type-is-b)
2. [JNI Types and Data Structures](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/types.html)

```
 num     #instances         #bytes  class name
----------------------------------------------
   1:             9        1661000  [I
   2:          5914         762256  <methodKlass>
   3:          5914         675200  <constMethodKlass>
   4:           398         471016  <constantPoolKlass>
   5:           362         286784  <constantPoolCacheKlass>
   6:           398         274152  <instanceKlassKlass>
   7:          1446         170352  [C
   8:           719         126784  [B
   9:           458          44848  java.lang.Class
  10:           673          43768  [[I
  11:           808          38784  java.nio.HeapCharBuffer
  ...
Total         20851        4725856
```

## [jstack](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jstack.html)

>Prints `Java thread stack` traces for a Java process, core file, or remote debug server. This command is experimental and unsupported.

### Synopsis

- jstack [ options ] pid
- jstack [ options ] executable core
- jstack [ options ] [ server-id@ ] remote-hostname-or-IP

### Description

>The `jstack` command **prints Java stack traces of Java threads** for a specified Java process, core file, or remote debug server. 

```
2020-02-09 17:37:01
Full thread dump Java HotSpot(TM) 64-Bit Server VM (24.80-b11 mixed mode):

"Attach Listener" daemon prio=5 tid=0x00007fbd9a836800 nid=0xd07 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Service Thread" daemon prio=5 tid=0x00007fbd9b02a000 nid=0x4303 runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread1" daemon prio=5 tid=0x00007fbd9b029000 nid=0x4403 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread0" daemon prio=5 tid=0x00007fbd9b014000 nid=0x4603 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Signal Dispatcher" daemon prio=5 tid=0x00007fbd9b022000 nid=0x4803 runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Finalizer" daemon prio=5 tid=0x00007fbd9a829800 nid=0x5003 in Object.wait() [0x0000700003172000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	- waiting on <0x00000007d5504858> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:135)
	- locked <0x00000007d5504858> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:151)
	at java.lang.ref.Finalizer$FinalizerThread.run(Finalizer.java:209)

"Reference Handler" daemon prio=5 tid=0x00007fbd9a829000 nid=0x5103 in Object.wait() [0x000070000306f000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	- waiting on <0x00000007d5504470> (a java.lang.ref.Reference$Lock)
	at java.lang.Object.wait(Object.java:503)
	at java.lang.ref.Reference$ReferenceHandler.run(Reference.java:133)
	- locked <0x00000007d5504470> (a java.lang.ref.Reference$Lock)

"main" prio=5 tid=0x00007fbd9a806000 nid=0x2803 waiting on condition [0x0000700002a5d000]
   java.lang.Thread.State: TIMED_WAITING (sleeping)
	at java.lang.Thread.sleep(Native Method)
	at Hello.main(Hello.java:10)

"VM Thread" prio=5 tid=0x00007fbd9a826800 nid=0x5203 runnable 

"GC task thread#0 (ParallelGC)" prio=5 tid=0x00007fbd99800800 nid=0x2007 runnable 

"GC task thread#1 (ParallelGC)" prio=5 tid=0x00007fbd99805800 nid=0x2a03 runnable 

"GC task thread#2 (ParallelGC)" prio=5 tid=0x00007fbd99806000 nid=0x2c03 runnable 

"GC task thread#3 (ParallelGC)" prio=5 tid=0x00007fbd99806800 nid=0x5403 runnable 

"VM Periodic Task Thread" prio=5 tid=0x00007fbd9b013800 nid=0x4203 waiting on condition 

JNI global references: 108
```

## [jcmd](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr006.html)

>The jcmd utility is used to send diagnostic command requests to the JVM, where these requests are useful for controlling Java Flight Recordings, troubleshoot, and diagnose JVM and Java Applications. It must be used on the same machine where the JVM is running, and have the same effective user and group identifiers that were used to launch the JVM.

### Synopsis

- jcmd [-l|-h|-help]
- jcmd pid|main-class PerfCounter.print
- jcmd pid|main-class -f filename
- jcmd pid|main-class command[ arguments]

### Description

>To invoke diagnostic commands from a remote machine or with different identifiers, you can use the `com.sun.management.DiagnosticCommandMBean` interface. For more information about the DiagnosticCommandMBean interface, see the API documentation at http://docs.oracle.com/javase/8/docs/jre/api/management/extension/com/sun/management/DiagnosticCommandMBean.html

- Perfcounter.print: Prints the **performance counters(总执行时间，存活的线程数等信息，不包含其他的信息)** available for the specified Java process. The list of performance counters might vary with the Java process.
- **command [arguments]**: The command to be sent to the specified Java process. The list of available diagnostic commands for a given process can be obtained by sending the help command to this process. 

### Usage

```bash
> jcmd
5485 sun.tools.jcmd.JCmd
2125 MyProgram
 
> jcmd MyProgram help (or "jcmd 2125 help")
2125:
The following commands are available:
JFR.stop
JFR.start
JFR.dump
JFR.check
VM.native_memory
VM.check_commercial_features
VM.unlock_commercial_features
ManagementAgent.stop
ManagementAgent.start_local
ManagementAgent.start
Thread.print
GC.class_stats
GC.class_histogram
GC.heap_dump
GC.run_finalization
GC.run
VM.uptime
VM.flags
VM.system_properties
VM.command_line
VM.version
help
 
> jcmd MyProgram help Thread.print
2125:
Thread.print
Print all threads with stacktraces.
 
Impact: Medium: Depends on the number of threads.
 
Permission: java.lang.management.ManagementPermission(monitor)
 
Syntax : Thread.print [options]
 
Options: (options must be specified using the <key> or <key>=<value> syntax)
        -l : [optional] print java.util.concurrent locks (BOOLEAN, false)
 
> jcmd MyProgram Thread.print
2125:
2014-07-04 15:58:56
Full thread dump Java HotSpot(TM) 64-Bit Server VM (25.0-b69 mixed mode):
...
```

### options

- Thread.print 等同于 `jstack`
- GC.class_histogram 等同于 `jmap histo` 
