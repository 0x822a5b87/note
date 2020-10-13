# trident API overview

[trident API overview](http://storm.apache.org/releases/current/Trident-API-Overview.html)

The core data model in Trident is the "Stream", processed as a series of batches. A stream is partitioned among the nodes in the cluster, and operations applied to a stream are applied in parallel across each partition.

There are five kinds of operations in Trident:

1. Operations that apply locally to each partition and cause **no network transfer**
2. `Repartitioning operations` that repartition a stream but otherwise don't change the contents (involves network transfer)
3. `Aggregation operations` that do network transfer as part of the operation
4. operations on grouped streams
5. Merges and joins

## Partition-local operations

Prtition-local operations involve no network transfer and are applied to each batch partition independently.

### Functions

1. 如果我们 emit，那么将是在原来的 tuple 基础上追加 fields。
2. 如果我们不 emit，那么这个 tuple 就被过滤掉了。
3. 假设上游的 Stream 包含了 `new Fields("a", "b", "c")`，那么我们可以在声明的时候通过 `mystream.each(new Fields("b"), new MyFunction(), new Fields("d")))` 来声明一个参数作为输入。**但是，在实际上，我们 emit 的时候仍然会带上另外两个参数**。

A function takes in a set of input fields and emits zero or more tuples as output. **The fields of the output tuple are appended to the original input tuple in the stream**. If a function emits no tuples, the original input tuple is filtered out. Otherwise, the input tuple is duplicated for each output tuple. Suppose you have this function:

#### FunctionSpout

```java
public class FunctionSpout extends BaseRichSpout {

    private final static Logger LOG = LoggerFactory.getLogger(FunctionSpout.class);

    private static final long serialVersionUID = -60323133508650657L;

    private final static int MAX_BATCH = 1;
    private       int        curBatch  = 0;

    private SpoutOutputCollector collector;

    private int[][] tuples = {
            {1, 2, 3},
            {4, 1, 6},
            {3, 0, 8}
    };

    @Override
    public void open(Map map, TopologyContext topologyContext, SpoutOutputCollector spoutOutputCollector) {
        LOG.info("open test spout");
        collector = spoutOutputCollector;
    }

    @Override
    public void nextTuple() {
        if (curBatch < MAX_BATCH) {
            for (int[] nums : tuples) {
                Values values = new Values();
                for (int n : nums) {
                    values.add(n);
                }
                collector.emit(values);
            }
            curBatch++;
        }
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer outputFieldsDeclarer) {
        outputFieldsDeclarer.declare(new Fields("a", "b", "c"));
    }
}
```

#### AddFunction

```java
public class AddFunction extends BaseFunction {
    @Override
    public void execute(TridentTuple tuple, TridentCollector collector) {
        for(int i=0; i < tuple.getInteger(0); i++) {
            collector.emit(new Values(i));
        }
    }
}
```

#### OutputFunction

```java
public class OutputFunction extends BaseFunction {

    private final static Logger LOG = LoggerFactory.getLogger(OutputFunction.class);

    @Override
    public void execute(TridentTuple tuple, TridentCollector collector) {
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        for (int i = 0; i < tuple.size(); ++i) {
            if (i != 0) {
                sb.append(",");
            }
            sb.append(tuple.get(i));
        }
        sb.append("]");
        LOG.info(sb.toString());
    }
}
```

#### Topo

>下面这种写法是错误的，因为我们只需要在 output 的位置声明新增的 tuple 即可

```java
        FunctionSpout spout = new FunctionSpout();
        topology.newStream("spout", spout).parallelismHint(1)
                .each(new Fields("a", "b", "c"), new AddFunction(), new Fields("a", "b", "c", "d"))
                .each(new Fields("b"), new AddFunction(), new Fields("d"))
                .each(new Fields("a", "b", "c", "d"), new OutputFunction(), new Fields());
```

>下面代码输出将是：因为这个时候我们通过 `tuple.getInteger(0)` 得到的数据是输入 tuple 的 `a`

```
18:01:56.977 INFO  com.xxx.storm.trident.function.FunctionSpout - open test spout
18:01:56.990 INFO  com.xxx.storm.trident.OutputFunction - [1,2,3,0]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [4,1,6,0]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [4,1,6,1]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [4,1,6,2]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [4,1,6,3]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [3,0,8,0]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [3,0,8,1]
18:01:56.991 INFO  com.xxx.storm.trident.OutputFunction - [3,0,8,2]
```

```java
        FunctionSpout spout = new FunctionSpout();
        topology.newStream("spout", spout).parallelismHint(1)
                .each(new Fields("b"), new AddFunction(), new Fields("d"))
                .each(new Fields("a", "b", "c", "d"), new OutputFunction(), new Fields());
```

>下面的代码输出如下：这个时候我们通过 `tuple.getInteger(0)` 得到的数据是 tuple 的 `b`。

```
18:03:40.570 INFO  com.xxx.storm.trident.function.FunctionSpout - open test spout
18:03:40.572 INFO  com.xxx.storm.trident.OutputFunction - [1,2,3,0]
18:03:40.573 INFO  com.xxx.storm.trident.OutputFunction - [1,2,3,1]
18:03:40.573 INFO  com.xxx.storm.trident.OutputFunction - [4,1,6,0]
```

```java
        FunctionSpout spout = new FunctionSpout();
        topology.newStream("spout", spout).parallelismHint(1)
                .each(new Fields("b"), new AddFunction(), new Fields("d"))
                .each(new Fields("a", "b", "c", "d"), new OutputFunction(), new Fields());

```

#### project

>可以通过 `project` 来保留那些我们感兴趣的字段以保证数据无异常。

```java
        FunctionSpout spout = new FunctionSpout();
        topology.newStream("spout", spout).parallelismHint(1)
                .each(new Fields("a", "b", "c"), new AddFunction(), new Fields("d"))
                .project(new Fields("d"))
                .each(new Fields("d"), new OutputFunction(), new Fields());

```

### Filters

Filters take in a tuple as input and decide whether or not to keep that tuple or not. Suppose you had this filter:

### map and flatMap

1. `map` returns a stream consisting of the result of applying the given mapping function to the tuples of the stream. This can be used to apply a one-one transformation to the tuples.
2. `flatMap` is similar to `map` but has the effect of applying a one-to-many transformation to the values of the stream, and then flattening the resulting elements into a new stream.

```java
public class UpperCase extends MapFunction {
 @Override
 public Values execute(TridentTuple input) {
   return new Values(input.getString(0).toUpperCase());
 }
}
```

```java
public class Split extends FlatMapFunction {
  @Override
  public Iterable<Values> execute(TridentTuple input) {
    List<Values> valuesList = new ArrayList<>();
    for (String word : input.getString(0).split(" ")) {
      valuesList.add(new Values(word));
    }
    return valuesList;
  }
}
```

**If you don't pass output fields as parameter, map and flatMap `preserves` the input fields to output fields.**

If you want to apply MapFunction or FlatMapFunction with replacing old fields with new output fields, you can call map / flatMap with additional Fields parameter as follows,


```java
mystream.map(new UpperCase(), new Fields("uppercased"));
mystream.flatMap(new Split(), new Fields("word"));
```

### peek

`peek` can be used to perform an additional action on each trident tuple as they flow through the stream. This could be useful for debugging to see the tuples as they flow past a certain point in a pipeline.

For example, the below code would print the result of converting the words to uppercase before they are passed to groupBy

```java
mystream.flatMap(new Split()).map(new UpperCase())
         .peek(new Consumer() {
                @Override
                public void accept(TridentTuple input) {
                  System.out.println(input.getString(0));
                }
         })
         .groupBy(new Fields("word"))
         .persistentAggregate(new MemoryMapState.Factory(), new Count(), new Fields("count"))
```

### min and minBy

`min` and `minBy` operations return minimum value `on each partition of a batch of tuples` in a trident stream.

### max and maxBy

`max` and `maxBy` operations return maximum value on each partition of a batch of tuples in a trident stream.

### Windowing

Trident streams can process tuples in batches which are of the same window and **emit aggregated result** to the next operation. There are two kinds of windowing supported which are based on processing time or tuples count: 

1. Tumbling window
2. Sliding window

**tumbling window 可以看做 sliding window 的一个特殊实例，当我们的 windowCount == slideCount 时，我们获取到的滑动窗口就是 tumbling window**

tumbling window 不会有重叠。

#### tumbling window

Tuples are grouped in a single window based on processing time or count.  **Any tuple belongs to only one of the windows.**

```java
    /**
     * Returns a stream of tuples which are aggregated results of a tumbling window with every {@code windowCount} of tuples.
     */
    public Stream tumblingWindow(int windowCount, WindowsStoreFactory windowStoreFactory,
                                      Fields inputFields, Aggregator aggregator, Fields functionFields);

    /**
     * Returns a stream of tuples which are aggregated results of a window that tumbles at duration of {@code windowDuration}
     */
    public Stream tumblingWindow(BaseWindowedBolt.Duration windowDuration, WindowsStoreFactory windowStoreFactory,
                                     Fields inputFields, Aggregator aggregator, Fields functionFields);

```

#### Sliding window

Tuples are grouped in windows and window slides for every sliding interval. **A tuple can belong to more than one window.**

```java
    /**
     * Returns a stream of tuples which are aggregated results of a sliding window with every {@code windowCount} of tuples
     * and slides the window after {@code slideCount}.
     */
    public Stream slidingWindow(int windowCount, int slideCount, WindowsStoreFactory windowStoreFactory,
                                      Fields inputFields, Aggregator aggregator, Fields functionFields);

    /**
     * Returns a stream of tuples which are aggregated results of a window which slides at duration of {@code slidingInterval}
     * and completes a window at {@code windowDuration}
     */
    public Stream slidingWindow(BaseWindowedBolt.Duration windowDuration, BaseWindowedBolt.Duration slidingInterval,
                                    WindowsStoreFactory windowStoreFactory, Fields inputFields, Aggregator aggregator, Fields functionFields);
```

### Windowing Support in Core Strom

[Windowing Support in Core Storm](http://storm.apache.org/releases/current/Windowing.html)

For example a time duration based sliding window with length 10 secs and sliding interval of 5 seconds.

```
........| e1 e2 | e3 e4 e5 e6 | e7 e8 e9 |...
-5      0       5            10          15   -> time
|<------- w1 -->|
        |<---------- w2 ----->|
                |<-------------- w3 ---->|
```

#### Tumbling Window

**Tuples are grouped in a single window based on time or count**. Any tuple belongs to only one of the windows.

For example a time duration based tumbling window with length 5 secs.

```
| e1 e2 | e3 e4 e5 e6 | e7 e8 e9 |...
0       5             10         15    -> time
   w1         w2            w3
```

The bolt interface `IWindowedBolt` is implemented by bolts that needs windowing support.

```java
public interface IWindowedBolt extends IComponent {
    void prepare(Map stormConf, TopologyContext context, OutputCollector collector);
    /**
     * Process tuples falling within the window and optionally emit 
     * new tuples based on the tuples in the input window.
     */
    void execute(TupleWindow inputWindow);
    void cleanup();
}
```

**Every time the window activates, the `execute` method is invoked**. The TupleWindow parameter gives access to the current tuples in the window, the tuples that expired and the new tuples that are added since last window was computed which will be useful for efficient windowing computations.

Bolts that needs windowing support typically would extend `BaseWindowedBolt` which has the apis for specifying the window length and sliding intervals.

```java
public class SlidingWindowBolt extends BaseWindowedBolt {
    private OutputCollector collector;

    @Override
    public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
        this.collector = collector;
    }

    @Override
    public void execute(TupleWindow inputWindow) {
      for(Tuple tuple: inputWindow.get()) {
        // do the windowing computation
        ...
      }
      // emit the results
      collector.emit(new Values(computedValue));
    }
}

public static void main(String[] args) {
    TopologyBuilder builder = new TopologyBuilder();
     builder.setSpout("spout", new RandomSentenceSpout(), 1);
     builder.setBolt("slidingwindowbolt", 
                     new SlidingWindowBolt().withWindow(new Count(30), new Count(10)),
                     1).shuffleGrouping("spout");
    Config conf = new Config();
    conf.setDebug(true);
    conf.setNumWorkers(1);

    StormSubmitter.submitTopologyWithProgressBar(args[0], conf, builder.createTopology());

}
```

#### Tuple timestamp and out of order tuples

```java
/**
* Specify a field in the tuple that represents the timestamp as a long value. If this
* field is not present in the incoming tuple, an {@link IllegalArgumentException} will be thrown.
*
* @param fieldName the name of the field that contains the timestamp
*/
public BaseWindowedBolt withTimestampField(String fieldName);
```

The value for the above `fieldName` will be looked up from the incoming tuple and considered for windowing calculations. If the field is not present in the tuple an exception will be thrown. Alternatively a `TimestampExtractor` can be used to derive a timestamp value from a tuple (e.g. extract timestamp from a nested field within the tuple).

```java
/**
* Specify the timestamp extractor implementation.
*
* @param timestampExtractor the {@link TimestampExtractor} implementation
*/
public BaseWindowedBolt withTimestampExtractor(TimestampExtractor timestampExtractor)
```

Along with the timestamp field name/extractor, a time lag parameter can also be specified which indicates the max time limit for tuples with out of order timestamps.

```java
/**
* Specify the maximum time lag of the tuple timestamp in milliseconds. It means that the tuple timestamps
* cannot be out of order by more than this amount.
*
* @param duration the max lag duration
*/
public BaseWindowedBolt withLag(Duration duration)
```

E.g. If the lag is `5` secs and a tuple `t1` arrived with timestamp `06:00:05` no tuples may arrive with tuple timestamp earlier than 06:00:00. If a tuple arrives with timestamp 05:59:59 after t1 and the window has moved past t1, it will be treated as a late tuple. Late tuples are not processed by default, just logged in the worker log files at INFO level.

#### Watermarks

>Watermark 是一种标识输入完整性的标记，携带一个时间戳，**当节点收到 Watermark 时，即可认为早于该时间戳的数据均已到达**，从而得到某个时间区间内的数据均已到达的结论。

For processing tuples with timestamp field, storm internally computes watermarks based on the incoming tuple timestamp. **Watermark is the minimum of the latest tuple timestamps (minus the lag) across all the input streams**. At a higher level this is similar to the watermark concept used by Flink and Google's MillWheel for tracking event based timestamps.

>它的计算方法是：storm 接受到得最新的 tuple 的 timestamp--Tmax 减去通过 withLat 设置的最大延时 L，Max（T1…Tn）- L。

Periodically (default every sec), the watermark timestamps are emitted and this is considered as the clock tick for the window calculation if tuple based timestamps are in use. The interval at which watermarks are emitted can be changed with the below api.

```java
/**
* Specify the watermark event generation interval. For tuple based timestamps, watermark events
* * are used to track the progress of time
* *
* * @param interval the interval at which watermark events are generated
* */
* public BaseWindowedBolt withWatermarkInterval(Duration interval)
```

When a watermark is received, all windows up to that timestamp will be evaluated.

For example, consider tuple timestamp based processing with following window parameters,

>假设一个Slide window，其Window length = 20s, sliding interval = 10s, watermark interval = 1s, lag = 5s。

```
|-----|-----|-----|-----|-----|-----|-----|
0     10    20    30    40    50    60    70
```

Current ts = `09:00:00`

Tuples `e1(6:00:03), e2(6:00:05), e3(6:00:07), e4(6:00:18), e5(6:00:26), e6(6:00:36)` are received between `9:00:00` and `9:00:01`

At time t = `09:00:01`, watermark w1 = `6:00:31` is emitted since no tuples earlier than `6:00:31` can arrive.

1. `09:00:01` 这个时间，是因为 watermark interval = 1s
2. `06:00:31` 这个时间，是因为这个 batch 的所有时间中最大的时间是 `e6(6:00:36)`，lag = 5s

Three windows will be evaluated. The first window end ts (06:00:10) is computed by taking the earliest event timestamp (06:00:03) and computing the ceiling based on the sliding interval (10s).

1. `5:59:50 - 06:00:10` with tuples e1, e2, e3
2. `6:00:00 - 06:00:20` with tuples e1, e2, e3, e4
3. `6:00:10 - 06:00:30` with tuples e4, e5

e6 is not evaluated since watermark timestamp `6:00:31` is older than the tuple ts `6:00:36`.

Tuples `e7(8:00:25), e8(8:00:26), e9(8:00:27), e10(8:00:39)` are received between `9:00:01` and `9:00:02`

At time t = `09:00:02` another watermark `w2 = 08:00:34` is emitted since no tuples earlier than `8:00:34` can arrive now.

Three windows will be evaluated,

1. `6:00:20 - 06:00:40` with tuples e5, e6 (from earlier batch)
2. `6:00:30 - 06:00:50` with tuple e6 (from earlier batch)
3. `8:00:10 - 08:00:30` with tuples e7, e8, e9

e10 is not evaluated since the tuple ts `8:00:39` is beyond the watermark time `8:00:34`.

The window calculation considers the time gaps and computes the windows based on the tuple timestamp.

#### Common windowing API

Below is the common windowing API which takes WindowConfig for any supported windowing configurations.

```java
    public Stream window(WindowConfig windowConfig, WindowsStoreFactory windowStoreFactory, Fields inputFields,
                         Aggregator aggregator, Fields functionFields)
```

Trident windowing APIs need `WindowsStoreFactory` to store received tuples and aggregated values. Currently, basic implementation for HBase is given with `HBaseWindowsStoreFactory`. It can further be extended to address respective usecases. Example of using HBaseWindowStoreFactory for windowing can be seen below.

### 总结

#### FixedBatchWindow

```java
public class FixedBatchWindow extends BaseRichSpout {

    private final static Logger LOG = LoggerFactory.getLogger(FixedBatchWindow.class);

    private static final long serialVersionUID = 1111260824087900500L;

    private SpoutOutputCollector collector;

    private int index = 0;

    private int[][] batchNums = {
            {1, 2, 3, 4, 5},
            {6, 7, 8, 9, 10},
            {11, 12, 13, 14, 15},
            {16}
    };

    public FixedBatchWindow() {
    }

    @Override
    public void open(Map conf, TopologyContext context, SpoutOutputCollector collector) {
        this.collector = collector;
    }

    @Override
    public void close() {

    }

    @Override
    public void nextTuple() {
        if (index < batchNums.length) {
            int[]        nums   = batchNums[index];
            for (int num : nums) {
                List<Object> values = new ArrayList<Object>();
                values.add(num);
                collector.emit(values);
                LOG.info("num = [{}]", num);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            ++index;
        }
        index %= batchNums.length;
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("num"));
    }

    @Override
    public Map<String, Object> getComponentConfiguration() {
        return null;
    }
}
```

#### SumSlidingWindowBolt

```java
public class SumSlidingWindowBolt extends BaseWindowedBolt {

    private static final Logger LOG = LoggerFactory.getLogger(SumSlidingWindowBolt.class);

    private int             sum = 0;
    private OutputCollector collector;

    @Override
    public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
        this.collector = collector;
    }

    @Override
    public void execute(TupleWindow inputWindow) {
        /*
         * The inputWindow gives a view of
         * (a) all the events in the window
         * (b) events that expired since last activation of the window
         * (c) events that newly arrived since last activation of the window
         */
        List<Tuple> tuplesInWindow = inputWindow.get();
        List<Tuple> newTuples      = inputWindow.getNew();
        List<Tuple> expiredTuples  = inputWindow.getExpired();

        LOG.info("in  = {}", print(tuplesInWindow));
        LOG.info("new = {}", print(newTuples));
        LOG.info("exp = {}", print(expiredTuples));

        LOG.debug("Events in current window: " + tuplesInWindow.size());
        /*
         * Instead of iterating over all the tuples in the window to compute
         * the sum, the values for the new events are added and old events are
         * subtracted. Similar optimizations might be possible in other
         * windowing computations.
         */
        for (Tuple tuple : newTuples) {
            sum += (int) tuple.getValue(0);
        }
        for (Tuple tuple : expiredTuples) {
            sum -= (int) tuple.getValue(0);
        }
        collector.emit(new Values(sum));
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("sum"));
    }

    private String print(List<Tuple> tuples) {
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        for (int i = 0; i < tuples.size(); ++i) {
            if (i != 0) {
                sb.append(",");
            }
            sb.append(tuples.get(i).getInteger(0));
        }
        sb.append("]");
        return sb.toString();
    }
}

```

#### 事件类型

>不管是 tumbling window 还是 sliding window，都有基于时间和事件数量的两种类型。

```java
		// 基于事件时间
        BaseWindowedBolt slidingWindow = new SumSlidingWindowBolt()
                .withWindow(BaseWindowedBolt.Duration.seconds(5), BaseWindowedBolt.Duration.of(3))
                .withWatermarkInterval(BaseWindowedBolt.Duration.seconds(1))
                .withLag(BaseWindowedBolt.Duration.seconds(3))
                .withTimestampExtractor(new TestTimeExtractor());

```

```java
		// 基于事件数量
        BaseWindowedBolt slidingWindow = new SumSlidingWindowBolt()
		    	.withWindow(BaseWindowedBolt.Count.of(5), BaseWindowedBolt.Count.of(3))
                .withWatermarkInterval(BaseWindowedBolt.Duration.seconds(1))
                .withLag(BaseWindowedBolt.Duration.seconds(3))
                .withTimestampExtractor(new TestTimeExtractor());

```

#### 基于时间窗口的事件

>基于事件时间的窗口也有两种类型：默认的 `基于 tuple 被处理的时间` 和 `基于 TimestampExtractor/withTimestampField 从事件中获取的时间`
><br/>
>同时，我们还有一个参数 lag 表明最大的延迟，假设日志 `t1` 到达的时间是 `06:00:05`，并且 lag == 5，那么对于 `t2` 如果他的到达时间是 `05:59:59`，那么日志将直接被忽略。

#### watermark

在处理带 timestamp 的 tuple 时，storm 会自动计算 watermark。watermark 是所有的输入流中的最新 tuple 的时间戳 - lag。

### partitionAggregate

partitionAggregate runs a function on each partition of a batch of tuples. Unlike functions, the tuples emitted by partitionAggregate replace the input tuples given to it. Consider this example:

```java
mystream.partitionAggregate(new Fields("b"), new Sum(), new Fields("sum"))
```

Suppose the input stream contained fields ["a", "b"] and the following partitions of tuples:

```
Partition 0:
["a", 1]
["b", 2]

Partition 1:
["a", 3]
["c", 8]

Partition 2:
["e", 1]
["d", 9]
["d", 10]
```

Then the output stream of that code would contain these tuples with one field called "sum":

```
Partition 0:
[3]

Partition 1:
[11]

Partition 2:
[20]
```

There are three different interfaces for defining aggregators: `CombinerAggregator`, `ReducerAggregator`, and `Aggregator`.

Here's the interface for CombinerAggregator:

```java
public interface CombinerAggregator<T> extends Serializable {
    T init(TridentTuple tuple);
    T combine(T val1, T val2);
    T zero();
}
```

A CombinerAggregator returns a single tuple with a single field as output. CombinerAggregators run the init function on each input tuple and use the combine function to combine values until there's only one value left. If there's no tuples in the partition, the CombinerAggregator emits the output of the zero function. For example, here's the implementation of Count:

A ReducerAggregator has the following interface:

```java
public interface ReducerAggregator<T> extends Serializable {
    T init();
    T reduce(T curr, TridentTuple tuple);
}
```

A ReducerAggregator produces an initial value with init, and then it iterates on that value for each input tuple to produce a single tuple with a single value as output. For example, here's how you would define Count as a ReducerAggregator:

```java
public class Count implements ReducerAggregator<Long> {
    public Long init() {
        return 0L;
    }

    public Long reduce(Long curr, TridentTuple tuple) {
        return curr + 1;
    }
}
```

**The most general interface for performing aggregations is Aggregator**, which looks like this:

```java
public interface Aggregator<T> extends Operation {
    T init(Object batchId, TridentCollector collector);
    void aggregate(T state, TridentTuple tuple, TridentCollector collector);
    void complete(T s	tate, TridentCollector collector);
}
```

Aggregators can emit any number of tuples with any number of fields. They can emit tuples at any point during execution. Aggregators execute in the following way:

1. The init method is called before processing the batch. The return value of init is an Object that will represent the state of the aggregation and will be passed into the aggregate and complete methods.
2. The aggregate method is called for each input tuple in the batch partition. This method can update the state and optionally emit tuples.
3. The complete method is called when **all tuples for the batch partition** have been processed by aggregate.

#### TestAggregatorTopo

```java
public class TestAggregatorTopo {
    public static StormTopology buildTopology() {
        TridentTopology topology = new TridentTopology();

        Fields word = new Fields("word");
        FixedBatchSpout spout = new FixedBatchSpout(word, 4,
                                                    Arrays.asList(new Object[]{"1"}),
                                                    Arrays.asList(new Object[]{"2"}),
                                                    Arrays.asList(new Object[]{"3"}),
                                                    Arrays.asList(new Object[]{"3"}),
                                                    Arrays.asList(new Object[]{"4"}),
                                                    Arrays.asList(new Object[]{"5"}),
                                                    Arrays.asList(new Object[]{"6"}),
                                                    Arrays.asList(new Object[]{"7"}),
                                                    Arrays.asList(new Object[]{"8"}),
                                                    Arrays.asList(new Object[]{"9"})
        );
        spout.setCycle(false);
        topology.newStream("spout", spout).parallelismHint(1)
                .partitionAggregate(new Fields("word"), new CountAgg(), new Fields());

        return topology.build();
    }

    public static void main(String[] args) {
        Config config = new Config();
        config.setDebug(false);
        LocalCluster localCluster = new LocalCluster();
        localCluster.submitTopology("aggregator", config, buildTopology());
    }
}

```

#### CountAgg

```java
public class CountAgg extends BaseAggregator<CountAgg.CountState> {
    static class CountState {
        long count = 0;
    }

    @Override
    public CountState init(Object batchId, TridentCollector collector) {
        return new CountState();
    }

    @Override
    public void aggregate(CountState state, TridentTuple tuple, TridentCollector collector) {
        state.count+=1;
    }

    @Override
    public void complete(CountState state, TridentCollector collector) {
        collector.emit(new Values(state.count));
    }
}
```

### execute multiple aggregators

Sometimes you want to execute multiple aggregators at the same time. This is called chaining and can be accomplished like this:

```java
mystream.chainedAgg()
        .partitionAggregate(new Count(), new Fields("count"))
        .partitionAggregate(new Fields("b"), new Sum(), new Fields("sum"))
        .chainEnd()
```

This code will run the Count and Sum aggregators on each partition. **The output will `contain a single tuple` with the fields ["count", "sum"].**

### stateQuery and partitionPersist

stateQuery和partitionPersist分别查询和更新状态源。 查看 [Trident State](http://storm.apache.org/releases/current/Trident-state.html)

### projection

The projection method on Stream keeps only the fields specified in the operation. If you had a Stream with fields ["a", "b", "c", "d"] and you ran this code:

```java
mystream.project(new Fields("b", "d"))
```

The output stream would contain only the fields ["b", "d"].


## Repartitioning operations

1. shuffle
2. broadcast
3. partitionBy
4. global
5. batchGlobal
6. partition

## Aggregation operations

Trident has aggregate and persistentAggregate methods for doing aggregations on Streams.

1. `aggregate` is run on `each batch` of the stream in isolation
2. `persistentAggregate` will aggregation on all tuples across all batches in the stream and store the result in a source of state.

**Running aggregate on a Stream does a global aggregation**. When you use a ReducerAggregator or an Aggregator, the stream is first repartitioned into a single partition, and then the aggregation function is run on that partition. When you use a CombinerAggregator, on the other hand, first Trident will compute partial aggregations of each partition, then repartition to a single partition, and then finish the aggregation after the network transfer. CombinerAggregator's are far more efficient and should be used when possible.

Here's an example of using aggregate to get a global count for a batch:

```java
mystream.aggregate(new Count(), new Fields("count"))
```

Like partitionAggregate, aggregators for aggregate can be chained. However, if you chain a CombinerAggregator with a non-CombinerAggregator, Trident is unable to do the partial aggregation optimization.

## Operations on grouped streams

The groupBy operation repartitions the stream by doing a partitionBy on the specified fields, and then within each partition groups tuples together whose group fields are equal. For example, here's an illustration of a groupBy operation:

![grouping](./grouping.png)

**If you run aggregators on a grouped stream, the aggregation will be run within each group instead of against the whole batch.** `persistentAggregate` can also be run on a GroupedStream, in which case the results will be stored in a MapState with the key being the grouping fields. You can read more about persistentAggregate in the Trident state doc.


