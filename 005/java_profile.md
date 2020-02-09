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
