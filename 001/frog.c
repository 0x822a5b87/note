#include <assert.h>
#include "stdio.h"
#include "stdlib.h"

size_t *frog_cal_cnt;
size_t *frog2_cal_cnt;
size_t *frog3_cal_cnt;

void init(size_t n)
{
    frog_cal_cnt  = malloc((n + 1) * sizeof(size_t));
    frog2_cal_cnt = malloc((n + 1) * sizeof(size_t));
    frog3_cal_cnt = malloc((n + 1) * sizeof(size_t));
    for (size_t i = 0; i <= n; ++i)
    {
        frog_cal_cnt[i]  = 0;
        frog2_cal_cnt[i] = 0;
        frog3_cal_cnt[i] = 0;
    }
}

void destroy()
{
    free(frog_cal_cnt);
    free(frog2_cal_cnt);
    free(frog3_cal_cnt);
}

void prt_cnt(size_t n)
{

    printf("===================%zu===================\n", n);

    for (size_t i = 0; i < n; ++i)
    {
        printf("i = %zu, f1 = %4zu, f2 = %4zu, f3 = %4zu\n",
               i, frog_cal_cnt[i], frog2_cal_cnt[i], frog3_cal_cnt[i]);
    }

    printf("===================%zu===================\n", n);
}

// 最简单的递归算法，空间复杂度是指数级，并且我们在计算过程中对每一个元素都计算了多次
int frog(size_t n)
{
    ++frog_cal_cnt[n];
    if (n <= 2)
        return n;
    return frog(n - 1) + frog(n - 2);
}

int frog2(size_t n)
{
    ++frog2_cal_cnt[n];
    if (n <= 2)
        return n;

    size_t   memoize[n + 1];
    for (int i = 0; i <= n; ++n)
        memoize[i] = -1;
    memoize[0]     = 0;
    memoize[1]     = 1;
    memoize[2]     = 2;

    return 0;
}

// 自底向上，这样的空间复杂度为 O(n)
int frog3(size_t n)
{
    int memoize[n + 1];
    memoize[0] = 0;
    memoize[1] = 1;
    memoize[2] = 2;

    for (size_t i = 3; i <= n; ++i)
    {
        memoize[i] = memoize[i - 1] + memoize[i - 2];
        ++frog3_cal_cnt[i];
    }

    return memoize[n];
}

int frog4(size_t n)
{
    if (n <= 2)
        return n;
    int prev = 1, prev2 = 2, step = 3;

    for (size_t i = 3; i < n; ++i)
    {
        prev = prev2;
        prev2 = step;
        step = prev + prev2;
    }

    return step;
}

int main(int argc, char **argv)
{
    size_t n = 10;

    for (size_t i = 0; i < n; ++i)
    {
        init(i);
        assert(frog(i) == frog3(i));
        assert(frog(i) == frog4(i));
        prt_cnt(i);
        destroy();
    }
}

