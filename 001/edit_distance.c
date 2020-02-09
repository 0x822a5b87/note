#include <assert.h>
#include "stdio.h"
#include "string.h"

int min(int x, int y)
{
    return x < y ? x : y;
}

int min2(int x, int y, int z)
{
    return min(min(x, y), z);
}

int minDistance(char *word1, char *word2)
{
    if (word1 == NULL || word2 == NULL)
    {
        return 0;
    }
    size_t len1 = strlen(word1), len2 = strlen(word2);
    int    dp[len1 + 1][len2 + 1];

    for (size_t i = 0; i <= len1; ++i)
    {
        for (size_t j = 0; j <= len2; ++j)
        {
            if (i == 0)
            {
                dp[i][j] = j;
            }
            else if (j == 0)
            {
                dp[i][j] = i;
            }
            else
            {
                if (word1[i-1] == word2[j-1])
                {
                    dp[i][j] = dp[i - 1][j - 1];
                }
                else
                {
                    dp[i][j] = 1 + min2(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
                }
            }
        }
    }

    return dp[len1][len2];
}

int main(int argc, char **argv)
{
    char *word1 = "horse";
    char *word2 = "ros";

    assert(minDistance(word1, word2) == 3);
    assert(minDistance(word1, word1) == 0);
    assert(minDistance(word2, word2) == 0);

    word1 = "intention";
    word2 = "execution";
    assert(minDistance(word1, word2) == 5);
}