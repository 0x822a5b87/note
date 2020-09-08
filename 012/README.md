# GDB 调试入门

GDB 主要用于调试编译型语言，对 C，C++，Go，Fortran 等语言有内置的支持，但它不支持解释型语言。

## 1. 环境搭建

### 1.1 编写程序

```cpp
#include <iostream>

void Func(const char *s)
{
	printf("input : %s\n", s);
	int *p = nullptr;
	int &r = static_cast<int &>(*p);

	int num = std::atoi(s);
	r = num;
	printf("%d\n", r);
}

int main(int argc, char *argv[])
{
	if (argc != 2)
	{
		printf("test [int]\n");
		return -1;
	}
	Func(argv[1]);
	return 0;
}
```

### 1.2 编译

```bash
g++ -g -std=c++11 -m 64 -o test gdb.cpp
```

## 2. 调试示例

```bash
sudo gdb test
```

### 2.2 运行

```gdb
set args 1 2 3
```

抛出异常

```
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_ACCESS (code=1, address=0x0)
    frame #0: 0x0000000100000ef4 test`Func(s="10") at gdb.cpp:10:4
   7   		int &r = static_cast<int &>(*p);
   8
   9   		int num = std::atoi(s);
-> 10  		r = num;
   11  		printf("%d\n", r);
   12  	}
   13
Target 0: (test) stopped.
```

### 2.3 断点

```gdb
# 设置断点
b Func(char const*)

# 查看函数代码
l Func

# 查看当前函数栈的代码
l

# 输出变量
p s
# (const char *) $6 = 0x00007ffeefbff39f "10"
```

### 3.5 修改

```gdb
set variable i = 10
```

## 4. corefile

core dump / crash dump / memory dump / system dump 都是指一个程序在特定时间崩溃（crash）时的内存记录，它包含了很多关键信息，比如寄存器（包括程序计数器和堆栈指针），内存管理信息，操作系统标志信息等。corefile 就是转储（dump）时的快照，corefile可以被重新执行用以调试错误信息。

### 4.1 生成

```bash
ulimit -c
# unlimited
```

如果结果是 0 则说明系统禁止了 corefile 的生成，需要执行 `ulimit -c unlimited` 来让 corefile 能够正常生成。以刚才的示例程序为例，先执行 test 文件，生成一个 corefile：

### 4.2 调试


