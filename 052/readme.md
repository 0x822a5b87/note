# prometheus 集群化方案

## reference

- [Thanos - Open source, highly available Prometheus setup with long term storage capabilities.](https://thanos.io/)
- [kvass - Kvass is a Prometheus horizontal auto-scaling solution , which uses Sidecar to generate special config file only containes part of targets assigned from Coordinator for every Prometheus shard.](https://github.com/tkestack/kvass)
- [如何扩展单个Prometheus实现近万Kubernetes集群监控？](https://mp.weixin.qq.com/s?__biz=Mzg5NjA1MjkxNw==&mid=2247486068&idx=1&sn=1da847461cbd2b9a92cba9f51818d9db&chksm=c007b1aef77038b84d3da5fd7a50fc2e7eb51253042c67a3b7f3db2f08130ca7425d8d953a28&mpshare=1&scene=1&srcid=0812musJWcQzfAEf7bDwGmIn&sharer_sharetime=1597215750359&sharer_shareid=c36e4807e52bb0fd28e7ef15200507a3&rd2werd=1#wechat_redirect)

## 如何扩展单个Prometheus实现近万Kubernetes集群监控？

### 核心名词

- **Meta Cluster** 托管其他集群的apiserver，controller-manager，scheduler，监控套件等非业务组件
- **Cluster-monitor** 单集群级别的监控采集套件
- **Barad**：云监控提供的多维监控系统，是云上其他服务主要使用的监控系统，其相对成熟稳定，但是不灵活，指标和label都需要提前在系统上设置好。
- **Argus**：云监控团队提供的多维业务监控系统，其特点是支持较为灵活的指标上报机制和强大的告警能力。这是TKE团队主要使用的监控系统。
- **Region Prometheus**： 因为 Cluster-monitor 只能采集集群自身的监控数据，但是一个 region 可能会包含多个不同的 cluster，所以可能需要 Region Prometheus 来采集 region 的相关数据。
- **Top Prometheus**：所有地域的Region Prometheus数据再聚合得到全网级别指标
- **job**: Prometheus的采集任务由配置文件中一个个的Job组成，一个Job里包含该Job下的所有监控目标的公共配置，比如使用哪种服务发现去获取监控目标，比如抓取时使用的证书配置，请求参数配置等等。
- **target**: 一个监控目标就是一个target，一个job通过服务发现会得到多个需要监控的target及其label集合用于描述target的一些属性。
- **relabel_configs**: 每个job都可以配置一个或多个relabel_config，relabel_config会对target的label集合进行处理，可以根据label过滤一些target或者修改，增加，删除一些label。**relabel_config过程发生在target开始进行采集之前,针对的是通过服务发现得到的label集合**。
- **metrics_relabel_configs**：每个job还可以配置一个或者多个metrics_relabel_config，其配置方式和relabel_configs一模一样，**但是其用于处理的是从target采集到的数据中的label**。
- **series**：一个series就是指标名+label集合，在面板中，表现为一条曲线。
- **head series**：Prometheus会将近2小时的series缓存在内存中，称为head series。

### 架构图

> 原始架构

![原始架构](640.png)

> kvass
>
> - 去掉了Cluster-monitor中的Prometheus
> - 去掉了Region Prometheus

![Kvaas](Kvaas.png)



### kvass

#### 高性能采集

> **Prometheus采集原理**

![prometheus采集原理](prometheus采集原理.png)









































