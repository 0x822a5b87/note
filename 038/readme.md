# 从外部访问Kubernetes中的Pod

> - hostNetwork
> - hostPort
> - NodePort
> - LoadBalancer
> - Ingress

## 总结

> - hostNetwork：直接绑定到宿主机，并把 container 中的端口绑定到宿主机的端口；
> - hostPort：直接将容器的端口与所调度的节点上的端口路由，相对于 hostNetwork 可以对端口映射。如宿主机是 8080，而 container port 是 8086
> - NodePort ：在每台宿主机上都打开一个固定的端口；
> - LoadBalancer ： NodePort  + LB
> - Ingress

## hostNetwork

> 如果在Pod中使用`hostNetwork:true`配置的话，在这种pod中运行的应用程序可以直接看到pod启动的主机的网络接口。在主机的所有网络接口上都可以访问到该应用程序。以下是使用主机网络的pod的示例定义：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 1
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      hostNetwork: true
      containers:
      - image: luksa/kubia:v1
        name: nodejs
  selector:
    matchLabels:
      app: kubia
```

```bash
k get pods -o wide
#NAME                     READY   STATUS        RESTARTS   AGE   IP               NODE           NOMINATED NODE   READINESS GATES
#kubia-6f6f49cc8d-852kh   1/1     Running       0          3s    192.168.59.101   minikube-m02   <none>           <none>

k get nodes -o wide
#NAME           STATUS   ROLES                  AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE              KERNEL-VERSION   CONTAINER-RUNTIME
#minikube-m02   Ready    <none>                 21m   v1.22.3   192.168.59.101   <none>        Buildroot 2021.02.4   4.19.202         docker://20.10.8

curl 192.168.59.101:8080
#This is v1 running in pod minikube-m02
```

## hostPort

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia-host-port
spec:
  replicas: 1
  template:
    metadata:
      name: kubia-host-port
      labels:
        app: kubia-host-port
    spec:
      containers:
      - image: luksa/kubia:v1
        name: nodejs
        ports:
        - containerPort: 8080
          hostPort: 8086
  selector:
    matchLabels:
      app: kubia-host-port
```

```bash
k get pods -o wide
#NAME                               READY   STATUS    RESTARTS   AGE    IP               NODE           NOMINATED NODE   READINESS GATES
#kubia-host-port-5746bcb4f4-mw5np   1/1     Running   0          6m8s   10.244.2.2       minikube-m03   <none>           <none>

k get nodes -o wide
#NAME           STATUS   ROLES                  AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE              KERNEL-VERSION   CONTAINER-RUNTIME
#minikube-m03   Ready    <none>                 47m   v1.22.3   192.168.59.102   <none>        Buildroot 2021.02.4   4.19.202         docker://20.10.8

curl 192.168.59.102:808
#This is v1 running in pod kubia-host-port-5746bcb4f4-mw5np
```

## NodePort

> NodePort在kubenretes里是一个广泛应用的服务暴露方式。Kubernetes中的service默认情况下都是使用的`ClusterIP`这种类型，这样的service会产生一个ClusterIP，这个IP只能在集群内部访问，要想让外部能够直接访问service，需要将service type修改为 `nodePort`。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia-node-port
spec:
  replicas: 1
  template:
    metadata:
      name: kubia-node-port
      labels:
        app: kubia-node-port
    spec:
      containers:
      - image: luksa/kubia:v1
        name: nodejs
        ports:
        - containerPort: 8080
          #这里不用配置 hostPort
  selector:
    matchLabels:
      app: kubia-node-port
```

```yaml
kind: Service
apiVersion: v1
metadata:
  name: kubia-node-port-service
spec:
  type: NodePort
  ports:
    - port: 8080
      nodePort: 30000
  selector:
    app: kubia-node-port
```

```bash
k get nodes -o wide
#minikube       Ready    control-plane,master   5h6m   v1.22.3   192.168.59.100   <none>        Buildroot 2021.02.4   4.19.202         docker://20.10.8

minikube ssh -n=minikube

curl localhost:30000
#This is v1 running in pod kubia-node-port-b66c464bb-6lq49
```

## LoadBalancer

> LoadBalancer 就是云的LB + NodePort

```yaml
kind: Service
apiVersion: v1
metadata:
  name: kubia-load-balancer-service
spec:
  type: LoadBalancer
  ports:
  - port: 8080
  selector:
    app: kubia-node-port
```

```bash
#查询服务绑定到了哪个端口
k get svc -o wide
#NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE     SELECTOR
#kubia-load-balancer-service   LoadBalancer   10.111.148.33   <pending>     8080:30961/TCP   2m18s   app=kubia-node-port

minikube ssh -n=minikube

curl localhost:30961
#This is v1 running in pod kubia-node-port-b66c464bb-6lq49
```

## Ingress

> Ingress 是部署在 kubernetes 之上的 docker 容器，它的镜像包含一个像 nginx 或 HAProxy 的负载均衡器和一个控制器守护进程。
>
> 控制器守护器从 kubernetes 接受所需的 ingress 配置，它会生成一个 nginx 或 HAProxy 配置文件，并重新启动负载均衡器使得配置生效。

















































