# [从零开始的 JSON 库教程](https://zhuanlan.zhihu.com/json-tutorial)

## tutorial01

### JSON 语法子集

```
JSON-text = ws value ws
ws = *(%x20 / %x09 / %x0A / %x0D)
value = null / false / true 
null  = "null"
false = "false"
true  = "true"
```

当中 `%xhh` 表示以 16 进制表示的字符，`/` 是多选一，`*` 是零或多个，`()` 用于分组。

那么第一行的意思是，JSON 文本由 3 部分组成，首先是空白（whitespace），接着是一个值，最后是空白。

第二行告诉我们，所谓空白，是由零或多个空格符（space U+0020）、制表符（tab U+0009）、换行符（LF U+000A）、回车符（CR U+000D）所组成。

第三行是说，我们现时的值只可以是 null、false 或 true，它们分别有对应的字面值（literal）。

### 宏的编写技巧

有些同学可能不了解 `EXPECT_EQ_BASE` 宏的编写技巧，简单说明一下。反斜线代表该行未结束，会串接下一行。而如果宏里有多过一个语句（statement），就需要用 `do { /*...*/ } while(0)` 包裹成单个语句，否则会有如下的问题：

```c
#define M() a(); b()

if (cond)
    M();
else
    c();

/* 预处理后 */

if (cond)
    a(); b(); /* b(); 在 if 之外     */
else          /* <- else 缺乏对应 if */
    c();
```

只用 `{ }` 也不行：

```c
#define M() { a(); b(); }

/* 预处理后 */

if (cond)
    { a(); b(); }; /* 最后的分号代表 if 语句结束 */
else               /* else 缺乏对应 if */
    c();
```

用 do while 就行了：

```c
#define M() do { a(); b(); } while(0)

/* 预处理后 */

if (cond)
    do { a(); b(); } while(0);
else
    c();
```

### 关于断言

初使用断言的同学，可能会错误地把含副作用的代码放在 assert() 中：

```c
assert(x++ == 0); /* 这是错误的! */
```

这样会导致 debug 和 release 版的行为不一样。

另一个问题是，初学者可能会难于分辨何时使用断言，何时处理运行时错误（如返回错误值或在 C++ 中抛出异常）。

简单的答案是， **如果那个错误是由于程序员错误编码所造成的（例如传入不合法的参数），那么应用断言；如果那个错误是程序员无法避免，而是由运行时的环境所造成的，就要处理运行时错误（例如开启文件失败）。**

### 代码实现总结

>对于 `LEPT_PARSE_ROOT_NOT_SINGULAR` 这个异常，我的实现是在 `lept_parse_true` 这些函数中实现；
><br/>
>而 answer 中的代码是在 `lept_parse` 中实现。
><br/>
>answer 的代码更好，因为 **每次 parse 完特定类型之后之后都需要做这个异常检查**

```c
static int lept_parse_false(lept_context* c, lept_value* v) {
    EXPECT(c, 'f');
    if (c->json[0] != 'a' || c->json[1] != 'l' || c->json[2] != 's' || c->json[3] != 'e')
    {
        return LEPT_PARSE_INVALID_VALUE;
    }
    c->json += 4;
    lept_parse_whitespace(c);
    if (*c->json != '\0')
    {
        return LEPT_PARSE_ROOT_NOT_SINGULAR;
    }
    else
    {
        v->type = LEPT_FALSE;
        return LEPT_PARSE_OK;
    }
}
```

```c
int lept_parse(lept_value* v, const char* json) {
    lept_context c;
    int ret;
    assert(v != NULL);
    c.json = json;
    v->type = LEPT_NULL;
    lept_parse_whitespace(&c);
    if ((ret = lept_parse_value(&c, v)) == LEPT_PARSE_OK) {
        lept_parse_whitespace(&c);
        if (*c.json != '\0')
            ret = LEPT_PARSE_ROOT_NOT_SINGULAR;
    }
    return ret;
}
```

## tutorial02

### JSON 数字语法

```
number = [ "-" ] int [ frac ] [ exp ]
int = "0" / digit1-9 *digit
frac = "." 1*digit
exp = ("e" / "E") ["-" / "+"] 1*digit
```

number 是以十进制表示，它主要由 4 部分顺序组成：负号、整数、小数、指数。只有整数是必需部分。注意和直觉可能不同的是，正号是不合法的。

整数部分如果是 0 开始，只能是单个 0；而由 1-9 开始的话，可以加任意数量的数字（0-9）。也就是说，0123 不是一个合法的 JSON 数字。

小数部分比较直观，就是小数点后是一或多个数字（0-9）。

JSON 可使用科学记数法，指数部分由大写 E 或小写 e 开始，然后可有正负号，之后是一或多个数字（0-9）。

![number](number.png)

### 总结

1. 为什么要把一些测试代码以 `#if 0 ... #endif` 禁用？

因为在做第 1 个练习题时，我希望能 100% 通过测试，方便做重构。另外，使用 #if 0 ... #endif 而不使用 /* ... */，是因为 C 的注释不支持嵌套（nested），而 #if ... #endif 是支持嵌套的。代码中已有注释时，用 #if 0 ... #endif 去禁用代码是一个常用技巧，而且可以把 0 改为 1 去恢复。

---

### **`个人总结`**

- 字面值数组的长度是字符长度+1：`sizeof("true") == 5`
- 在对数组进行 for 循环时可以使用如下技巧

```c
// 执行完之后 i 就是数组的长度
size_t i;
for (i = 0; literal[i]; ++i)
{
	// work
}
```

#### 语法手写为校验规则

![grammer](grammer.png)

1. 整个图分为 1，2，3 三个状态，我们每次的目的是达到 end。如果不能达到 end 那么 valid 失败
2. 要到达 `1`，我们可以通过两个途径，接受一个 `-` 或者 `""`
3. 根据代码，我们每一个模块可以到达下一个状态。
4. 在从一个状态到另外一个状态的过程中，可能还会有 `3 -> end` 这种比较复杂的状态变换，其实它相当于这个图的一个子模块。

```c
static int valid_number2(lept_context *c, char **end)
{
    const char *p = c->json;
    if (*p == '-')
        ++p;
	// 到达状态1

    if (*p == '0')
    {
        ++p;
    }
    else if (ISDIGIT1TO9(*p))
    {
        for (p++; ISDIGIT(*p); p++);
    }
    else
    {
        return LEPT_PARSE_INVALID_VALUE;
    }
	// 到达状态2

    if (*p == '.')
    {
        p++;
        if (!ISDIGIT(*p))
            return LEPT_PARSE_INVALID_VALUE;
        for (p++; ISDIGIT(*p); p++);
    }
	// 到达状态3

    if (*p == 'e' || *p == 'E')
    {
        p++;
        if (*p == '+' || *p == '-')
        {
            p++;
        }
        if (!ISDIGIT(*p))
            return LEPT_PARSE_INVALID_VALUE;
        for (p++; ISDIGIT(*p); p++){};
    }
	// 到达 end

    *end = p;
    return LEPT_PARSE_OK;
}
```

## tutorial03

### JSON 字符串语法


```
string = quotation-mark *char quotation-mark
char = unescaped /
   escape (
       %x22 /          ; "    quotation mark  U+0022
       %x5C /          ; \    reverse solidus U+005C
       %x2F /          ; /    solidus         U+002F
       %x62 /          ; b    backspace       U+0008
       %x66 /          ; f    form feed       U+000C
       %x6E /          ; n    line feed       U+000A
       %x72 /          ; r    carriage return U+000D
       %x74 /          ; t    tab             U+0009
       %x75 4HEXDIG )  ; uXXXX                U+XXXX
escape = %x5C          ; \
quotation-mark = %x22  ; "
unescaped = %x20-21 / %x23-5B / %x5D-10FFFF
```

简单翻译一下，JSON 字符串是由前后两个双引号夹着零至多个字符。字符分为 `无转义字符` 或 `转义序列`。转义序列有 9 种，都是以反斜线开始，如常见的 \n 代表换行符。比较特殊的是 \uXXXX，当中 XXXX 为 16 进位的 UTF-16 编码，本单元将不处理这种转义序列，留待下回分解。

### 2. 字符串表示

- JSON 允许 '\0' 字符，例如 "Hello\u0000World"

了解需求后，我们考虑实现。lept_value 事实上是一种变体类型（variant type），我们通过 type 来决定它现时是哪种类型，而这也决定了哪些成员是有效的。首先我们简单地在这个结构中加入两个成员：

```c
typedef struct {
    char* s;
    size_t len;
    double n;
    lept_type type;
}lept_value;
```

然而我们知道，一个值不可能同时为数字和字符串，因此我们可使用 C 语言的 union 来节省内存：

```c
typedef struct {
    union {
        struct { char* s; size_t len; }s;  /* string */
        double n;                          /* number */
    }u;
    lept_type type;
}lept_value;
```

### 3. 内存管理

由于字符串的长度不是固定的，我们要动态分配内存。为简单起见，我们使用标准库 `<stdlib.h>` 中的 `malloc()`、`realloc()` 和 `free()` 来分配／释放内存。

```c
void lept_set_string(lept_value* v, const char* s, size_t len) {
    assert(v != NULL && (s != NULL || len == 0));
    lept_free(v);
    v->u.s.s = (char*)malloc(len + 1);
    memcpy(v->u.s.s, s, len);
    v->u.s.s[len] = '\0';
    v->u.s.len = len;
    v->type = LEPT_STRING;
}
```

那么，再看看 lept_free()：

```c
void lept_free(lept_value* v) {
    assert(v != NULL);
    if (v->type == LEPT_STRING)
        free(v->u.s.s);
    v->type = LEPT_NULL;
}
```

但也由于我们会检查 `v` 的类型，在调用所有访问函数之前，我们必须初始化该类型。所以我们加入 lept_init(v)，因非常简单我们用宏实现：

```c
#define lept_init(v) do { (v)->type = LEPT_NULL; } while(0)
```

用上 `do { ... } while(0)` 是为了把表达式转为语句，模仿无返回值的函数。

其实在前两个单元中，我们只提供读取值的 API，没有写入的 API，就是因为写入时我们还要考虑释放内存。我们在本单元中把它们补全：

```c
#define lept_set_null(v) lept_free(v)

int lept_get_boolean(const lept_value* v);
void lept_set_boolean(lept_value* v, int b);

double lept_get_number(const lept_value* v);
void lept_set_number(lept_value* v, double n);

const char* lept_get_string(const lept_value* v);
size_t lept_get_string_length(const lept_value* v);
void lept_set_string(lept_value* v, const char* s, size_t len);
```

### 4. 缓冲区与堆栈

我们解析字符串（以及之后的数组、对象）时，需要把解析的结果先储存在一个临时的缓冲区，最后再用 lept_set_string() 把缓冲区的结果设进值之中。

**如果每次解析字符串时，都重新建一个动态数组，那么是比较耗时的。我们可以重用这个动态数组，每次解析 JSON 时就只需要创建一个。** 而且我们将会发现，无论是解析字符串、数组或对象，我们也只需要以先进后出的方式访问这个动态数组。换句话说，我们需要一个动态的堆栈（stack）数据结构。

我们把一个动态堆栈的数据放进 lept_context 里：

```c
typedef struct {
    const char* json;
    char* stack;
    size_t size, top;
}lept_context;
```

然后，我们实现堆栈的压入及弹出操作。和普通的堆栈不一样，我们这个堆栈是以字节储存的。每次可要求压入任意大小的数据，它会返回数据起始的指针（会 C++ 的同学可再参考[1]）：

```c
#ifndef LEPT_PARSE_STACK_INIT_SIZE
#define LEPT_PARSE_STACK_INIT_SIZE 256
#endif

static void* lept_context_push(lept_context* c, size_t size) {
    void* ret;
    assert(size > 0);
	// 如果超过栈的大小，就扩容
    if (c->top + size >= c->size) {
		// 初始化
        if (c->size == 0)
            c->size = LEPT_PARSE_STACK_INIT_SIZE;
		// 计算新的 size
        while (c->top + size >= c->size)
            c->size += c->size >> 1;  /* c->size * 1.5 */

		// realloc 复制数据到新的地址
        c->stack = (char*)realloc(c->stack, c->size);
    }

	// 返缓冲区的地址，缓冲区提供的大小为 size(不是 c->size)
    ret = c->stack + c->top;
	// 修改栈指针，这是信任外部的操作的。
	// 因为用户完全可以使用超过栈的空间
    c->top += size;
    return ret;
}

static void* lept_context_pop(lept_context* c, size_t size) {
    assert(c->top >= size);
    return c->stack + (c->top -= size);
}
```

解析字符串

```c
static int lept_parse_string(lept_context* c, lept_value* v) {
    size_t head = c->top, len;
    const char* p;
    EXPECT(c, '\"');
    p = c->json;
    for (;;) {
        char ch = *p++;
        switch (ch) {
			// 遇到 " 就退出并计算长度，这里注意。
			// 每次 PUTC 都会修改 c->top，那么结束是的 c->top - 开始时的 c->top 就是实际长度
            case '\"':
                len = c->top - head;
                lept_set_string(v, (const char*)lept_context_pop(c, len), len);
                c->json = p;
                return LEPT_PARSE_OK;
            case '\0':
                c->top = head;
                return LEPT_PARSE_MISS_QUOTATION_MARK;
            default:
                PUTC(c, ch);
        }
    }
}
```

### 个人总结

- 可以在 lept_value 中使用 `union` 来节省内存
- 字符串必须存放在动态分配的空间中，我们使用 `malloc()` 和 `free()` 来管理内存，同时 `free()` 可以封装成 `lept_free()` 函数
- 我们在解析字符串的时候：
	- 我们可以直接分配某个 `size` 的堆空间，然后在空间不够的时候扩展这个堆，最后将 lept_value 指向这个堆上的数据。 **优点是，可以节省一次从缓存上拷贝数据到 `stack` 的开销，缺点是会浪费一些内存**
	- 也可以和我们的例子中，在 `lept_context` 上分配一个缓存，所有的字符串都在这个缓存上读写，最后将数据从缓存上复制到 `stack` 上

#### 解析 boolean 错误

>这是开始的实现。因为 `v->type` 是一个枚举类型，所以 LEPT_TRUE 和 LEPT_FALSE 都不等于零。
><br/>
>后来我又实现为 `return v->type == LEPT_FALSE`，这会导致 v->type == LEPT_FALSE 时返回 1，从而返回完全相反的结果。

```c
int lept_get_boolean(const lept_value* v) {
    assert(v != NULL);
	// 错误的实现
    return v->type;
}

void lept_set_boolean(lept_value* v, int b) {
    assert(v != NULL);
    v->type = ((b == 0) ? LEPT_FALSE : LEPT_TRUE);
}
```

#### 性能优化的思考

如果整个字符串都没有转义符，我们不就是把字符复制了两次？第一次是从 json 到 stack，第二次是从 stack 到 v->u.s.s。我们可以在 json 扫描 '\0'、'\"' 和 '\\' 3 个字符（ ch < 0x20 还是要检查），直至它们其中一个出现，才开始用现在的解析方法。这样做的话，前半没转义的部分可以只复制一次。缺点是，代码变得复杂一些，我们也不能使用 lept_set_string()。

