#include <assert.h>
#include "stdio.h"

int uniquePaths(int m, int n)
{
    if (m <= 0 || n <= 0)
        return 0;
    if (m == 1 || n == 1)
        return 1;

    int dp[n][m];
    for (int i = 0; i < m; ++i)
    {
        dp[0][i] = 1;
    }
    for (int j = 0; j < n; ++j)
    {
        dp[j][0] = 1;
    }

    for (int i = 1; i < n; ++i)
    {
        for (int j = 1; j < m; ++j)
        {
            dp[i][j] = dp[i - 1][j] + dp[i][j - 1];
        }
    }

    return dp[n - 1][m - 1];
}

int uniquePathsOptimized(int m, int n)
{
    if (m <= 0 || n <= 0)
        return 0;

    int dp[n];
    for (int i = 0; i < n; ++i)
        dp[i] = 1;

    for (int i = 1; i < m; ++i)
    {
        for (int j = 1; j < n; ++j)
        {
            dp[j] += dp[j-1];
        }
    }

    return dp[n-1];
}

int main(int argc, char **argv)
{
    assert(uniquePaths(0, 0) == 0);
    assert(uniquePaths(1, 1) == 1);
    assert(uniquePaths(1, 2) == 1);
    assert(uniquePaths(2, 2) == 2);
    assert(uniquePaths(3, 2) == 3);

    assert(uniquePathsOptimized(3, 2) == 3);
    assert(uniquePathsOptimized(10, 10) == uniquePaths(10, 10));
}