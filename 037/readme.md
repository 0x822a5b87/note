#### istio

## istio example

### 获取 istio gateway NodePort 地址

```bash
#端口
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
#https 端口
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
#host
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "$GATEWAY_URL"
#192.168.99.101:32440
```

### http service

#### Dockerfile

```dockerfile
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

#### app.js

```javascript
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  response.writeHead(200);
  response.end("You've hit v1 " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

#### Dokcerfile

```dockerfile
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app-v2.js"]
```

#### app-v2.js

```javascript
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  response.writeHead(200);
  response.end("You've hit v2 " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

#### 打包镜像

```bash
# 针对 v1 和 v2 分别打包镜像
docker build -t kubia-v1 .
docker tag kubia-v1 mirrors.tencent.com/ieg-data-public-test/kubia-v1:latest
sudo docker push mirrors.tencent.com/ieg-data-public-test/kubia-v1:latest

docker build -t kubia-v2 .
docker tag kubia-v1 mirrors.tencent.com/ieg-data-public-test/kubia-v2:latest
sudo docker push mirrors.tencent.com/ieg-data-public-test/kubia-v2:latest
```

### kubernetes

#### v1 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia-server
  #May match selectors of replication controllers and services
  labels:
    tenc-service: kubia-server
    version: v1
spec:
  replicas: 3
  #Label selector for pods. Existing ReplicaSets whose pods are selected by this will be the ones affected by this deployment. It must match the pod template's labels.
  selector:
    matchLabels:
      tenc-service: kubia-server
      version: v1
  template:
    metadata:
      #May match selectors of replication controllers and services.
      labels:
        tenc-service: kubia-server
        version: v1
    spec:
      containers:
      - image: mirrors.tencent.com/ieg-data-public-test/kubia-v1:latest
        name: kubia-server
```

#### v2

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia-server-v2
  #May match selectors of replication controllers and services
  labels:
    tenc-service: kubia-server
    version: v2
spec:
  replicas: 1
  #Label selector for pods. Existing ReplicaSets whose pods are selected by this will be the ones affected by this deployment. It must match the pod template's labels.
  selector:
    matchLabels:
      tenc-service: kubia-server
      version: v2
  template:
    metadata:
      #May match selectors of replication controllers and services.
      labels:
        tenc-service: kubia-server
        version: v2
    spec:
      containers:
      - image: mirrors.tencent.com/ieg-data-public-test/kubia-v2:latest
        name: kubia-server-v2
```

#### service

>service 绑定到 `kubia-server-v1` 和 `kubia-server-v2`的pod。
>
>我们可以在集群内通过 kubernetes 的 FQDN 访问他们了。
>
>```bash
>curl kubia-service:8080
>#You've hit kubia-server-77b8dfb768-jxlcw
>```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-service
  #May match selectors of replication controllers and services
  labels:
    tenc-service: kubia-server
spec:
  clusterIP: None
  ports:
  - name: http-8080
    port: 8080
    protocol: TCP
    targetPort: 8080
  #Route service traffic to pods with label keys and values matching this selector.
  #Only applies to types ClusterIP, NodePort, and LoadBalancer. Ignored if type is ExternalName.
  selector:
    tenc-service: kubia-server
```

### istio

> - `Gateway` 描述了一个在网格边缘运行的负载均衡器，接收传入或传出的 HTTP/TCP 连接。该规范描述了一组应该暴露的端口、要使用的协议类型、负载均衡器的 SNI 配置等。
> - `VirtualService` 主要配置流量路由
> - `DestinationRule` 定义了在路由发生后适用于服务流量的策略。这些规则指定了负载均衡的配置、来自 sidecar 的连接池大小，以及用于检测和驱逐负载均衡池中不健康主机的离群检测设置。

#### gateway

> Istio 会启动 `istio-egressgateway`,`istio-ingressgateway`,`istiod`等多个服务，其中 `istio-ingressgateway` 带有一个标签 `istio=istio-ingressgateway`。
>
> 我们会在 Gateway 中选中这个 service。
>
> ```bash
> k get service -n istio-system
> #NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE
> #istio-egressgateway    ClusterIP      10.100.126.37    <none>        80/TCP,443/TCP                                                               24h
> #istio-ingressgateway   LoadBalancer   10.100.149.56    <pending>     15021:30778/TCP,80:32440/TCP,443:30197/TCP,31400:32278/TCP,15443:32492/TCP   24h
> #istiod                 ClusterIP      10.108.112.180   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                                        24h
> ```

> `hosts` 的意思是 gateway 声明的 hosts。
>
> 比如说，我们设置 hosts: "127.0.0.1"，随后我们通过 CLB 127.0.0.1 绑定到这个  gateway。那么后续我们通过CLB访问的时候，http 的请求头就会带上 `header: 127.0.0.1`。这个时候 gateway 就会生效了。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubia-service-gateway
spec:
  selector:
    # use istio default controller
    istio: ingressgateway 
  #A list of server specifications.
  servers:
  - port:
      number: 8080
      name: http
      protocol: HTTP
    #One or more hosts exposed by this gateway.
    hosts:
    - "*"
```

#### VirtualService

> hosts 配置项和 Gateway 的 hosts 含义大概相同。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kubia-vs
spec:
  #The destination hosts to which traffic is being sent.
  hosts:
  - "*"
  gateways:
  - kubia-service-gateway
  http:
  #A HTTP rule can either redirect or forward (default) traffic.
  - route:
    - destination:
       #The name of a service from the service registry.
        host: kubia-service.default.svc.cluster.local      # 指定 K8S 中的 svc 资源名字
        subset: dr-v1
        port:
          number: 8080
      weight: 50
    - destination:
        host: kubia-service.default.svc.cluster.local      # 指定 K8S 中的 svc 资源名字
        subset: dr-v2
        port:
          number: 8080
      weight: 50
```

#### DestinationRule

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: kubia-dr
  namespace: default
spec:
  host: kubia-service.default.svc.cluster.local            # 指定 K8S 中的 svc 资源名字
  subsets:
  - labels:
      version: v1
    name: dr-v1
  - labels:
      version: v2
    name: dr-v2
```

### 总结

整个数据链路是

> kuerbernetes NodePort -> Gateway -> VirtualService -> DestinationRule -> 不同版本的 service。

1. Gateway 通过标签 `istio: ingressgateway ` 找到了对应的 istio service，同时我们在最开始通过 `$GATEWAY_URL` 找到了 `istio-ingressgateway` 暴露到集群外的 NodePort，我们所有的流量都是通过 NodePort 流入 `istio-ingressgateway`；
2. VirtualService 中通过 `gateway: kubia-service-gateway` 关联到我们的 Gateway，并配置了将 `kubia-service.default.svc.cluster.local  `的流量转发到 `dr-v1` 和 `dr-v2` 的规则；
3. DestinationRule 没有和 VirtualService 关联，只是直接声明了对于服务 `kubia-service.default.svc.cluster.local  `的 `dr-v1` 还有 `dr-v2` 的识别方式（通过 labels）；















