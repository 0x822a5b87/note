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

#### gateway

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubia-service-gateway
spec:
  selector:
    # use istio default controller
    istio: ingressgateway 
  servers:
  - port:
      number: 8080
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

#### VirtualService

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kubia-vs
spec:
  hosts:
  - "*"
  gateways:
  - kubia-service-gateway
  http:
  - route:
    - destination:
        host: kubia-service.default.svc.cluster.local      # 指定 K8S 中的 svc 资源名字
        subset: v1
        port:
          number: 8080
      weight: 50
    - destination:
        host: kubia-service.default.svc.cluster.local      # 指定 K8S 中的 svc 资源名字
        subset: v2
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
    name: v1
  - labels:
      version: v2
    name: v2
```

















