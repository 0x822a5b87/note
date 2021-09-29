# [OpenResty 最佳实践](https://moonbingbing.gitbooks.io/openresty-best-practices/content/)

## OpenResty 简介

OpenResty（也称为 ngx_openresty）是一个全功能的 Web 应用服务器。它打包了标准的 Nginx 核心，很多的常用的第三方模块，以及它们的大多数依赖项。

通过揉和众多设计良好的 Nginx 模块，OpenResty 有效地把 Nginx 服务器转变为一个强大的 Web 应用服务器，基于它开发人员可以使用 Lua 编程语言对 Nginx 核心以及现有的各种 Nginx C 模块进行脚本编程，构建出可以处理一万以上并发请求的极端高性能的 Web 应用。

OpenResty 致力于将你的服务器端应用完全运行于 Nginx 服务器中，充分利用 Nginx 的事件模型来进行 **非阻塞 I/O 通信**。不仅仅是和 HTTP 客户端间的网络通信是非阻塞的，与MySQL、PostgreSQL、Memcached 以及 Redis 等众多远方后端之间的网络通信也是非阻塞的。

## Lua 入门

- Lua 由标准 C 编写而成
- Lua 脚本可以很容易的被 C/C++ 代码调用，也可以反过来调用 C/C++ 的函数
- Lua 语言的各个版本是不相兼容的。因此本书只介绍 Lua 5.1 语言，这是为标准 Lua 5.1 解释器和 LuaJIT 2 所共同支持的。

### Lua 简介

Lua 有着如下的特性：

1. 变量名没有类型，值才有类型，变量名在运行时可与任何类型的值绑定;
2. 语言只提供唯一一种数据结构，称为表(table)，它混合了`数组`、`哈希`，可以用任何类型的值作为 key 和 value。提供了一致且富有表达力的表构造语法，使得 Lua 很适合描述复杂的数据;
3. 函数是一等类型，支持匿名函数和正则尾递归(proper tail recursion);
4. 支持词法定界(lexical scoping)和闭包(closure);
5. 提供 thread 类型和结构化的协程(coroutine)机制，在此基础上可方便实现协作式多任务;
6. 运行期能编译字符串形式的程序文本并载入虚拟机执行;
7. 通过元表(metatable)和元方法(metamethod)提供动态元机制(dynamic meta-mechanism)，从而允许程序运行时根据需要改变或扩充语法设施的内定语义;
8. 能方便地利用表和动态元机制实现基于原型(prototype-based)的面向对象模型;
9. 从 5.1 版开始提供了完善的模块机制，从而更好地支持开发大型的应用程序;

### Lua 和 LuaJIT 的区别

LuaJIT 利用了 JIT 技术来优化 Lua 的性能。

## Lua 环境搭建

```bash
echo 'print("hello world")' > hello.lua

luajit hello.lua
# hello world
```



























































