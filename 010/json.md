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
