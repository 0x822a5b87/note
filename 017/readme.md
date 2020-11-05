流式计算框架的exactly once指的是最终的处理结果是exactly once的，不是说对输入的数据只恰好处理一次。这里以计数为例，我们说的exactly once指的是写出的最终的结果（这里我们假设是DB）与输入的数据一致，一条不多一条不少。这个听起来很容易，但是实现起来却并不容易，因为 流式计算框架通常是分布式的，而且通常有着比较复杂的topology。在这里我简单描述下三种流式计算框架（storm trident, spark streaming, flink）分别是如何实现exactly once的。

## storm trident

首先我们来说说storm trident。因为分布式系统中随时都可能出现机器挂掉的情况，要保证实现exactly once最基本的一点就是在挂了之后需要重试。光重试是不够的，重试的过程中还要保证顺序。打个比方我们处理2条kafka的消息，消息A表示为(offset: 1, key: cnn, count: 1)，消息B表示为（offset: 2, key: cnn, count: 2)。如果不保证顺序，那么处理的流程可能是这样的：

1. 将A的数据存入数据库
2. 将B的数据存入数据库
3. 通知系统B处理完成
4. 系统挂了，只能重试，由于A尚未ack，所以系统从A开始拉取，但B已经处理完成，因此无法实现exactly once

但是如果我们保证处理的顺序性，那么处理的流程就是这样的：

1. 将A的数据存入数据库，并记录下最后的offset
2. 通知系统A处理完成
3. 将B的数据存入数据库，并记录下最后的offset
4. 通知系统B处理完成

在这种情况下如果尚未通知系统A处理完成就挂了，有2种可能：A未写入数据库或者A已经写入数据库。而这两种情况可以根据记录下来的最后的offset来判断。

一个分布式系统中如果一条一条地处理，显然吞吐太低，严重浪费资源，这里可以将一条一条改成一批一批地处理。这样虽然比一条一条地处理好，但是面对复杂的topology，依然会严重浪费资源。比如我的topology需要先解析kafka里的日志，并提取出相应的字段，然后根据key shuffle到不同的机器上聚合然后存入到数据库里去。这里显然只有存入数据库的这个动作是需要按照顺序一批一批处理，而前面解析日志的部分不需要严格按照顺序处理，因此storm trident里的operator分为两种，一种是有状态的，一种是无状态的。有状态的处理需要严格保序，而无状态的operator则不需要等待上一个批次处理完成。这个其实与tcp中的窗口的思想有点类似。

以上就是storm trident的基本思想。因此从上面的分析可以看出，要实现exactly once的处理，输入流需要支持回退（kafka就是一个常用的输入流），输出需要支持update（比如mysql, redis），比如使用kafka作为输出是做不到exactly once的。

## spark streaming

spark streaming通过将输入切分成一个一个的batch，在遭遇失败的时候需要重新回放最后一个batch，因此它要求foreach rdd的操作是幂等。看了storm trident分析的同学可能有一个困惑：spark streaming要实现exactly once，就要保证按顺序处理，它是如何做到的呢？我们知道spark streaming的每一个batch都会生成一个job来处理，在内部实现中spark streaming只允许同时运行一个job，也就是只允许同时处理一个batch。这种做法的问题在于会严重浪费资源。

## flink

flink所提出的使用checkpiont方法来实现exactly once是目前我了解到的最优雅的方式。trident和spark streaming的batch方式的一个问题在于资源的利用率。batch切小了吞吐上不去，切大了需要预分配更多的资源，而且trident基于storm原生的ack机制，所以batch还与超时的设置相关。flink的基本思路就是将状态定时地checkpiont到hdfs中去，当发生failure的时候恢复上一次的状态，然后将输出update到外部。这里需要注意的是输入流的offset也是状态的一部分，因此一旦发生failure就能从最后一次状态恢复，从而保证输出的结果是exactly once的。因此这里注意exactly once的条件跟storm trident相同：输入流要能回退到某一点，输出要能被update。

