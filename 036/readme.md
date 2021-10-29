## Kubernetes in Actions

## question

1. 因为 rc 是和 label 绑定的，那么 kubernetes 集群中是否会存在两个 label 一模一样的 pod？

## references

- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [Glossary - a comprehensive, standardized list of Kubernetes terminology](https://kubernetes.io/docs/reference/glossary/)

## roadmap

![k8s-roadmap](k8s-roadmap.png)

## components-of-kubernetes

![components-of-kubernetes](components-of-kubernetes.svg)

## 1. Kubernetes 介绍

1. Kubernetes 可以被当做集群的一个操作系统来看待；
2. 当 `API server` 处理应用的描述时，`scheduler` 调度指定组的容器到可用的工作节点上，调度是基于每组所需的计算资源，以及调度时每个节点未分配的资源。然后，那些节点上的 `Kubelet` 指示容器运行时（例如Docker ）拉取所需的镜像并运行容器。

![k8s work](kubernetes 体系结构的基本概述和在它之上运行的应用程序.png)

## 2. 开始使用 kubernetes 和 docker

```bash
docker run busybox echo ”Hello world”
```

![busybox](busybox.png)

#### 2.1.2 创建一个简单的Node.js 应用

```javascript
const http = require('http');
const os   = require('os');

console.log('Kubia server starting...')

var handler = function(request, response) {
	console.log("Received request from " + request.connection.remoteAddress)
	response.writeHead(200)
	response.end("You've hit " + os.hostname() + "\n")
};

var www = http.createServer(handler);
www.listen(8080);
```

#### 构建容器镜像

> 在这个例子中，我们使用了 `node:7` 作为基础镜像，因为对于 node 应用来说 node 包含了运行应用所需的一切，所以我们无需使用：
>
> app.js
>
> node
>
> linux
>
> 这种层级的镜像结构。

```dockerfile
FROM node:7

ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

```bash
# 打包镜像
# 在当前目录构建一个建 kubia 的镜像，docker 会在当前目录寻找 Dockerfile 然后构建 docker 镜像。
docker build -t kubia .

docker images kubia
# REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
# kubia        latest    4369322ecec2   About a minute ago   660MB

# 运行镜像
docker run --name kubia-container -p 8080:8080 -d kubia

# 复制 kubia 镜像，并使用 luksa/kubia 作为名字 
docker tag kubia luksa/kubia
```

#### 配置 kubernetes 集群

```bash
# 启动 minikube 虚拟机
minikube start
#😄  minikube v1.21.0 on Darwin 10.15.7
#✨  Using the docker driver based on existing profile
#👍  Starting control plane node minikube in cluster minikube
#🚜  Pulling base image ...
#🏃  Updating the running docker "minikube" container ...
#🐳  Preparing Kubernetes v1.20.7 on Docker 20.10.7 ...
#🔎  Verifying Kubernetes components...
#    ▪ Using image kubernetesui/metrics-scraper:v1.0.4
#    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
#    ▪ Using image kubernetesui/dashboard:v2.1.0
#🌟  Enabled addons: storage-provisioner, default-storageclass, dashboard
#🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

# 启动3个虚拟节点
minikube start --nodes=3
# 下面的命令会指定 profile 为 multinode-demo
#minikube start --nodes=3 -p multinode-demo

# 验证集群是否正常工作
kubectl cluster-info

# 列出集群节点
kubectl get nodes
# NAME                  STATUS     ROLES                  AGE     VERSION
# multinode-demo1       Ready      control-plane,master   2m24s   v1.20.7
# multinode-demo1-m02   Ready      <none>                 72s     v1.20.7
# multinode-demo1-m03   NotReady   <none>                 9s      v1.20.7

# 查看节点状态
kubectl describe node multinode-demo1
```

#### 在 kubernetes 上部署第一个应用

> 一个 pod 是一组紧密相关的容器，他们总是运行在同一个工作节点上，以及同一个 linux namespace。

```bash
# --image=luksa/kubia 显示的是指定要运行的容器镜像，
# --port=8080 告诉 kubernetes 应用正在监听 8080
kubectl run kubia --image=luksa/kubia --port=8080

# 列出 pod
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# kubia   1/1     Running   0          5m41s

# Now kubectl run command creates standalone pod without ReplicationController. 
kubectl expose pod kubia --type=LoadBalancer --name kubia-http

# Connect to LoadBalancer services
minikube tunnel
# 🏃  Starting tunnel for service kubia-http.

kubectl get services
# NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# kubernetes   ClusterIP      10.96.0.1       <none>        443/TCP          150m
# kubia-http   LoadBalancer   10.101.223.38   <pending>     8080:32161/TCP   96s
```

![在kubernetes中运行luksa/kubia容器](在kubernetes中运行luksa:kubia容器.png)

## 3. pod : 运行于 kubernetes 中的容器

### 3.1 介绍 pod

> 为何需要 pod 这种容器？
>
> 为何不直接使用容器？
>
> 为何甚至需要同时运行多个容器？难道不能把所有的进程都放在一个容器中吗？

容器被设计为每个容器只运行一个进程（除非进程自己产生新的进程）。如果在单个容器中运行多个不相关的进程，那么保持所有的进程运行、管理他们的日志将会是我们的责任。当容器崩溃时，容器内包含的进程全部输出到标准输出中，此时我们很难确定每个进程分别记录了什么。

由于不能将多个进程放在一个单独的容器中，所以我们需要另一种更高级的结构来将容器绑定到一起，并将他们作为一个单元进程管理。

**容器之间是完全隔离的，我们的期望是隔离容器组而不是单个容器，并且让每个容器组内的容器共享一些资源，而不是全部。kubernetes 通过配置 docker 让一个 pod 内的所有容器共享相同的linux namespace，而不是每个容器都有自己的一组 namespace。**

一个 pod 中的容器运行于相同的 network namespace，因此他们享有相同的ip和 port。因此对于在同一个 pod 下的多个进程不能绑定到相同的端口。

![pod间的网络模型](pod间的网络模型.png)

同一个 kubernetes 集群的 pod 在同一个 **共享网络地址空间**，这意味着每个 pod 都可以通过其他 pod 的 ip 地址来实现互相访问。

##### 将多层应用分散到多个pod中

> 对于一个有前端服务和后端数据库组成的多层应用程序，应该配置成单个pod还是多个pod呢？

如果我们放到一个 pod 中，那么意味着前端和后端的服务永远只能在一台机器上执行，无法充分的提高基础架构的使用率。

另外，kubernetes 的扩缩容也是基于 pod 的，前端和后端的服务放在一个 pod 下意味着我们无法针对前端服务以及后端服务的需求进行扩缩容。

##### 何时在 pod 中使用多个容器

> 使用单个 pod 包含多个容器的主要原因是：应用可能由一个主进程和一个或者多个辅助进程组成。

例如在微服务架构中的，主进程是业务逻辑，辅助进程是 envoy（或者其他网关）。

![前端服务和后端服务架构](前端服务和后端服务架构.png)

### 3.2 以 yaml 或 json 描述文件创建 pod

[kubernetes docs](https://kubernetes.io/docs/reference/)

```bash
# 使用 -o yaml 选项获取 pod 的整个定义 yaml
kubectl get po kubia -o yaml
```

```yaml
# yaml 描述文件所使用的 kubernetes API 版本
apiVersion: v1
# kubernetes 对象资源类型
kind: Pod
# pod 元数据（名称、标签和注解等）
metadata:
  creationTimestamp: "2021-10-27T07:33:55Z"
  labels:
    run: kubia
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .: {}
          f:run: {}
      f:spec:
        f:containers:
          k:{"name":"kubia"}:
            .: {}
            f:image: {}
            f:imagePullPolicy: {}
            f:name: {}
            f:ports:
              .: {}
              k:{"containerPort":8080,"protocol":"TCP"}:
                .: {}
                f:containerPort: {}
                f:protocol: {}
            f:resources: {}
            f:terminationMessagePath: {}
            f:terminationMessagePolicy: {}
        f:dnsPolicy: {}
        f:enableServiceLinks: {}
        f:restartPolicy: {}
        f:schedulerName: {}
        f:securityContext: {}
        f:terminationGracePeriodSeconds: {}
    manager: kubectl-run
    operation: Update
    time: "2021-10-27T07:33:55Z"
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:conditions:
          k:{"type":"ContainersReady"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
          k:{"type":"Initialized"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
          k:{"type":"Ready"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
        f:containerStatuses: {}
        f:hostIP: {}
        f:phase: {}
        f:podIP: {}
        f:podIPs:
          .: {}
          k:{"ip":"10.244.2.2"}:
            .: {}
            f:ip: {}
        f:startTime: {}
    manager: kubelet
    operation: Update
    time: "2021-10-27T07:35:16Z"
  name: kubia
  namespace: default
  resourceVersion: "1110"
  uid: 29ed7476-3fff-4ddb-93c8-90a1fa81fda9
# pod 规格/内容（pod 的容器列表、volumn 等）
spec:
  containers:
  - image: luksa/kubia
    imagePullPolicy: Always
    name: kubia
    ports:
    - containerPort: 8080
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-zmmm2
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: minikube-m03
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-zmmm2
    secret:
      defaultMode: 420
      secretName: default-token-zmmm2
# pod 机器内部容器的详细状态
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2021-10-27T07:33:55Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2021-10-27T07:35:16Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2021-10-27T07:35:16Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2021-10-27T07:33:55Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://56a21a88860f2a9afe9a4eaf66ae69f20eac03d238ae8d11738c052cdf5e1ae6
    image: luksa/kubia:latest
    imageID: docker-pullable://luksa/kubia@sha256:3f28e304dc0f63dc30f273a4202096f0fa0d08510bd2ee7e1032ce600616de24
    lastState: {}
    name: kubia
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2021-10-27T07:35:16Z"
  hostIP: 192.168.49.4
  phase: Running
  podIP: 10.244.2.2
  podIPs:
  - ip: 10.244.2.2
  qosClass: BestEffort
  startTime: "2021-10-27T07:33:55Z"
```

##### kubia-manual.yaml

> 下面的 yaml 描述了如下的一个 pod：
>
> 1. 使用 kubernetes v1 的 api
> 2. 资源类型是一个 pod
> 3. 容器的名称是 kubia-manual
> 4. pod 基于名为 luksa/kubia 的镜像组成，监听端口 8080 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual
spec:
  containers:
    - image: luksa/kubia
      name: kubia
      ports:
        - containerPort: 8080
          protocol: TCP
```

```bash
# 解释 pod 的字段
k explain pods
#KIND:     Pod
#VERSION:  v1
#
#DESCRIPTION:
#     Pod is a collection of containers that can run on a host. This resource is
#     created by clients and scheduled onto hosts.
#
#FIELDS:
#   apiVersion     <string>
#     APIVersion defines the versioned schema of this representation of an
#     object. Servers should convert recognized schemas to the latest internal
#     value, and may reject unrecognized values. More info:
#     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
#
#   kind     <string>
#     Kind is a string value representing the REST resource this object
#     represents. Servers may infer this from the endpoint the client submits
#     requests to. Cannot be updated. In CamelCase. More info:
#     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
#
#   metadata <Object>
#     Standard object's metadata. More info:
#     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata
#
#   spec     <Object>
#     Specification of the desired behavior of the pod. More info:
#     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
#
#   status   <Object>
#     Most recently observed status of the pod. This data may not be up to date.
#     Populated by the system. Read-only. More info:
#     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

# 解释 pods 下的 spec
k explain pods.spec
```

#### 3.2.3 使用 kubectl create 来创建 pod

```bash
# -f 表示资源文件
k create -f kubia-manual.yaml

k get pods
#NAME           READY   STATUS    RESTARTS   AGE
#kubia          1/1     Running   0          79m
#kubia-manual   1/1     Running   0          37s
```

> 我们通过 `kubia-manual.yaml` 创建的 pod **kubia-manual**，和我们最开始手动创建的 **kubia**，两个都绑定到了 8080 端口。但是我们之前提到的，不同的 pod 之间是在不同的 network namespace 下，所以他们不会冲突。

```bash
# 查看 pod 日志
kubectl logs kubia-manual

# 如果 pod 中有其他容器，可以通过 -c 指定容器
kubectl logs kubia-manual -c kubia
```

#### 3.2.5 向 pod 发送请求

前面我们使用了 `kubectl expose` 命令创建了一个 service，以便于在外部访问 pod。

除此之外，我们可以通过 **端口转发** 来实现这个功能。

```bash
# 将本机器的 8888 端口转发到 kubia-manual 的 8080 端口
kubectl port-forward kubia-manual 8888:8080
```

![k8s port-forward](k8s port-forward.png)

### 3.3 使用标签组织 pod

> 在实际的应用中，我们需要有一个简单的方法来区分所有的 pod。
>
> 例如，在灰度发布中，我们需要知道哪些 pod 是已经灰度的，哪些是没有灰度的。

#### 3.3.1 介绍标签

> 1. pod 可以组织 kubernetes 的所有资源；
> 2. pod 是可以附加到资源的任意键值对；

假设我们现在的 pod 有两个标签：

1. app
2. rel：显示应用程序版本是 stable、beta 还是 canary。

![使用标签组织pod](使用标签组织pod.png)

#### 3.3.2 创建pod时指定标签

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual-with-labels
  # 指定标签
  labels:
    creation_method: manual
    env: prod
spec:
  containers:
    - image: luksa/kubia
      name: kubia
      ports:
        - containerPort: 8080
          protocol: TCP
```

```bash
# 创建带 labels 的 pod
k create -f kubia-manual-with-labels.yaml

k get po --show-labels
#NAME                       READY   STATUS    RESTARTS   AGE     LABELS
#kubia                      1/1     Running   0          135m    run=kubia
#kubia-manual               1/1     Running   0          57m     <none>
#kubia-manual-with-labels   1/1     Running   0          2m11s   creation_method=manual,env=prod

# -L 将我们感兴趣的标签显示在对应的列中
k get po -L creation_method,env
#NAME                       READY   STATUS    RESTARTS   AGE     CREATION_METHOD   ENV
#kubia                      1/1     Running   0          137m
#kubia-manual               1/1     Running   0          58m
#kubia-manual-with-labels   1/1     Running   0          3m43s   manual            prod

# 使用 selector 过滤
kubectl get pods -l creation_method=manual
#NAME                       READY   STATUS    RESTARTS   AGE
#kubia-manual-with-labels   1/1     Running   0          6m23s
```

#### 3.3.3 修改现有 pod 标签

```bash
# 修改标签
k label po kubia-manual creation_method=manual

kubectl get pods -l creation_method=manual
#NAME                       READY   STATUS    RESTARTS   AGE
#kubia-manual               1/1     Running   0          65m
#kubia-manual-with-labels   1/1     Running   0          10m

# 修改标签时必须增加 --overwrite
k label po kubia-manual-with-labels env=debug --overwrite

k get pods -l env=debug -L creation_method,env
#NAME                       READY   STATUS    RESTARTS   AGE     CREATION_METHOD   ENV
#kubia-manual-with-labels   1/1     Running   0          2m36s   manual            debug
```

#### 3.4 使用标签选择器

```bash
# 选择标签
k get po -l creation_method=manual

# 选择标签 env=deubg
k get po -l env=debug
#NAME                       READY   STATUS    RESTARTS   AGE
#kubia-manual-with-labels   1/1     Running   0          4m47s

# 选择不包含 env 标签的 pod
k get po -l '!env' --show-labels
#NAME           READY   STATUS    RESTARTS   AGE     LABELS
#kubia          1/1     Running   0          5m56s   run=kubia
#kubia-manual   1/1     Running   0          5m45s   <none>
```

- env!=debug
- env in (prd, dev)
- env notin(prd, dev)
- Creation_method=manual,env=debug

#### 3.5 使用标签和选择器来约束 pod 调度

> 当我们希望控制 pod 的调度的时候，我们不会说明 pod 应该被调度到哪个节点上，这会使得我们的应用程序和基础架构强耦合。
>
> 我们应该 **描述应用对节点的需求，使得 kubernetes 选择一些符合这些需求的节点。**
>
> 标签可以附加到 kubernetes 的任意对象上，**这也包括了我们新增加的节点。**

#### 3.5.1 使用标签分类工作节点

```bash
# 查询所有节点
k get nodes --show-labels
#NAME           STATUS   ROLES                  AGE   VERSION   LABELS
#minikube       Ready    control-plane,master   19h   v1.20.7   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,gpu=true,kubernetes.io/arch=amd64,kubernetes.io/hostname=minikube,kubernetes.io/os=linux,minikube.k8s.io/commit=76d74191d82c47883dc7e1319ef7cebd3e00ee11,minikube.k8s.io/name=minikube,minikube.k8s.io/updated_at=2021_10_27T15_26_02_0700,minikube.k8s.io/version=v1.21.0,node-role.kubernetes.io/control-plane=,node-role.kubernetes.io/master=
#minikube-m02   Ready    <none>                 25m   v1.20.7   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=minikube-m02,kubernetes.io/os=linux
#minikube-m03   Ready    <none>                 25m   v1.20.7   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=minikube-m03,kubernetes.io/os=linux

# 为 name=minikube 的节点增加标签 gpu=true
k label nodes minikube gpu=true

k get nodes -l gpu=true
#NAME       STATUS   ROLES                  AGE   VERSION
#minikube   Ready    control-plane,master   19h   v1.20.7
```

#### 3.5.2 将 pod 调度到特定节点

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-gpu
spec:
  nodeSelector:
    gpu: "true"
  containers:
    - image: luksa/kubia
      name: kubia
```

#### 3.5.3 调度到一个特定节点

> 每个 node 包含一个唯一标签：`kubernetes.io/hostname`

```bash
k get nodes -L kubernetes.io/hostname
#NAME           STATUS   ROLES                  AGE   VERSION   HOSTNAME
#minikube       Ready    control-plane,master   19h   v1.20.7   minikube
#minikube-m02   Ready    <none>                 54m   v1.20.7   minikube-m02
#minikube-m03   Ready    <none>                 53m   v1.20.7   minikube-m03
```

### 3.6 注解 pod

1. 注解也是键值对；
2. 注解不能像标签一样对对象进行分组；
3. 一般来说，新功能的 alpha 和 beta 版本不会向API对象引入任何新的字段，因此使用的是注解而不是字段，一旦确定会引入新的字段并废弃注解；

#### 3.6.1 查找对象的注解

```bash
# 为 kubia-manual 添加注解
k annotate pod kubia-manual mycompany.com/someannotation="foo bar"

k get pods kubia-manual -o yaml | head -n 10
#apiVersion: v1
#kind: Pod
#metadata:
#  annotations:
#    mycompany.com/someannotation: foo bar
#  creationTimestamp: "2021-10-28T02:26:55Z"
#  managedFields:
#  - apiVersion: v1
#    fieldsType: FieldsV1
#    fieldsV1:
```

### 3.7 使用命名空间对资源进行分组

#### 3.7.1 了解对 namespace 的需求

通过 namesapce，我们可以将包含大量组件的复杂系统拆分为更小的不同组，例如我们可以将资源分配为 dev，prd 以及 QA。

#### 3.7.2 发现其他 namespace 以及 pod

```bash
# 查询所有namespace
k get ns
#NAME                   STATUS   AGE
#default                Active   22h
#kube-node-lease        Active   22h
#kube-public            Active   22h
#kube-system            Active   22h
#kubernetes-dashboard   Active   22h

# 查询对应 namespace 下的 pod
k get pods --namespace kube-system
#NAME                               READY   STATUS    RESTARTS   AGE
#coredns-74ff55c5b-klnsq            1/1     Running   1          22h
#etcd-minikube                      1/1     Running   1          22h
#kindnet-dpbdl                      1/1     Running   1          22h
#kindnet-f5sxx                      1/1     Running   1          22h
#kindnet-qn6vb                      1/1     Running   1          22h
#kube-apiserver-minikube            1/1     Running   1          22h
#kube-controller-manager-minikube   1/1     Running   1          22h
#kube-proxy-gvnp2                   1/1     Running   1          22h
#kube-proxy-mfpn4                   1/1     Running   1          22h
#kube-proxy-zqg4v                   1/1     Running   1          22h
#kube-scheduler-minikube            1/1     Running   1          22h
#storage-provisioner                1/1     Running   1          22h
```

#### 3.7.3 创建一个 namspace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: custom-namespace
```

```bash
k create  -f custom-namespace.yaml
#namespace/custom-namespace created

# 也可以通过命令行直接创建
k create namespace custom-namespace-command
```

```bash
# 在对应的 namespace 下创建 pod
k create -f kubia-manual.yaml --namespace custom-namespace
```

#### 3.7.5 namespace 提供的隔离

namespace 将对象分隔到不同的组，只允许我们对属于特定 namespace 的对象进行操作，单实际上命名空间不提供对正在运行的对象的任何隔离。

例如，两个不同的命名空间的 pod 实际上是可以互相通信的。

```bash
# 获取 custom-namespace 下的 pod
k get pods --namespace custom-namespace -o wide
#NAME           READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
#kubia-manual   1/1     Running   0          11m   10.244.1.4   minikube-m02   <none>           <none>

# 进入 default 下的 pod
k exec -it kubia -- /bin/bash

curl http://10.244.1.4:8080
# You've hit kubia-manual
```

### 3.8 停止和移除 pod

> 在删除 pod 的过程中，kubernetes 向进程发送一个 SIGTERM 信号并等待一定时间使其正常关闭。
>
> 如果没有及时关闭，则通过 SIGKILL 终止该进程。

```bash
# 停止和移除 pod
k delete pods kubia-gpu
```

#### 3.8.2 使用标签选择器删除 pod

```bash
k delete po -l creation_method=manual
# pod "kubia-manual-with-labels" deleted

k delete ns custom-namespace
```

```bash
# 删除操作也只会在当前 namesapce 执行
k delete po kubia-manual

k get pods --namespace custom-namespace -o wide
#NAME           READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
#kubia-manual   1/1     Running   0          18m   10.244.1.4   minikube-m02   <none>           <none>

k delete po kubia-manual --namespace custom-namespace

k get pods --namespace custom-namespace -o wide
# No resources found in custom-namespace namespace.
```

#### 3.8.4 删除所有 pod

```bash
k delete po --all
```

## 4. 副本机制和其他控制器：部署托管的 pod

> 在实践中，我们基本不会手动创建 pod，而是创建 ReplicationController 或 Deployment 这样的资源，接着由他们创建并管理实际的 pod。
>
> 因为手动创建的 pod，而不是托管的 pod 可能会存在容灾方面的问题。

### 4.1 保持 pod 健康

> 只要将 pod 调度到某个节点，该节点上的 `kubelet` 就会运行 pod 的容器，从此只要该 pod 存在，就会保持运行。
>
> **如果容器的主进程崩溃（OOM 或者因为 BUG 导致的重启等），kubelet 会自动重启应用程序。**
>
> 但是，我们还是需要通过某种手段来保证 kubelet 能够探测容器的存活状态。因为假设我们的应用因为无限循环或者死锁而停止响应，为了确保应用程序在这种情况下可以重新启动，必须从外部程序检查应用程序的运行情况。

#### 4.1.1 介绍存活探针（liveness probe）

- HTTP GET 探针
- TCP Socket 探针
- Exec 探针

#### 4.1.2 创建基于 HTTP 的存活探针

```javascript
// 每五次请求会返回一次 500 错误码
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var requestCount = 0;

var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  requestCount++;
  if (requestCount > 5) {
    response.writeHead(500);
    response.end("I'm not well. Please restart me!");
    return;
  }
  response.writeHead(200);
  response.end("You've hit " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

```dockerfile
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
spec:
  containers:
    - image: luksa/kubia-unhealthy
      name: kubia
      livenessProbe:
        httpGet:
          path: /
          port: 8080
```

```bash
# 打包镜像
docker build -t kubia-liveness .

docker tag kubia-liveness luksa/kubia-liveness

# 创建 pod
k create -f kubia-liveness-probe.yaml

# 隔一段时间查看一下 pod 状态，看看 pod 是否有重启
k get po kubia-liveness
#NAME             READY   STATUS    RESTARTS   AGE
#kubia-liveness   1/1     Running   1          3m34s

# 查看 pod 状态
k describe po kubia-liveness
```

![kubectl-desc.png](kubectl-desc.png)

#### 4.1.4 配置存活探针的附加属性

- delay
- timeout
- period
- failure

#### 4.1.5 创建有效的存活探针

> 1. 存活探针不应该依赖于任何外部程序：例如，当服务器无法连接到后端数据库时，前端web服务器不应该返回失败。后端数据库的存活应该由数据库的存活探针来探测；
> 2. 存活探针应该足够轻量，避免消耗过多的资源；
> 3. 如果是任何基于 JVM 或者类似的应用，应该使用 HTTP GET 存货探针，如果是 exec 探针会因为启动过程而需要大量的计算资源。

### 4.2 了解 ReplicationController

> ReplicationController 用于确保 pod 始终运行，并且保证 pod 的数量不多不少。

![ReplicationController 重建 pod](ReplicationController 重建 pod.png)

![ReplicationController 的协调流程](ReplicationController 的协调流程.png)

#### ReplicationController 的三个部分

- label selector
- replica count
- pod template

![ReplicationController的三个关键部分](ReplicationController的三个关键部分.png)

#### 更改控制器的标签选择器或 pod 模板的效果

> 更改标签选择器和 pod 模板对现有 pod 没有影响。更改标签选择器会使得现有的 pod 脱离 ReplicationController 的范围，因此ReplicationController会停止关注他们。
>
> 在创建 pod 之后，ReplicationController 也不关心 pod 的实际内容（容器环境、环境变量等）。

> 注意，ReplicationController 会创建一个新的 pod 实例，与正在替换的实例无关。

#### 4.2.2 创建一个 ReplicationController

> 下面的配置文件上传到 API server 时，kubernetes 会创建一个名为 kubia 的 rc，它确保符合标签 app=kubia 的 pod 始终是3个。

```yaml
apiVersion: v1
# 这里定义了 rc
kind: ReplicationController
metadata:
  # rc 的名字
  name: kubia
spec:
  # pod 实例数量
  replicas: 3
  # selector 决定了 rc 的操作对象
  selector:
    app: kubia
  # 创建新 pod 使用的模板
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
        - name: kubia
          image: luksa/kubia
          ports:
            - containerPort: 8080
```

> 上面是正确的配置文件，下面是一个错误的配置文件。会抛出如下异常：
>
> The ReplicationController "kubia-rc" is invalid: spec.template.metadata.labels: Invalid value: map[string]string{"app":"kubia"}: `selector` does not match template `labels`
>
> `spec.selector` 必须和 `spec.template.metadata.labels` 中的标签完全匹配，否则启动的新的 pod 将不会使得实际的副本数量接近期望的副本数量。

```yaml
apiVersion: v1
# 这里定义了 rc
kind: ReplicationController
metadata:
  name: kubia-rc
spec:
  # pod 实例数量
  replicas: 3
  # selector 决定了 rc 的操作对象
  selector:
    app: kubia-rc
  # 创建新 pod 使用的模板
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
        - name: kubia
          image: luksa/kubia
          ports:
            - containerPort: 8080
```

> 我们也可以不指定 selector，这样它会自动根据 pod 模板中的标签自动配置，这也是 kubernetes 推荐的做法。

#### 4.2.3 使用 ReplactionController

```bash
k get pods
#NAME             READY   STATUS    RESTARTS   AGE
#kubia-rc-54vwv   1/1     Running   0          4m16s
#kubia-rc-j9hxn   1/1     Running   0          4m16s
#kubia-rc-lkmfk   1/1     Running   0          4m16s

# 删除第一个 pod
k delete pod kubia-rc-54vwv
# pod "kubia-rc-54vwv" deleted

# 再次查看，发现有一个新的 pod 被拉起了
k get pods
#NAME             READY   STATUS    RESTARTS   AGE
#kubia-rc-2l2q5   1/1     Running   0          38s
#kubia-rc-j9hxn   1/1     Running   0          5m27s
#kubia-rc-lkmfk   1/1     Running   0          5m27s
```

#### 控制器如何创建新 pod

控制器并不对 delete 行为产生任何操作，而是因为 delete 导致的 pod 数量不足，rc 来创建新的 pod 保证 pod 数量。

![创建新的pod代替原来的pod](创建新的pod代替原来的pod.png)

#### 应对节点故障

#### 4.2.4 将 pod 移入或移出 rc 的作用域

> 由 rc 创建的 pod 并不是绑定到 rc 上。而是 rc 管理所有 label 与之对应的 pod。
>
> 需要注意的问题是，只要 rc 的 `selector` 能匹配到 pod，就说明 pod 是正确的。

```bash
k get pod --show-labels
#NAME             READY   STATUS    RESTARTS   AGE   LABELS
#kubia-rc-2l2q5   1/1     Running   0          39m   app=kubia
#kubia-rc-j9hxn   1/1     Running   0          44m   app=kubia
#kubia-rc-lkmfk   1/1     Running   0          44m   app=kubia

# 为第一个 pod 增加一个新的标签
k label po kubia-rc-2l2q5 env=dev

# 查询之后发现，rc 没有拉起新的 pod，因为现在 rc 的 selector 还是能匹配到三个 pod 的
k get pod --show-labels
#NAME             READY   STATUS    RESTARTS   AGE   LABELS
#kubia-rc-2l2q5   1/1     Running   0          39m   app=kubia,env=dev
#kubia-rc-j9hxn   1/1     Running   0          44m   app=kubia
#kubia-rc-lkmfk   1/1     Running   0          44m   app=kubia

# 再次修改第一个
k label po kubia-rc-2l2q5 app=kubia-dev --overwrite

# 查询发现 rc 拉起了新的 pod，因为此时 selector 已经匹配不到三个 pod 了。
k get pod --show-labels
#NAME             READY   STATUS              RESTARTS   AGE   LABELS
#kubia-rc-2l2q5   1/1     Running             0          42m   app=kubia-dev,env=dev
#kubia-rc-hx8zx   0/1     ContainerCreating   0          2s    app=kubia
#kubia-rc-j9hxn   1/1     Running             0          47m   app=kubia
#kubia-rc-lkmfk   1/1     Running             0          47m   app=kubia
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-gpu
  labels:
    app: "kubia"
    gpu: "true"
spec:
  containers:
    - image: luksa/kubia
      name: kubia
```

> 如果我们使用上面的配置重新拉起一个pod的话，我们可以发现找不到新的 labels，因为此时pod数量已经满足需求

```bash
# 查看 rc 状态，发现新创建的pod已经被删除
k get pod --show-labels
#NAME             READY   STATUS    RESTARTS   AGE   LABELS
#kubia-rc-2l2q5   1/1     Running   0          91m   app=kubia-dev,env=dev
#kubia-rc-hx8zx   1/1     Running   0          49m   app=kubia
#kubia-rc-j9hxn   1/1     Running   0          96m   app=kubia
#kubia-rc-jht4f   1/1     Running   0          32m   app=kubia

k describe rc kubia-rc
#Events:
#  Type    Reason            Age                 From                    Message
#  ----    ------            ----                ----                    -------
#  Normal  SuccessfulCreate  21m                 replication-controller  Created pod: kubia-rc-hx8zx
#  Normal  SuccessfulCreate  5m36s               replication-controller  Created pod: kubia-rc-jht4f
#  Normal  SuccessfulDelete  7s (x3 over 3m35s)  replication-controller  Deleted pod: kubia-gpu
```

现在 kubia-rc-2l2q5 已经完全脱离了 rc 的管控。

#### 4.2.5 修改 pod 模板

> 修改 pod 模板并不会影响已经创建的 pod。**要修改旧的pod，我们得删除他们后等 rc 拉起新的 pod**

![修改 pod 模板](修改 pod 模板.png)

```bash
# 可以使用以下命令编辑 rc
k edit rc kubia-rc
```

#### 4.2.6 水平缩放 pod

> 调整 spec.replicas 即可达到水平缩放。
>
> kubernetes 的水平伸缩是 `声名式` 的。

#### ReplicationController 扩容

```bash
# 扩容
k scale rc kubia-rc --replicas=10

# 缩容
k scale rc kubia-rc --replicas=3
```

#### 4.2.7 删除 rc

> 删除 rc 会使得 pod 也会被删除，可以通过增加 --cascade=false 使得 pod 保留

```bash
k delete rc kubia-rc --cascade=false

k get pod --show-labels
#NAME             READY   STATUS    RESTARTS   AGE   LABELS
#kubia-rc-2l2q5   1/1     Running   0          16h   app=kubia-dev,env=dev
#kubia-rc-hx8zx   1/1     Running   0          15h   app=kubia
#kubia-rc-j9hxn   1/1     Running   0          16h   app=kubia
#kubia-rc-jht4f   1/1     Running   0          15h   app=kubia
#kubia-rc-txpcl   1/1     Running   0          42m   app=kubia

# 但是删除 pod 之后，又可以重建并通过 label 重新关联
k create -f kubia-rc.yaml
```

### 4.3 使用 ReplicaSet 而不是 ReplicationController

> rs 是 rc 的替代品，通常不会直接创建它们，而是在创建 Deployment 时自动的创建 rs

#### 4.3.1 比较 rs 和 rc

> rs 的匹配能力相对于 rc 说更强；

#### 4.3.2 定义 rs

```yaml
# 注意，这里不是 v1 的 api
# 这里使用 api组 -> apps
# 以及声明了实际的 api 版本 v1beta2
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
        - name: kubia
          image: luksa/kubia
```

```bash
# 执行
k create -f kubia-replicaset.yaml
# error: unable to recognize "kubia-replicaset.yaml": no matches for kind "ReplicaSet" in version "apps/v1beta2"

# 查询 kubernetes api 版本
k api-versions | grep apps
# apps/v1

# 修改 apiVersion 版本
k create -f kubia-replicaset.yaml
```

```bash
# 查询 pod
k get pod --show-labels
#NAME             READY   STATUS    RESTARTS   AGE    LABELS
#kubia-kk4n4      1/1     Running   0          118s   app=kubia
#kubia-pls4g      1/1     Running   0          118s   app=kubia
#kubia-rc-2l2q5   1/1     Running   0          16h    app=kubia-dev,env=dev
#kubia-rc-c7n88   1/1     Running   0          28m    app=kubia
#kubia-rc-hx8zx   1/1     Running   0          16h    app=kubia
#kubia-rc-j9hxn   1/1     Running   0          16h    app=kubia
#kubia-rc-jht4f   1/1     Running   0          15h    app=kubia
#kubia-rvm2w      1/1     Running   0          118s   app=kubia
```

#### 4.3.4 使用 rs 的标签选择器

- In
- NotIn
- Exists ：不指定 values
- DoesNotExist ： 不指定 values

```yaml
spec:
  replicas: 3
  selector:
    matchLabels:
      - key: app
        operator: in
        values:
          - kubia
```

### 4.4 使用 DaemonSet 在每个节点上运行一个 pod

> rs 和 rc 会在 kubernetes 上部署特定数量的 pod。但是有的时候我们可能希望在集群的每个节点上部署一个 pod 实例就需要用到 DaemonSet 了。

#### 4.4.1 使用 DaemonSet

> 1. DaemonSet 没有期望pod数的说法；
> 2. DaemonSet 在新节点加入节点时，会自动的新加pod；

#### 4.4.2 使用 DaemonSet 只在特定的节点上运行 pod

> DaemonSet 将 pod 部署到集群中的所有节点上，除非这些 pod 只在部分节点上运行 -- 也就是说 pod 设置了 nodeSelector 属性。

#### 用一个例子解释 DaemonSet

> 假设 ssd-monitor 需要在所有使用固态硬盘的节点上运行。
>
> 
>
> 下面的 yaml 声明了一个如下的 DaemonSet：
>
> DaemonSet 匹配包含标签 `app=ssd-monitor` 的 pod。
>
> template 存在一个 NODE_SELECTOR，保证 pod 只会部署在包含标签 `disk-ssd` 的机器上。

```yaml
apiVersion: apps/v1
# 指定类型为 DaemonSet
kind: DaemonSet
# DaemonSet 的名字为 ssd-monitor
metadata:
  name: ssd-monitor
spec:
  # DaemonSet 管理和 matchLabels 匹配的 pod
  selector:
    matchLabels:
      app: ssd-monitor
  # DaemonSet 的模板
  template:
    # 声明了 DaemonSet 的 label
    metadata:
      labels:
        app: ssd-monitor
    # 声明了选择器，表名只会在包含 disk=ssd 的 pod 上
    spec:
      nodeSelector:
        disk: ssd
      containers:
        - name: main
          image: luksa/ssd-monitor
```

```bash
k get ds
#NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
#ssd-monitor   0         0         0       0            0           disk=ssd        35s

# 没有自动拉起 pod
k get po
#No resources found in default namespace.

# 为机器打上标签
k label nodes minikube disk=ssd

# 很快就发现 pod 拉起了
k get po
#NAME                READY   STATUS              RESTARTS   AGE
#ssd-monitor-kvd2k   0/1     ContainerCreating   0          10s
```

### 4.5 运行执行单个任务的 pod

> 期望任务执行完之后就退出。

#### 4.5.1 Job 资源

![Job管理的pod会一直被重新安排](Job管理的pod会一直被重新安排.png)

#### 4.5.2 定义 Job 资源

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      # Job 不能使用默认的策略（always），因为他们不是要无限期的运行
      restartPolicy: OnFailure
      containers:
        - name: main
          image: luksa/batch-job
```

#### 4.5.3 看 Job 运行一个 pod

```bash
k create -f exporter.yaml

k get po --show-labels
#NAME                READY   STATUS        RESTARTS   AGE   LABELS
#batch-job-hpkmk     1/1     Running       0          19s   app=batch-job,controller-uid=95704705-974d-413c-a0bf-0d2a5db66dbc,job-name=batch-job

k logs batch-job-hpkmk
#Fri Oct 29 06:52:16 UTC 2021 Batch job starting
#Fri Oct 29 06:54:16 UTC 2021 Finished succesfully
```

#### 4.5.4 在 Job 中运行多个 pod 实例

> 作业可以配置为多个 pod 实例，并以并行或者串行的方式运行它们。

##### 顺序运行 Job pod

> 通过 completions: 5 使得 Job 运行多次

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      restartPolicy: OnFailure
      containers:
        - name: main
          image: luksa/batch-job
```

##### 并行运行 Job pod

> 通过 parallelism: 2 配置并行度为2

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  parallelism: 2
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      restartPolicy: OnFailure
      containers:
        - name: main
          image: luksa/batch-job
```

#### 4.5.5 限制 Job pod 完成任务的时间

> 1. activeDeadlineSeconds 可以限制 pod 时间，避免永远不结束
> 2. 还可以通过 spec.backoffLimit 指定重试次数，默认为 6.

### 4.6 安排 Job 定期运行或者将来运行一次

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: batch-job-every-fifteen-minutes
spec:
  # crontab
  schedule: "0,15,30,45 * * * *"
  # pod 最迟必须在预定时间后15秒开始运行，超过这个时间任务将被标记为 failed
  startingDeadlineSeconds: 15
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: periodic-batch-job
        spec:
          restartPolicy: OnFailure
          containers:
          - name: main
            image: luksa/batch-job
```





























































