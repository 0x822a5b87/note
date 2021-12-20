# 通过 docker-compose 设定 network

>Docker Compose 預設會幫你的應用程式設定一個 network，service 的每個容器都會加入 default network，並且該 network 上的其他容器都可以連接 (reachable) 以及發現 (discoverable) 與容器名稱相同的 hostname。

> 預設的 network 名稱是基於 “專案目錄名稱”，並加上 `_default`。例如：你的應用程式放在名為 `myapp` 的專案目錄中，而 `docker-compose.yml` 的內容如下：
>
> 下面的 docker-compose.yaml 会执行如下：
>
> 1. 建立一個名為 `myapp_default` 的 network
> 2. 使用 `web` 的設定建立容器，並以 `web` 這個名稱加入名為 `myapp_default` 的 network
> 3. 使用 `db` 的設定建立容器，並以 `db` 這個名稱加入名為 `myapp_default` 的 network

```yaml
version: '3'

services:
  web:
    build: .
    ports:
      - '8000:8000'
  db:
    image: postgres
    ports:
      - '8001:5432'
```

> 可以看到，我们会创建一个 `050_default` 的 network（因为我们的文件名在 `050/` 目录下）

```bash
docker-compose up -d
#Docker Compose is now in the Docker CLI, try `docker compose up`
#
#Creating network "050_default" with the default driver
#Building web
```

現在，每個容器都可以找到名為 `web` 或 `db` 的 hostname，並獲得對應容器的 IP 位址。例如：`web` 的應用程式的程式碼可以連接到 `postgres://db:5432` 的 URL，並開始使用 Postgres 資料庫。

## 更新容器

> docker-compose up

## 指定自定 network

> 若不想使用預設的 app network，可以使用 [top-level `networks` key](https://docs.docker.com/compose/compose-file/#network-configuration-reference) 來指定自己的 network，讓你可以建立更複雜的拓撲，並指定 [custom network driver](https://docs.docker.com/engine/extend/plugins_network/) 和 option。還可以使用它，將 service 連接到不由 Compose 管理，而是由外部建立的 network。

> 下面的 docker-compose.yaml 会如下执行：
>
> 1. 初始化 proxy 容器，并且加入到 frontend network 中；
> 2. 初始化 app 容器，同时加入 frontend network 以及 backend network；
> 3. 初始化 db 容器，并且加入到 backend network；
> 4. 声明 frontend 和 backend 两个不同的网络。

```yaml
version: '3'

services:
  proxy:
    build: ./proxy
    networks:
      - frontend
  app:
    build: ./app
    networks:
      - frontend
      - backend
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    # Use a custom driver
    driver: custom-driver-1
  backend:
    # Use a custom driver which takes special options
    driver: custom-driver-2
    driver_opts:
      foo: '1'
      bar: '2'
```

## 使用 pre-existing network

> 通过 `external` 指定在 `docker-compose.yaml` 外声明的 network。

下面的例子中，会使用外部的 network -> `my-network-name`，并在 docker-compose.yaml 中声明了别名 `my-network`

```yaml
version: "3.7"

services:
  app:
    image: whatever
    networks:
    - my-network

networks:
  my-network:
    external:
      name: my-network-name
```

> proxy 是通往外部世界的 gateway，他会在找到一个外部的 outside network 并连接。

```yaml
version: "3.7"

services:
  proxy:
    build: ./proxy
    networks:
      - outside
      - default
  app:
    build: ./app
    networks:
      - default

networks:
  outside:
    external: true
```



















































