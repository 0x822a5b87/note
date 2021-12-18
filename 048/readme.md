# golang channel 入门

## 定义 channel

```go
// 定义 int 类型 chan
ch := make(chan int)

// 定义带缓冲区的 chan
ch := make(chan int, 10)
```

## 发送数据和写入数据

```go
// 从 ch 中读取数据到 value
// 如果 chan 被 close，则 ok != nil
value, ok := <-ch
```

