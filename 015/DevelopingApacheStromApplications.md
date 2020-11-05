# [Developing Apache Storm Applications](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/developing-storm-applications/content/trident_concepts.html)

- [Storm中文文档 - Trident API概述](https://www.jianshu.com/p/881d502cd4b5)

## Developing Apache Storm Applications

Here are some examples of differences between core Storm and Trident:

- The basic primitives in core storm are `bolts` and `spouts`. The core data abstraction in Trident is the `stream`.
- Core Storm processes events individually. Trident supports the concept of transactions, and processes data in micro-batches.
- **Trident was designed to support stateful stream processing**
- Core Storm supports a wider range of programming languages than Trident.
- Core Storm supports at-least-once processing very easily, but for exactly-once semantics, Trident is easier (from an implementation perspective) than using core Storm primitives.

## [Trident Concept](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/developing-storm-applications/content/trident_concepts.html)

### Introductory Example: Trident Word Count

```java
TridentTopology topology = new TridentTopology();
    Stream wordCounts = topology.newStream("spout1", spout)
            .each(new Fields("sentence"), new Split(), new Fields("word"))
            .parallelismHint(16)
            .groupBy(new Fields("word"))
            .persistentAggregate(new MemoryMapState.Factory(), new Count(), new Fields("count"))
            .newValuesStream()
            .parallelismHint(16);
```

- The remaining lines of code aggregate the running count for individual words, update a persistent state store, and emit the current count for each word.

The `persistentAggregate()` method applies a Trident Aggregator to a stream, updates a persistent state store with the result of the aggregation, and emits the result:

```java
.persistentAggregate(new MemoryMapState.Factory(), new Count(), new Fields("count"))
```

The sample code uses an in-memory state store (MemoryMapState); Storm comes with a number of state implementations for databases such as HBase.

The `Count` class is a `Trident CombinerAggregator` implementation that **sums all values in a batch partition of tuples**:

**Trident提供aggregate和persistentAggregate方法对流进行聚合操作。aggregate独立运行在每个batch的流中，而persistentAggregate将聚合所有batch的流的元组，并将结果保存在一个状态源中。**

### CombinerAggregator 详解

#### Trident Word Count 源码

```java
public class TestGlobalAggregatorTopo {
    public static StormTopology buildTopology() {
        TridentTopology topology = new TridentTopology();

        Fields word = new Fields("word");
        FixedBatchSpout spout = new FixedBatchSpout(new Fields("sentence"), 2,
                                                    new Values("the cow jumped over the moon"),
                                                    new Values("the man went to the store and bought some candy"),
                                                    new Values("four score and seven years ago"),
                                                    new Values("how many apples candy you eat"));

        spout.setCycle(false);
        topology.newStream("spout", spout).parallelismHint(1)
                .each(new Fields("sentence"), new SplitFunction(), new Fields("word"))
//                .each(new Fields("sentence"), new OutputFunction(), new Fields(""))
                .groupBy(new Fields("word"))
                .persistentAggregate(new MemoryMapState.Factory(), new Count(), new Fields("count"))
                .newValuesStream()
                .peek(new Consumer() {
                    @Override
                    public void accept(TridentTuple input) {
                        String v = String.format("word = [%s], count = [%s]", input.get(0), input.get(1));
                        System.out.println(v);
                    }
                });

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

#### persistentAggregate(new MemoryMapState.Factory(), new Count(), new Fields("count"))

1. 在这个方法中，我们将 `Count()` 添加到了 `ChainedAggregatorDeclarer` 中。
2. 在这个方法中，我们初始化了 `StateSpec` 和 `StateUpdater` 这两个重要对象
3. `partitionPersist` 方法是所有的 `partitionPersist` 重载方法的最终调用方法。
4. 我们还初始化了两个重要对象 `ProcessorNode` 和 `PartitionPersistProcessor`，在这两个类中，我们会去调用 `startBatch` 和 `finishBatch` 来帮助我们实现 `事务` 和 `批处理` 等语义。

```java
	// GroupedStream
    public TridentState persistentAggregate(StateFactory stateFactory, CombinerAggregator agg, Fields functionFields) {
        return persistentAggregate(new StateSpec(stateFactory), agg, functionFields);
    }

    public TridentState persistentAggregate(StateSpec spec, CombinerAggregator agg, Fields functionFields) {
        return persistentAggregate(spec, null, agg, functionFields);
    }

    public TridentState persistentAggregate(StateFactory stateFactory, Fields inputFields, CombinerAggregator agg, Fields functionFields) {
        return persistentAggregate(new StateSpec(stateFactory), inputFields, agg, functionFields);
    }

    public TridentState persistentAggregate(StateSpec spec, Fields inputFields, CombinerAggregator agg, Fields functionFields) {
        return aggregate(inputFields, agg, functionFields)
                .partitionPersist(spec,
                        TridentUtils.fieldsUnion(_groupFields, functionFields),
                        new MapCombinerAggStateUpdater(agg, _groupFields, functionFields),
                        TridentUtils.fieldsConcat(_groupFields, functionFields)); 
    }
```

```java
    public TridentState partitionPersist(StateSpec stateSpec, Fields inputFields, StateUpdater updater, Fields functionFields) {
        projectionValidation(inputFields);
        String id = _topology.getUniqueStateId();
        ProcessorNode n = new ProcessorNode(_topology.getUniqueStreamId(),
                    _name,
                    functionFields,
                    functionFields,
                    new PartitionPersistProcessor(id, inputFields, updater));
        n.committer = true;
        n.stateInfo = new NodeStateInfo(id, stateSpec);
        return _topology.addSourcedStateNode(this, n);
    }

```

### [Trident State](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/developing-storm-applications/content/trident_state.html)

Trident includes high-level abstractions for managing persistent state in a topology. State management is fault tolerant: updates are idempotent when failures and retries occur. **These properties can be combined to achieve exactly-once processing semantics**. Implementing persistent state with the Storm core API would be more difficult.

Trident groups tuples into batches, each of which is given a unique transaction ID. When a batch is replayed, the batch is given the same transaction ID. `State updates in Trident are ordered` such that a state update for a particular batch will not take place until the state update for the previous batch is fully processed. This is reflected in Tridents State interface at the center of the state management API:

```java
public interface State {
    void beginCommit(Long txid);
    void commit(Long txid);
}
```

When updating state, Trident informs the `State` implementation that a transaction is about to begin by calling `beginCommit()`, indicating that state updates can proceed. At that point the State implementation updates state as a batch operation. Finally, when the state update is complete, Trident calls the `commit()` method, indicating that the state update is ending. The inclusion of transaction ID in both methods allows the underlying implementation to manage any necessary rollbacks if a failure occurs.


