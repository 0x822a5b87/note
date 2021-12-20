# [envoy-example](https://github.com/envoyproxy/envoy/tree/main/examples)

## reference

- [front proxy](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/front_proxy)
- [Double proxy (with `mTLS` encryption)](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/double-proxy)
- [Envoy mesh 教程](https://jimmysong.io/kubernetes-handbook/usecases/envoy-mesh-in-kubernetes-tutorial.html)
- [envoy tutorial](https://github.com/rootsongjc/envoy-tutorial)
- [envoy-steps](https://github.com/datawire/envoy-steps)

## [front proxy](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/front_proxy)

> https://github.com/envoyproxy/envoy/tree/main/examples/front-proxy

![docker_compose_front_proxy](docker_compose_front_proxy.svg)

### docker-compose.yaml

> **docker-compose.yaml**
>
> 1. 启动了三个 container，分别是 `front-envoy`, `servce1`,`service2`
> 2. `front-envoy` 暴露了 8080，8443，8001 三个端口
> 3. 三个 container 共同使用 networks `envoymesh`

```yaml
version: "3.7"
services:

  front-envoy:
    build:
      context: .
      dockerfile: Dockerfile-frontenvoy
    networks:
    - envoymesh
    ports:
    - "8080:8080"
    - "8443:8443"
    - "8001:8001"

  service1:
    build:
      context: .
      dockerfile: Dockerfile-service
    volumes:
    - ./service-envoy.yaml:/etc/service-envoy.yaml
    networks:
    - envoymesh
    environment:
    - SERVICE_NAME=1

  service2:
    build:
      context: .
      dockerfile: Dockerfile-service
    volumes:
    - ./service-envoy.yaml:/etc/service-envoy.yaml
    networks:
    - envoymesh
    environment:
    - SERVICE_NAME=2

networks:
  envoymesh: {}
```

### Dockerfile-frontenvoy

> 1. 使用镜像 `envoyproxy/envoy-dev:latest`
> 2. 安装依赖
> 3. 复制 `./front-enovy.yaml` 到 `/etc/front-envoy.yaml` 作为配置文件
> 4. 通过 `/user/local/bin/envoy` 启动 envoy，并指定配置文件和 envoy 为 `front-proxy`

```dockerfile
FROM envoyproxy/envoy-dev:latest

RUN apt-get update && apt-get -q install -y \
    curl
COPY ./front-envoy.yaml /etc/front-envoy.yaml
RUN chmod go+r /etc/front-envoy.yaml
CMD ["/usr/local/bin/envoy", "-c", "/etc/front-envoy.yaml", "--service-cluster", "front-proxy"]
```

### Dockerfile-service

> 1. 使用 `envoyproxy/envoy-alpine-dev:latest` 镜像
> 2. 安装依赖
> 3. 复制代码 `./service.py`, `./start_service.sh`
> 4. 通过 `./start_service.sh` 启动服务

```dockerfile
FROM envoyproxy/envoy-alpine-dev:latest

RUN apk update && apk add py3-pip bash curl
RUN pip3 install -q Flask==0.11.1 requests==2.18.4
RUN mkdir /code
ADD ./service.py /code
ADD ./start_service.sh /usr/local/bin/start_service.sh
RUN chmod u+x /usr/local/bin/start_service.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/start_service.sh"]
```

### service.py

> 1. 服务监听 `8080` 端口，并且实现了两个路由，分别是 `/service/<service_number>` 和 `/trace/<service_number`
> 2. `/trace/<service_number` 接口读取了环境变量 `SERVICE_NAME`，并在 `SERVICE_NAME` == 1 的时候去请求 `requests.get("http://localhost:9000/trace/2", headers=headers)`

```python
from flask import Flask
from flask import request
import os
import requests
import socket
import sys

app = Flask(__name__)

TRACE_HEADERS_TO_PROPAGATE = [
    'X-Ot-Span-Context',
    'X-Request-Id',

    # Zipkin headers
    'X-B3-TraceId',
    'X-B3-SpanId',
    'X-B3-ParentSpanId',
    'X-B3-Sampled',
    'X-B3-Flags',

    # Jaeger header (for native client)
    "uber-trace-id",

    # SkyWalking headers.
    "sw8"
]


@app.route('/service/<service_number>')
def hello(service_number):
  return ('Hello from behind Envoy (service {})! hostname: {} resolved'
          'hostname: {}\n'.format(os.environ['SERVICE_NAME'], socket.gethostname(),
                                  socket.gethostbyname(socket.gethostname())))


@app.route('/trace/<service_number>')
def trace(service_number):
  headers = {}
  # call service 2 from service 1
  if int(os.environ['SERVICE_NAME']) == 1:
    for header in TRACE_HEADERS_TO_PROPAGATE:
      if header in request.headers:
        headers[header] = request.headers[header]
    requests.get("http://localhost:9000/trace/2", headers=headers)
  return ('Hello from behind Envoy (service {})! hostname: {} resolved'
          'hostname: {}\n'.format(os.environ['SERVICE_NAME'], socket.gethostname(),
                                  socket.gethostbyname(socket.gethostname())))


if __name__ == "__main__":
  app.run(host='127.0.0.1', port=8080, debug=True)
```

### start_service.py

```python
#!/bin/sh
python3 /code/service.py &
envoy -c /etc/service-envoy.yaml --service-cluster "service${SERVICE_NAME}"
```

### front-envoy.yaml

> 这个是 front-envoy 的 `[bootstrap](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/bootstrap/v3/bootstrap.proto#config-bootstrap-v3-bootstrap)`，配置了 front-envoy 的数据转发规则。
>
> ```yaml
> {
>   "node": "{...}",
>   "static_resources": "{...}",
>   "dynamic_resources": "{...}",
>   "cluster_manager": "{...}",
>   "hds_config": "{...}",
>   "flags_path": "...",
>   "stats_sinks": [],
>   "stats_config": "{...}",
>   "stats_flush_interval": "{...}",
>   "stats_flush_on_admin": "...",
>   "watchdog": "{...}",
>   "watchdogs": "{...}",
>   "tracing": "{...}",
>   "layered_runtime": "{...}",
>   "admin": "{...}",
>   "overload_manager": "{...}",
>   "enable_dispatcher_stats": "...",
>   "header_prefix": "...",
>   "stats_server_version_override": "{...}",
>   "use_tcp_for_dns_lookups": "...",
>   "dns_resolution_config": "{...}",
>   "typed_dns_resolver_config": "{...}",
>   "bootstrap_extensions": [],
>   "fatal_actions": [],
>   "default_socket_interface": "...",
>   "inline_headers": [],
>   "perf_tracing_file_path": "..."
> }
> ```

```yaml
# envoy 静态配置
static_resources:
  # 配置 listeners，它的参数是一个 list。
  listeners:
  # 监听 8080 端口
    # address 配置了 envoy 需要监听的端口
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 8080
    # 该 listener 的 filter chains
    filter_chains:
      # 一组独立的 network filter，他们组成了 filter chains 用于和 listener 建立连接
      # 如果 filter chains 是空的，那么默认连接直接关闭
    - filters:
        # 配置 http 连接 filter，每个 filter 的实际配置取决于具体的类型
        # 使用 name 去初始化对应的 filter，必须匹配
        # https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/network_filters#config-network-filters
        # 中声明的 filter
      - name: envoy.filters.network.http_connection_manager
        # 特定 filter 的配置，取决于我们在 name 中声明的 filter 类型
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          # 指定连接的编码类型
          codec_type: auto
          # REQUIRED，连接管理器的统计信息的可读前缀
          stat_prefix: ingress_http
          # 静态路由表的静态路由信息，动态路由信息在 rds 中配置
          route_config:
            name: local_route
            # 组成路由表的一些 virtual host
            virtual_hosts:
              # virtual host 的逻辑名，与我们的实际路由无关。
            - name: backend
              # 与我们的 virtual host 匹配的 domain 列表
              domains:
              - "*"
              # 匹配的路由规则
              routes:
                # 和 domains 结合的效果是
                # 对于 host 为 *（任意 host），并且 path 前缀为 /service/1 的请求将被路由到集群 service1
              - match:
                  prefix: "/service/1"
                route:
                  cluster: service1
              - match:
                  prefix: "/service/2"
                route:
                  cluster: service2
          # 一些由 http filter 组成的 filter chain，对发向 connection manager 的 request 进行过滤
          http_filters:
          - name: envoy.filters.http.router
            typed_config: {}
  # 监听 8443 端口
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 8443
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/service/1"
                route:
                  cluster: service1
              - match:
                  prefix: "/service/2"
                route:
                  cluster: service2
          http_filters:
          - name: envoy.filters.http.router
            typed_config: {}

      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          common_tls_context:
            tls_certificates:
              # The following self-signed certificate pair is generated using:
              # $ openssl req -x509 -newkey rsa:2048 -keyout a/front-proxy-key.pem -out  a/front-proxy-crt.pem -days 3650 -nodes -subj '/CN=front-envoy'
              #
              # Instead of feeding it as an inline_string, certificate pair can also be fed to Envoy
              # via filename. Reference: https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-datasource.
              #
              # Or in a dynamic configuration scenario, certificate pair can be fetched remotely via
              # Secret Discovery Service (SDS). Reference: https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret.
              certificate_chain:
                inline_string: |
                  -----BEGIN CERTIFICATE-----
                  MIICqDCCAZACCQCquzpHNpqBcDANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDDAtm
                  cm9udC1lbnZveTAeFw0yMDA3MDgwMTMxNDZaFw0zMDA3MDYwMTMxNDZaMBYxFDAS
                  BgNVBAMMC2Zyb250LWVudm95MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
                  AQEAthnYkqVQBX+Wg7aQWyCCb87hBce1hAFhbRM8Y9dQTqxoMXZiA2n8G089hUou
                  oQpEdJgitXVS6YMFPFUUWfwcqxYAynLK4X5im26Yfa1eO8La8sZUS+4Bjao1gF5/
                  VJxSEo2yZ7fFBo8M4E44ZehIIocipCRS+YZehFs6dmHoq/MGvh2eAHIa+O9xssPt
                  ofFcQMR8rwBHVbKy484O10tNCouX4yUkyQXqCRy6HRu7kSjOjNKSGtjfG+h5M8bh
                  10W7ZrsJ1hWhzBulSaMZaUY3vh5ngpws1JATQVSK1Jm/dmMRciwlTK7KfzgxHlSX
                  58ENpS7yPTISkEICcLbXkkKGEQIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCmj6Hg
                  vwOxWz0xu+6fSfRL6PGJUGq6wghCfUvjfwZ7zppDUqU47fk+yqPIOzuGZMdAqi7N
                  v1DXkeO4A3hnMD22Rlqt25vfogAaZVToBeQxCPd/ALBLFrvLUFYuSlS3zXSBpQqQ
                  Ny2IKFYsMllz5RSROONHBjaJOn5OwqenJ91MPmTAG7ujXKN6INSBM0PjX9Jy4Xb9
                  zT+I85jRDQHnTFce1WICBDCYidTIvJtdSSokGSuy4/xyxAAc/BpZAfOjBQ4G1QRe
                  9XwOi790LyNUYFJVyeOvNJwveloWuPLHb9idmY5YABwikUY6QNcXwyHTbRCkPB2I
                  m+/R4XnmL4cKQ+5Z
                  -----END CERTIFICATE-----
              private_key:
                inline_string: |
                  -----BEGIN PRIVATE KEY-----
                  MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC2GdiSpVAFf5aD
                  tpBbIIJvzuEFx7WEAWFtEzxj11BOrGgxdmIDafwbTz2FSi6hCkR0mCK1dVLpgwU8
                  VRRZ/ByrFgDKcsrhfmKbbph9rV47wtryxlRL7gGNqjWAXn9UnFISjbJnt8UGjwzg
                  Tjhl6EgihyKkJFL5hl6EWzp2Yeir8wa+HZ4Achr473Gyw+2h8VxAxHyvAEdVsrLj
                  zg7XS00Ki5fjJSTJBeoJHLodG7uRKM6M0pIa2N8b6HkzxuHXRbtmuwnWFaHMG6VJ
                  oxlpRje+HmeCnCzUkBNBVIrUmb92YxFyLCVMrsp/ODEeVJfnwQ2lLvI9MhKQQgJw
                  tteSQoYRAgMBAAECggEAeDGdEkYNCGQLe8pvg8Z0ccoSGpeTxpqGrNEKhjfi6NrB
                  NwyVav10iq4FxEmPd3nobzDPkAftfvWc6hKaCT7vyTkPspCMOsQJ39/ixOk+jqFx
                  lNa1YxyoZ9IV2DIHR1iaj2Z5gB367PZUoGTgstrbafbaNY9IOSyojCIO935ubbcx
                  DWwL24XAf51ez6sXnI8V5tXmrFlNXhbhJdH8iIxNyM45HrnlUlOk0lCK4gmLJjy9
                  10IS2H2Wh3M5zsTpihH1JvM56oAH1ahrhMXs/rVFXXkg50yD1KV+HQiEbglYKUxO
                  eMYtfaY9i2CuLwhDnWp3oxP3HfgQQhD09OEN3e0IlQKBgQDZ/3poG9TiMZSjfKqL
                  xnCABMXGVQsfFWNC8THoW6RRx5Rqi8q08yJrmhCu32YKvccsOljDQJQQJdQO1g09
                  e/adJmCnTrqxNtjPkX9txV23Lp6Ak7emjiQ5ICu7iWxrcO3zf7hmKtj7z+av8sjO
                  mDI7NkX5vnlE74nztBEjp3eC0wKBgQDV2GeJV028RW3b/QyP3Gwmax2+cKLR9PKR
                  nJnmO5bxAT0nQ3xuJEAqMIss/Rfb/macWc2N/6CWJCRT6a2vgy6xBW+bqG6RdQMB
                  xEZXFZl+sSKhXPkc5Wjb4lQ14YWyRPrTjMlwez3k4UolIJhJmwl+D7OkMRrOUERO
                  EtUvc7odCwKBgBi+nhdZKWXveM7B5N3uzXBKmmRz3MpPdC/yDtcwJ8u8msUpTv4R
                  JxQNrd0bsIqBli0YBmFLYEMg+BwjAee7vXeDFq+HCTv6XMva2RsNryCO4yD3I359
                  XfE6DJzB8ZOUgv4Dvluie3TB2Y6ZQV/p+LGt7G13yG4hvofyJYvlg3RPAoGAcjDg
                  +OH5zLN2eqah8qBN0CYa9/rFt0AJ19+7/smLTJ7QvQq4g0gwS1couplcCEnNGWiK
                  72y1n/ckvvplmPeAE19HveMvR9UoCeV5ej86fACy8V/oVpnaaLBvL2aCMjPLjPP9
                  DWeCIZp8MV86cvOrGfngf6kJG2qZTueXl4NAuwkCgYEArKkhlZVXjwBoVvtHYmN2
                  o+F6cGMlRJTLhNc391WApsgDZfTZSdeJsBsvvzS/Nc0burrufJg0wYioTlpReSy4
                  ohhtprnQQAddfjHP7rh2LGt+irFzhdXXQ1ybGaGM9D764KUNCXLuwdly0vzXU4HU
                  q5sGxGrC1RECGB5Zwx2S2ZY=
                  -----END PRIVATE KEY-----

  # 配置 clusters
  clusters:
    # service1 的配置
    # Supplies the name of the cluster which must be unique across all clusters. 
  - name: service1
    connect_timeout: 0.25s
    # 解析 cluster 的服务发现类型
    type: strict_dns
    lb_policy: round_robin
    http2_protocol_options: {}
    # 如果设置了 static，strict_dns，logical_dns 作为服务发现，那么这个参数是必要的
    # 来自 RDS 的每条路由都将映射到单个集群或使用 RDS WeightedCluster 中表示的权重跨集群拆分的流量。
    load_assignment:
      # Name of the cluster. This will be the service_name value if specified in the cluster EdsClusterConfig.
      cluster_name: service1
      endpoints:
        # The group of endpoints belonging to the locality specified.
      - lb_endpoints:
          # Upstream host identifier or a named reference.
        - endpoint:
            # The upstream host address.
            address:
              socket_address:
                # 在 Dockerfile-service 中，我们指定通过 service_start.sh 启动 envoy
                # 而 service_start.sh 指定了 --service-cluster "service${SERVICE_NAME}" 作为集群名
                # 此外，我们在 docker-compose.yaml 中指定了所有的 container 使用同一个 networks
                address: service1
                port_value: 8000
    # service2 的配置
  - name: service2
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    http2_protocol_options: {}
    load_assignment:
      cluster_name: service2
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: service2
                port_value: 8000
# 管理端配置
admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8001
layered_runtime:
  layers:
    - name: static_layer_0
      static_layer:
        envoy:
          resource_limits:
            listener:
              example_listener_name:
                connection_limit: 10000
```

> 整个文件根目录下只有三个模块：
>
> 1. static_resources 声明了 envoy 的静态资源，包含了 `listeners` 和 `clusters`
> 2. admin 管理端配置并监听了 `8001` 端口，还记得之前我们在 `docker-compose.yaml` 里暴露的三个端口就包含了它。
> 3. layered_runtime 配置了 `runtime configuration provider`

![envoy-front-proxy-root-element](envoy-front-proxy-root-element.png)

#### static_resources

> static_resources 配置了 envoy 的静态资源，我们还可以通过 `**dynamic_resources**` 去配置动态的资源。
>
> ```yaml
> # static_resources 下可以配置的参数
> {
>   "listeners": [],
>   "clusters": [],
>   "secrets": []
> }
> ```
>
> 1. listeners 配置了可用的监听器，在 dynamic_resources 中对应于 `LDS`
> 2. clusters 配置了集群，在 dynamic_resources 中对应于 `CDS`，如果为 cds_config 指定了基于网络的配置源，则需要有一些可用的初始集群定义，以允许 Envoy 知道如何与管理服务器对话。 这些集群定义可能不使用 EDS（即它们应该是静态 IP 或基于 DNS 的）。
> 3. Secrets 对应于 `SDS`

![envoy-front-proxy-static_resources](./envoy-front-proxy-static_resources.png)

### service-envoy.yaml

```yaml
# service envoy 的配置
static_resources:
  listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 8000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/service"
                route:
                  cluster: local_service
          http_filters:
          - name: envoy.filters.http.router
            typed_config: {}
  clusters:
  - name: local_service
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    load_assignment:
      cluster_name: local_service
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8081
```

## [Double proxy (with `mTLS` encryption)](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/double-proxy)

> This sandbox demonstrates a basic “double proxy” configuration, in which a simple Flask app connects to a PostgreSQL database, with two Envoy proxies in between.

> Envoy (front)` -> `Flask` -> `Envoy (postgres-front)` -> `Envoy (postgres-back)` -> `PostgreSQL

### create certificate

#### Step 1: Create a certificate authority

```bash
pwd
#envoy/examples/double-proxy
mkdir -p certs
openssl genrsa -out certs/ca.key 4096
openssl req -x509 -new -nodes -key certs/ca.key -sha256 -days 1024 -out certs/ca.crt
```

#### Step 2: Create a domain key

```bash
openssl genrsa -out certs/example.com.key 2048
```

#### Step 3: Generate certificate signing requests for the proxies

>Use the domain key to generate certificate signing requests for each of the proxies:

```bash
openssl req -new -sha256 \
     -key certs/example.com.key \
     -subj "/C=US/ST=CA/O=MyExample, Inc./CN=proxy-postgres-frontend.example.com" \
     -out certs/proxy-postgres-frontend.example.com.csr
     
 openssl req -new -sha256 \
     -key certs/example.com.key \
     -subj "/C=US/ST=CA/O=MyExample, Inc./CN=proxy-postgres-backend.example.com" \
     -out certs/proxy-postgres-backend.example.com.csr
```

#### Step 4: Sign the proxy certificates

>You can now use the certificate authority that you created to sign the certificate requests.
>
>Note the `subjectAltName`. This is used for reciprocally matching and validating the certificates.

```bash
openssl x509 -req \
     -in certs/proxy-postgres-frontend.example.com.csr \
     -CA certs/ca.crt \
     -CAkey certs/ca.key \
     -CAcreateserial \
     -extfile <(printf "subjectAltName=DNS:proxy-postgres-frontend.example.com") \
     -out certs/postgres-frontend.example.com.crt \
     -days 500 \
     -sha256
     
openssl x509 -req \
     -in certs/proxy-postgres-backend.example.com.csr \
     -CA certs/ca.crt \
     -CAkey certs/ca.key \
     -CAcreateserial \
     -extfile <(printf "subjectAltName=DNS:proxy-postgres-backend.example.com") \
     -out certs/postgres-backend.example.com.crt \
     -days 500 \
     -sha256
```

### Start all of our containers

```bash
docker-compose build --pull

docker-compose up -d

docker-compose ps
```

#### docker-compose.yaml

> 配置文件声明了五个不同的 container，并通过 network 将四个组件隔离。
>
> 1. 声明了 `edge`, `postgres-backend`, `postgres-frontend`, `postgres-in-between` 四个不同的 `network`
> 2. 声明了 `proxy-frontend`, `app`, `proxy-postgres-fronted`, `proxy-postgres-backend`, `postgres` 五个不同的 container
> 3. `edge` 包含了 proxy-frontend 和 app
> 4. `postgres-frontend` 包含了 app 和 proxy-postgres-frontend
> 5. `postgres-in-between` 包含了 proxy-postgres-frontend 和 proxy-postgres-backend
> 6. `postgres-backend` 包含了 proxy-postgres-backend 和 postgres

```yaml
version: "3.7"
services:

  # Envoy( front )
  proxy-frontend:
    build:
      context: .
      dockerfile: Dockerfile-proxy
    networks:
      edge:
    ports:
      - "10000:10000"

  # Flash
  app:
    build:
      context: .
      dockerfile: Dockerfile-app
    networks:
      edge:
      postgres-frontend:

  # Envoy( postgres-front )
  proxy-postgres-frontend:
    build:
      context: .
      dockerfile: Dockerfile-proxy-frontend
    networks:
      postgres-frontend:
        aliases:
          - postgres
      postgres-in-between:

  # Envoy( postgres-back )
  proxy-postgres-backend:
    build:
      context: .
      dockerfile: Dockerfile-proxy-backend
    networks:
      postgres-backend:
      postgres-in-between:
        aliases:
        - proxy-postgres-backend.example.com

  # PostgreSQL
  postgres:
    image: postgres:latest
    networks:
      postgres-backend:
    environment:
      # WARNING! Do not use it on production environments because this will
      #          allow anyone with access to the Postgres port to access your
      #          database without a password, even if POSTGRES_PASSWORD is set.
      #          See PostgreSQL documentation about "trust":
      #          https://www.postgresql.org/docs/current/auth-trust.html
      POSTGRES_HOST_AUTH_METHOD: trust

networks:
  edge:
    name: edge

  postgres-backend:
    name: postgres-backend

  postgres-frontend:
    name: postgres-frontend

  postgres-in-between:
    name: postgres-in-between
```

#### Dockerfile-proxy

> 整个架构对外暴露的服务，Flask 通过该 proxy 对外暴露。

```go
FROM envoyproxy/envoy-dev:latest

COPY ./envoy.yaml /etc/envoy.yaml
RUN chmod go+r /etc/envoy.yaml
CMD ["/usr/local/bin/envoy", "-c /etc/envoy.yaml", "-l", "debug"]
```

#### envoy.yaml

> envoy.yaml 的配置很简单，就是将所有入流量转发到 `app:8000`，其中 app 是 container，因为和 proxy-front 在同一个 network 中，所以可以直接访问。

```yaml
# 静态配置
static_resources:
  listeners:
    # 绑定 listener 到 0.0.0.0:10000
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            # 匹配所有 host
            virtual_hosts:
              # 所有的请求都转发到 cluster : service1
            - name: app
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/"
                route:
                  cluster: service1
          http_filters:
          - name: envoy.filters.http.router

  clusters:
    # service1 使用 strict_dns 作为服务发现类型，连接超时时间为 0.25s
    # 并且绑定到 app:8000
  - name: service1
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    load_assignment:
      cluster_name: service1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: app
                port_value: 8000
```

#### Dockerfile-app

```go
FROM python:3.8-alpine

RUN apk update && apk add postgresql-dev gcc python3-dev musl-dev
RUN pip3 install -q Flask==0.11.1 requests==2.18.4 psycopg2-binary
RUN mkdir /code
ADD ./service.py /code
ENTRYPOINT ["python3", "/code/service.py"]
```

#### service.py

>由于我们在 `docker-compose.yaml` 文件中设置了 `postgres-frontend` 的别名为 `postgres`，所以我们可以直接通过 `postgres` 去访问数据库。

```python
import sys

from flask import Flask

import psycopg2

app = Flask(__name__)


@app.route('/')
def hello():
  conn = psycopg2.connect("host=postgres user=postgres")
  cur = conn.cursor()
  cur.execute('SELECT version()')
  msg = 'Connected to Postgres, version: %s' % cur.fetchone()
  cur.close()
  return msg


if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8000, debug=True)
```

#### Dockerfile-proxy-frontend

```go
FROM envoyproxy/envoy-dev:latest

COPY ./envoy-frontend.yaml /etc/envoy.yaml
COPY ./certs/ca.crt /certs/cacert.pem
COPY ./certs/postgres-frontend.example.com.crt /certs/clientcert.pem
COPY ./certs/example.com.key /certs/clientkey.pem

RUN chmod go+r /etc/envoy.yaml /certs/cacert.pem /certs/clientkey.pem /certs/clientcert.pem
CMD ["/usr/local/bin/envoy", "-c /etc/envoy.yaml", "-l", "debug"]
```

#### envoy-frontend.yaml

```yaml
static_resources:
  listeners:
  - name: postgres_listener
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 5432
    filter_chains:
    - filters:
      - name: envoy.filters.network.postgres_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.postgres_proxy.v3alpha.PostgresProxy
          stat_prefix: egress_postgres
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: postgres_tcp
          cluster: postgres_cluster

  clusters:
  - name: postgres_cluster
    connect_timeout: 1s
    type: strict_dns
    load_assignment:
      cluster_name: postgres_cluster
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: proxy-postgres-backend.example.com
                port_value: 5432
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        common_tls_context:
          tls_certificates:
            certificate_chain:
              filename: certs/clientcert.pem
            private_key:
              filename: certs/clientkey.pem
          validation_context:
            match_subject_alt_names:
            - exact: proxy-postgres-backend.example.com
            trusted_ca:
              filename: certs/cacert.pem
```

#### Dockerfile-proxy-backend

```go
FROM envoyproxy/envoy-dev:latest

COPY ./envoy-backend.yaml /etc/envoy.yaml
COPY ./certs/ca.crt /certs/cacert.pem
COPY ./certs/postgres-backend.example.com.crt /certs/servercert.pem
COPY ./certs/example.com.key /certs/serverkey.pem

RUN chmod go+r /etc/envoy.yaml /certs/cacert.pem /certs/serverkey.pem /certs/servercert.pem
CMD ["/usr/local/bin/envoy", "-c /etc/envoy.yaml", "-l", "debug"]
```

#### envoy-backend.yaml

```yaml
static_resources:
  listeners:
  - name: postgres_listener
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 5432
    listener_filters:
    - name: "envoy.filters.listener.tls_inspector"
      typed_config: {}
    filter_chains:
    - filters:
      - name: envoy.filters.network.postgres_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.postgres_proxy.v3alpha.PostgresProxy
          stat_prefix: egress_postgres
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: postgres_tcp
          cluster: postgres_cluster
      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
          require_client_certificate: true
          common_tls_context:
            tls_certificates:
              certificate_chain:
                filename: certs/servercert.pem
              private_key:
                filename: certs/serverkey.pem
            validation_context:
              match_subject_alt_names:
              - exact: proxy-postgres-frontend.example.com
              trusted_ca:
                filename: certs/cacert.pem

  clusters:
  - name: postgres_cluster
    connect_timeout: 1s
    type: strict_dns
    load_assignment:
      cluster_name: postgres_cluster
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: postgres
                port_value: 5432
```

## [envoy-tutorial](https://github.com/rootsongjc/envoy-tutorial)

> envoy-tutorial 是在 envoy-steps 基础上的开发，因为 envoy-steps 仅仅是一个脚手架。 

![envoy-mesh-in-kubernetes](envoy-mesh-in-kubernetes.png)

### 部署应用

```bash
# 部署 pg 库
kubectl apply -f postgres

# 创建 usersvc 镜像
cd usersvc
docker build -t jimmysong/usersvc:step1 .

# 创建 usersvc
```

### 创建 namespace

```bash
kubectl apply -f postgres

kubectl apply -f usersvc

# 登录 usersvc 所在的 pod
curl localhost:5000/user/health
```

### postgres

#### deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      service: postgres
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        service: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:9.6.24-stretch
        env:
        - name: POSTGRES_PASSWORD
          value : "trust"
        resources: {}
      restartPolicy: Always
status: {}
```

#### service

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    service: postgres
  name: postgres
spec:
  type: ClusterIP
  ports:
  - name: postgres
    port: 5432
  selector:
    service: postgres
```

### usersvc

#### deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: usersvc
  namespace: envoy-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      service: usersvc
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        service: usersvc
    spec:
      containers:
      - name: usersvc
        image: jimmysong/usersvc:step1
        resources: {}
      restartPolicy: Always
status: {}
```

#### service

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    service: usersvc
  name: usersvc
  namespace: envoy-tutorial
spec:
  type: ClusterIP
  ports:
  - name: usersvc
    port: 80
    targetPort: 5000
  selector:
    service: usersvcpostgres-84b55d4df8-r7hg4
```





















