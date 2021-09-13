## arthas-tunnel-server

- [arthas-tunnel-server](https://arthas.aliyun.com/doc/tunnel.html#arthas-tunnel-server)

>通过Arthas Tunnel Server/Client 来远程管理/连接多个Agent。

## 简介

> [How arthas tunnel server work](https://github.com/alibaba/arthas/blob/master/tunnel-server/README.md#)

```
+---------+              +----------------------+              +----------------------+                +--------------+
| browser      | <----->  |     arthas tunnel server         | <-----> |       arthas tunnel client        |    <--- -> |   arthas agent      |
+---------+               +----------------------+              +----------------------+                +--------------+

```

我们使用 `arthas-tunnel-server` 的流程如下：

1. 开启 `arthas-tunnel-server`，它需要绑定两个端口，一个端口是提供 web 服务，另外一个端口是用于和 `agent` 通信；
2. 启动 `agent`，并连接到我们需要的 `arthas-tunnel-server`，启动 `agent` 有以下方式：
   1. 通过 **./as.sh --tunnel-server 'ws://127.0.0.1:8898/ws' --app-name test**
   2. 通过 **java -jar arthas-boot.jar --tunnel-server 'ws://127.0.0.1:8898/ws'**
   3. 对于 **spring boot 应用**，引用 `arthas-spring-boot-starter` 实现，具体参考 [Arthas Spring Boot Starter](https://arthas.aliyun.com/doc/spring-boot-starter.html)
   4. 对于 **非 spring boot 应用**，引用 `arthas-agent-attach` 和 `arthas-packaging` 依赖来实现。
3. 在 `arthas-tunnel-server` 的 web 服务上进行远程调试以及其他的操作。

## 下载部署arthas tunnel server

>从Github Releases页下载：https://github.com/alibaba/arthas/releases

Arthas tunnel server是一个spring boot fat jar应用，直接java -jar启动：

```java
java -jar  arthas-tunnel-server.jar --server.port=8899 --arthas.server.port=8898
```

## 启动arthas时连接到tunnel server

在启动arthas，可以传递--tunnel-server参数，比如：

```bash
as.sh --tunnel-server 'ws://127.0.0.1:8898/ws'
```

如果有特殊需求，可以通过`--agent-id`参数里指定agentId。默认情况下，会生成随机ID。

agent attach 成功之后，会打印出 agentId

```
  ,---.  ,------. ,--------.,--.  ,--.  ,---.   ,---.
 /  O  \ |  .--. ''--.  .--'|  '--'  | /  O  \ '   .-'
|  .-.  ||  '--'.'   |  |   |  .--.  ||  .-.  |`.  `-.
|  | |  ||  |\  \    |  |   |  |  |  ||  | |  |.-'    |
`--' `--'`--' '--'   `--'   `--'  `--'`--' `--'`-----'


wiki      https://arthas.aliyun.com/doc
tutorials https://arthas.aliyun.com/doc/arthas-tutorials.html
version   3.4.6
pid       60048
time      2021-09-09 11:27:24
id        test_BMVF3EXPRDOG1KBKOLEU
```

如果没有打印成功，可以通过 `session` 指令查看

```
[arthas@60048]$ session
 Name              Value
--------------------------------------------------------
 JAVA_PID          60048
 SESSION_ID        95c03582-dc46-4c23-9fd9-f57ec343b0ec
 AGENT_ID          test_BMVF3EXPRDOG1KBKOLEU
 TUNNEL_SERVER     ws://127.0.0.1:8898/ws
 TUNNEL_CONNECTED  true
```

## Tunnel Server的管理页面

在本地启动tunnel-server，然后使用`as.sh` attach，并且指定应用名`--app-name test`：

```bash
./as.sh --tunnel-server 'ws://127.0.0.1:8898/ws' --app-name test
```

- 通过 http://localhost:8899/apps.html 可以查看所有连接的应用列表
- 通过 http://localhost:8080/agents.html?app=test 可以查看所有的 agent

## URL

- [查看连接信息](http://127.0.0.1:8080/actuator/arthas)

>登陆用户名是arthas，密码在arthas tunnel server的日志里可以找到，比如：Using generated security password: `328768bf-457b-4edb-aa1e-8e35fa2bb35b`

