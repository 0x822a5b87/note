#include "stdio.h"
#include "stdlib.h"

#define min(a, b) (((a) < (b)) ? (a) : (b))

int minPathSum(int **grid, int gridSize, int *gridColSize)
{
    int rows = *gridColSize, cols = gridSize;

    int dp[cols][rows];

    dp[0][0] = **grid;
    for (int col = 1; col < rows; ++col)
    {
        dp[0][col] = grid[0][col] + dp[0][col - 1];
    }
    for (int row = 1; row < cols; ++row)
    {
        dp[row][0] = grid[row][0] + dp[row - 1][0];
    }


    for (int col = 1; col < cols; ++col)
    {
        for (int row = 1; row < rows; ++row)
        {
            int up = dp[col - 1][row];
            int left   = dp[col][row - 1];
            dp[col][row] = min(up, left) + grid[col][row];
        }
    }

    return dp[cols - 1][rows - 1];
}

int minPathSum1(int **grid, int gridSize, int *gridColSize)
{
    int cols = *gridColSize, rows = gridSize;

    int dp[cols][rows];

    int *start = *grid;

    dp[0][0] = *start;
    for (int col = 1; col < rows; ++col)
    {
        dp[0][col] = start[col] + dp[0][col - 1];
    }
    for (int row = 1; row < cols; ++row)
    {
        dp[row][0] = start[row * cols] + dp[row - 1][0];
    }


    for (int col = 1; col < cols; ++col)
    {
        for (int row = 1; row < rows; ++row)
        {
            int up = dp[col - 1][row];
            int left   = dp[col][row - 1];
            dp[col][row] = min(up, left) + start[col * cols + row];
        }
    }

    return dp[cols - 1][rows - 1];
}


int main(int argc, char **argv)
{
    int rows = 3, columns = 3;

    int numbers[9];
    numbers[0] = 1;
    numbers[1] = 3;
    numbers[2] = 1;
    numbers[3] = 1;
    numbers[4] = 5;
    numbers[5] = 1;
    numbers[6] = 4;
    numbers[7] = 2;
    numbers[8] = 1;

    int *p = numbers;
    int **pp = &p;
    printf("%d\n", minPathSum1(&p, rows, &columns));
}