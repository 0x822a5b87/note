# CMake 入门实战

[CMake 入门实战](https://www.hahack.com/codes/cmake/)

## 什么是 CMake

1. 不同的 Make 工具遵循不同的规范和标准，`CMake` 是一种跨平台的工具来 `定制整个编译流程`。

### cmake 的编译过程

1. 编写 CMake 配置文件 `CMakeLists.txt `
2. 执行命令 `cmake ${PATH}` 或者 `ccmake ${PATH}` 生成 `Makefile`（ccmake 和 cmake 的区别在于前者提供了一个交互式的界面）。其中， PATH 是 CMakeLists.txt 所在的目录。
3. 执行 `make` 进行编译

## 入门案例：单个源文件

### c 语言源文件

```c
#include <stdio.h>
#include <stdlib.h>

/**
 * power - Calculate the power of number.
 * @param base: Base value.
 * @param exponent: Exponent value.
 *
 * @return base raised to the power exponent.
 */
double power(double base, int exponent)
{
    int result = base;
    int i;

    if (exponent == 0) {
        return 1;
    }
    
    for(i = 1; i < exponent; ++i){
        result = result * base;
    }

    return result;
}

int main(int argc, char *argv[])
{
    if (argc < 3){
        printf("Usage: %s base exponent \n", argv[0]);
        return 1;
    }
    double base = atof(argv[1]);
    int exponent = atoi(argv[2]);
    double result = power(base, exponent);
    printf("%g ^ %d is %g\n", base, exponent, result);
    return 0;
}
```

### cmake 文件

```cmake
# cmake 最低版本要求
cmake_minimum_required (VERSION 2.8)

# 项目信息
project (Demo1)

# 将 main.cc 源文件编译成一个名为 Demo 的可执行文件
add_executable(Demo main.cpp)
```

1. `cmake_minimum_required` : cmake 最低版本要求
2. `project` : 项目信息
3. `add_executable` : 将 `main.cpp` 源文件编译成一个名为 `Demo` 的可执行文件

### 编译过程

```bash
# 得到 Makefile
cmake .
# 执行编译
make
```

## 多个源文件

### 文件结构

```
./Demo2
    |
    +--- main.cc
    |
    +--- MathFunctions.cc
    |
    +--- MathFunctions.h
```

### cmake 文件

```cmake
cmake_minimum_required (VERSION 2.8)

project (Demo2)

# 查找目录下的所有源文件
# 并将源文件保存到 DIR_SRCS 变量
aux_source_directory(. DIR_SRCS)

# 指定生成目标
add_executable(Demo ${DIR_SRCS})
```

1. 我们可以通过 `add_executable(Demo main.cc MathFunctions.cc)` 来添加所有文件，不过如果文件太多会很麻烦，所以我们使用 `aux_source_directory` 命令
2. `aux_source_directory` 命令的语法是 `aux_source_directory(<dir> <variable>)` 将 `<dir>` 的值赋给 `<variable>`
3. `add_executable(Demo ${DIR_SRCS})` 将 `DIR_SRCS` 目录下的所有编译成 Demo


## 多个目录，多个源文件

```
./Demo3
    |
    +--- main.cc
    |
    +--- math/
          |
          +--- MathFunctions.cc
          |
          +--- MathFunctions.h
```

#### 主目录下的 makefile

```cmake
# CMake 最低版本号要求
cmake_minimum_required (VERSION 2.8)

# 项目信息
project (Demo3)

# 查找目录下的所有源文件
# 并将名称保存到 DIR_SRCS 变量
aux_source_directory(. DIR_SRCS)

# 添加 math 子目录
add_subdirectory(math)

# 指定生成目标
add_executable(Demo ${DIR_SRCS})

# 添加链接库
target_link_libraries(Demo MathFunctions)
```
1. 对于这种情况，需要分别在项目根目录 Demo3 和 math 目录里各编写一个 CMakeLists.txt 文件。为了方便，我们可以先将 math 目录里的文件编译成静态库再由 main 函数调用。
2. `add_subdirectory` 指定本项目包含子目录 math，这样 math 目录下的 `makefile` 文件和源代码也会被处理
3. `target_link_libraries` 指明可执行文件 main 需要一个名为 MathFunctions 的链接库

#### math 目录下的 makefile

```cmake
# 查找当前目录下的所有源文件
# 并将名称保存到 DIR_LIB_SRCS 变量
aux_source_directory(. DIR_LIB_SRCS)

# 指定生成 MathFunctions 链接库
add_library(MathFunctions ${DIR_LIB_SRCS})
```

1. `add_library` 将 src 目录中的源文件编译为静态链接库

## 自定义编译选项

CMake 允许为项目增加编译选项，从而可以根据用户的环境和需求选择最合适的编译方案。

例如，可以将 MathFunctions 库设为一个可选的库，如果该选项为 `ON` ，就使用该库定义的数学函数来进行运算。否则就调用标准库中的数学函数库。

### 修改 makefile

```cmake
# CMake 最低版本号要求
cmake_minimum_required (VERSION 2.8)

# 项目信息
project (Demo4)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

# 是否使用自己的 MathFunctions 库
option (USE_MYMATH
	   "Use provided math implementation" ON)

# 加入一个配置头文件，用于处理 CMake 对源码的设置
configure_file (
  "${PROJECT_SOURCE_DIR}/config.h.in"
  "${PROJECT_BINARY_DIR}/config.h"
  )

# 是否加入 MathFunctions 库
if (USE_MYMATH)
  include_directories ("${PROJECT_SOURCE_DIR}/math")
  add_subdirectory (math)
  set (EXTRA_LIBS ${EXTRA_LIBS} MathFunctions)
endif (USE_MYMATH)

# 查找当前目录下的所有源文件
# 并将名称保存到 DIR_SRCS 变量
aux_source_directory(. DIR_SRCS)

# 指定生成目标
add_executable (Demo ${DIR_SRCS})
target_link_libraries (Demo  ${EXTRA_LIBS})
```

1. `CMAKE_INCLUDE_CURRENT_DIR` : If this variable is enabled, CMake automatically adds in each directory ${CMAKE_CURRENT_SOURCE_DIR} and ${CMAKE_CURRENT_BINARY_DIR} to the include path for this directory
2. `configure_file` 命令的意思是，读取 `config.h.in` 配置文件，并生成 `config.h`
3. `option` 命令添加了一个 `USE_MYMATH` 选项，并且默认为 `ON`

### 配置文件

```
#cmakedefine USE_MYMATH
```

>如前面所提到的， `config.h.in` 定义了 USE_MYMATH 配置

#### [configure_file](https://cmake.org/cmake/help/latest/command/configure_file.html)

**Copy a file to another location and modify its contents.**

Consider a source tree containing a `foo.h.in` file:

```cmake
#cmakedefine FOO_ENABLE
#cmakedefine FOO_STRING "@FOO_STRING@"
```

An adjacent `CMakeLists.txt` may use `configure_file` to configure the header:

```cmake
option(FOO_ENABLE "Enable Foo" ON)
if(FOO_ENABLE)
  set(FOO_STRING "foo")
endif()
configure_file(foo.h.in foo.h @ONLY)
```

**This creates a `foo.h` in the build directory corresponding to this source directory. If the FOO_ENABLE option is on, the configured file will contain:**

```c
#define FOO_ENABLE
#define FOO_STRING "foo"
```

Otherwise it will contain:

```c
/* #undef FOO_ENABLE */
/* #undef FOO_STRING */
```

### 修改 main.cc

我们需要修改 `main.cc`，让其根据 `USE_MYMATH` 的预定义值来决定是否盗用标准库还是自定义的 MathFunctions 库：

```cpp
#include <stdio.h>
#include <stdlib.h>
#include "config.h"

#ifdef USE_MYMATH
  #include "math/MathFunctions.h"
#else
  #include <math.h>
#endif


int main(int argc, char *argv[])
{
    if (argc < 3){
        printf("Usage: %s base exponent \n", argv[0]);
        return 1;
    }
    double base = atof(argv[1]);
    int exponent = atoi(argv[2]);
    
#ifdef USE_MYMATH
    printf("Now we use our own Math library. \n");
    double result = power(base, exponent);
#else
    printf("Now we use the standard library. \n");
    double result = pow(base, exponent);
#endif
    printf("%g ^ %d is %g\n", base, exponent, result);
    return 0;
}
```

1. 我们在 main.cpp 中有使用到 `#include config.h`，**但是我们不直接编写 `config.h`，而是编写 `config.h.in` 并在 cmake 中生成 `config.h`**

### 编译项目

1. 使用 `ccmake .` 来进入一个交互式的配置界面，可以对 `USE_MYMATH` 字段进行配置
2. 配置完成之后使用 make 进行编译，这个时候会根据我们的配置来生成 `config.h`

## 安装和测试

CMake 也可以指定安装规则，以及添加测试。这两个功能分别可以通过在产生 Makefile 后使用 `make install` 和 `make test` 来执行。

### 定制安装规则

>首先在 math/CMakeLists.txt 文件里增加下面两行，指定 MathFunctions 将被安装到 /usr/local/bin 下

```cmake
# 指定 MathFunctions 库的安装路径
install (TARGETS MathFunctions DESTINATION bin)
install (FILES MathFunctions.h DESTINATION include)
```

>之后同样修改根目录的 CMakeLists 文件，在末尾添加下面几行：

```cmake
# 指定安装路径
install (TARGETS Demo DESTINATION bin)
install (FILES "${PROJECT_BINARY_DIR}/config.h"
         DESTINATION include)
```

1. 通过上面的定制，生成的 Demo 文件和 MathFunctions 函数库 libMathFunctions.o 文件将会被复制到 `/usr/local/bin` 中，而 `MathFunctions.h` 和生成的 `config.h` 文件则会被复制到 `/usr/local/include` 中。
2. `/usr/local/` 是默认安装到的根目录，可以通过修改 `CMAKE_INSTALL_PREFIX` 变量的值来指定这些文件应该拷贝到哪个根目录）

### [install](https://cmake.org/cmake/help/v3.13/command/install.html)

>Specify rules to run at install time.

`DESTINATION` : Specify the directory on disk to which a file will be installed. If a full path (with a leading slash or drive letter) is given it is used directly. If a relative path is given it is interpreted relative to the value of the `CMAKE_INSTALL_PREFIX` variable. The prefix can be relocated at install time using the DESTDIR mechanism explained in the `CMAKE_INSTALL_PREFIX` variable documentation.

```bash
# 指定生成文件夹的前缀
cmake -DCMAKE_INSTALL_PREFIX=/tmp .

make DESTDIR=~/tmp install
```

### 为工程添加测试

添加测试同样很简单。CMake 提供了一个称为 CTest 的测试工具。我们要做的只是在项目根目录的 CMakeLists 文件中调用一系列的 `add_test` 命令。

```cmake
# 启用测试
enable_testing()

# 测试程序是否成功运行
add_test (test_run Demo 5 2)

# 测试帮助信息是否可以正常提示
add_test (test_usage Demo)
set_tests_properties (test_usage
  PROPERTIES PASS_REGULAR_EXPRESSION "Usage: .* base exponent")

# 测试 5 的平方
add_test (test_5_2 Demo 5 2)

set_tests_properties (test_5_2
 PROPERTIES PASS_REGULAR_EXPRESSION "is 25")

# 测试 10 的 5 次方
add_test (test_10_5 Demo 10 5)

set_tests_properties (test_10_5
 PROPERTIES PASS_REGULAR_EXPRESSION "is 100000")

# 测试 2 的 10 次方
add_test (test_2_10 Demo 2 10)

set_tests_properties (test_2_10
 PROPERTIES PASS_REGULAR_EXPRESSION "is 1024")
```

1. `add_test (test_run Demo 5 2)` 用来测试程序是否成功运行并返回 0 值
2. 剩下的三个测试分别用来测试 5 的 平方、10 的 5 次方、2 的 10 次方是否都能得到正确的结果。其中 PASS_REGULAR_EXPRESSION 用来测试输出是否包含后面跟着的字符串

### 支持 gdb

让 CMake 支持 gdb 的设置也很容易，只需要指定 `Debug` 模式下开启 `-g` 选项：

```cmake
set(CMAKE_BUILD_TYPE "Debug")
set(CMAKE_CXX_FLAGS_DEBUG "$ENV{CXXFLAGS} -O0 -Wall -g -ggdb")
set(CMAKE_CXX_FLAGS_RELEASE "$ENV{CXXFLAGS} -O3 -Wall")
```

### 添加环境检查

有时候可能要对系统环境做点检查，例如要使用一个平台相关的特性的时候。在这个例子中，我们检查系统是否自带 pow 函数。如果带有 pow 函数，就使用它；否则使用我们定义的 power 函数。

#### 添加 CheckFunctionExists 宏

首先在顶层 CMakeLists 文件中添加 CheckFunctionExists.cmake 宏，并调用 check_function_exists 命令测试链接器是否能够在链接阶段找到 pow 函数。

```cmake
# 检查系统是否支持 pow 函数
include (${CMAKE_ROOT}/Modules/CheckFunctionExists.cmake)
check_function_exists (pow HAVE_POW)
```
