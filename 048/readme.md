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

// 向 chan 写入数据
ch <- 10
```

## 在 chan 关闭的时候退出

> 明显使用 for range 最优雅

```go
// 使用 range
	for i := range ch2 {
		fmt.Println(i)
	}

// 自己判断
	for {
		i, ok := <-ch2
		if !ok {
			break
		}
		fmt.Println(i)
	}

	for i, ok := <-ch2; ok; i, ok = <-ch2 {
		fmt.Println(i)
	}
```

## 单向通道

```go
package main

import "fmt"

// 只写 chan
func counter(out chan<- int) {
	for i := 0; i < 10; i++ {
		out <- i
	}
	close(out)
}

// 只写 chan 和 只读 chan
func squarer(out chan<- int, in <-chan int) {
	for i := range in {
		out <- i * i
	}
	close(out)
}

// 只读 chan
func printer(in <-chan int) {
	for i := range in {
		fmt.Println(i)
	}
}

func CreateChannel() {
	ch1 := make(chan int)
	ch2 := make(chan int)
	go counter(ch1)
	go squarer(ch2, ch1)
	printer(ch2)
}
```

## 通道总结

| channel | 无缓冲 | 非空                                    | 空的                    | 满了                                    | 没满 |
| ------- | ------ | --------------------------------------- | ----------------------- | --------------------------------------- | ---- |
| 读      | 阻塞   | 接受值                                  | 阻塞                    | 接收值                                  |      |
| 写      | 阻塞   | 发送值                                  | 发送值                  | 阻塞                                    |      |
| 关闭    | panic  | 关闭成功,<br />读完数据后返回<br />零值 | 关闭成功,<br />返回零值 | 关闭成功,<br />读完数据后<br />返回零值 |      |



























