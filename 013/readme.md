# backtracking

## introduction

[backtracking introduction](https://www.geeksforgeeks.org/backtracking-introduction/)

[Backtracking WIKIPEDIA](https://en.wikipedia.org/wiki/Backtracking)

## WIKIPEDIA

### introduction

Backtracking is a general algorithm for finding all (or some) solutions to some computational problems, notably constraint satisfaction problems, that incrementally builds candidates to the solutions, and abandons a candidate ("backtracks") as soon as it determines that the candidate cannot possibly be completed to a valid solution

The classic textbook example of the use of backtracking is the eight queens puzzle, that asks for all arrangements of eight chess queens on a standard chessboard so that no queen attacks any other. In the common backtracking approach, the partial candidates are arrangements of k queens in the first k rows of the board, all in different rows and columns. Any partial solution that contains two mutually attacking queens can be abandoned.

**Backtracking can be applied only for problems which admit the concept of a "partial candidate solution" and a relatively quick test of whether it can possibly be completed to a valid solution.**

### Description of the method

The backtracking algorithm enumerates a set of partial candidates that, in principle, could be completed in various ways to give all the possible solutions to the given problem. The completion is done incrementally, by a sequence of candidate extension steps.

Conceptually, **the partial candidates are represented as the nodes of a tree structure**, the potential search tree. **Each partial candidate is the parent of the candidates that differ from it by a single extension step;** the leaves of the tree are the partial candidates that cannot be extended any further.

**The backtracking algorithm traverses this search tree recursively, from the root down, in depth-first order.** At each node c, **the algorithm checks whether c can be completed to a valid solution. If it cannot, the whole sub-tree rooted at c is skipped (pruned)**. Otherwise, the algorithm (1) checks whether c itself is a valid solution, and if so reports it to the user; and (2) recursively enumerates all sub-trees of c. The two tests and the children of each node are defined by user-given procedures.

### Pseudocode

1. root(P): return the partial candidate at the root of the search tree.
2. reject(P,c): return true only if the partial candidate c is not worth completing.
3. accept(P,c): return true if c is a solution of P, and false otherwise.
4. first(P,c): generate the first extension of candidate c.
5. next(P,s): generate the next alternative extension of a candidate, after the extension s.
6. output(P,c): use the solution c of P, as appropriate to the application.

The backtracking algorithm reduces the problem to the call bt(root(P)), where bt is the following recursive procedure:

```
procedure bt(c) is
    if reject(P, c) then return
    if accept(P, c) then output(P, c)
    s ← first(P, c)
    while s ≠ NULL do
        bt(s)
        s ← next(P, s)
```

## GeeksForGeeks

[Backtracking | Introduction](https://www.geeksforgeeks.org/backtracking-introduction/)

Backtracking is an algorithmic-technique for solving problems **recursively by trying to build a solution incrementally**, one piece at a time, removing those solutions that fail to satisfy the constraints of the problem at any point of time

Backtracking can be defined as a general algorithmic technique that considers **searching every possible combination** in order to solve a computational problem.

>How to determine if a problem can be solved using Backtracking?

Generally, every constraint satisfaction problem which has clear and well-defined constraints on any objective solution, that incrementally builds candidate to the solution and abandons a candidate (“backtracks”) as soon as it determines that the candidate cannot possibly be completed to a valid solution, can be solved by Backtracking. 

### The Knight’s tour problem | Backtracking-1

>The knight is placed on the first block of an empty board and, moving according to the rules of chess, must visit each square exactly once.

Following is the Backtracking algorithm for Knight’s tour problem.

```
If all squares are visited 
    print the solution
Else
   a) Add one of the next moves to solution vector and recursively 
   check if this move leads to a solution. (A Knight can make maximum 
   eight moves. We choose one of the 8 moves in this step).
   b) If the move chosen in the above step doesn't lead to a solution
   then remove this move from the solution vector and try other 
   alternative moves.
   c) If none of the alternatives work then return false (Returning false 
   will remove the previously added item in recursion and if false is 
   returned by the initial call of recursion then "no solution exists" )
```

```cpp
//
// Created by 0x822a5b87 on 2020/9/8.
//

#include <iomanip>
#include "iostream"

using namespace std;

#define N 8

int solveKTUtil(int x, int y, int movei,
				int sol[N][N], int xMove[],
				int yMove[]);

/* A utility function to check if i,j are
valid indexes for N*N chessboard */
int isSafe(int x, int y, int sol[N][N])
{
	return (x >= 0 && x < N && y >= 0 &&
			y < N && sol[x][y] == -1);
}

/* A utility function to print
solution matrix sol[N][N] */
void printSolution(int sol[N][N])
{
	for (int x = 0; x < N; x++)
	{
		for (int y = 0; y < N; y++)
			cout << " " << setw(2)
				 << sol[x][y] << " ";
		cout << endl;
	}
}

/* This function solves the Knight Tour problem using
Backtracking. This function mainly uses solveKTUtil()
to solve the problem. It returns false if no complete
tour is possible, otherwise return true and prints the
tour.
Please note that there may be more than one solutions,
this function prints one of the feasible solutions. */
int solveKT()
{
	int sol[N][N];

	/* Initialization of solution matrix */
	for (int x = 0; x < N; x++)
		for (int y = 0; y < N; y++)
			sol[x][y] = -1;

	/* xMove[] and yMove[] define next move of Knight.
	xMove[] is for next value of x coordinate
	yMove[] is for next value of y coordinate */
	int xMove[8] = {2, 1, -1, -2, -2, -1, 1, 2};
	int yMove[8] = {1, 2, 2, 1, -1, -2, -2, -1};

	// Since the Knight is initially at the first block
	sol[0][0] = 0;

	/* Start from 0,0 and explore all tours using
	solveKTUtil() */
	if (solveKTUtil(0, 0, 1, sol, xMove, yMove) == 0)
	{
		cout << "Solution does not exist";
		return 0;
	}
	else
		printSolution(sol);

	return 1;
}

/* A recursive utility function to solve Knight Tour
problem */
int solveKTUtil(int x, int y, int movei,
				int sol[N][N], int xMove[N],
				int yMove[N])
{
	if (movei == N * N)
		return 1;

	/* Try all next moves from
	the current coordinate x, y */
	for (int k = 0; k < 8; k++)
	{
		int next_x = x + xMove[k];
		int next_y = y + yMove[k];
		if (isSafe(next_x, next_y, sol))
		{
			sol[next_x][next_y]     = movei;
			if (solveKTUtil(next_x, next_y,
							movei + 1, sol,
							xMove, yMove) == 1)
				return 1;
			else
				// backtracking
				sol[next_x][next_y] = -1;
		}
	}
	return 0;
}

// Driver Code
int main()
{
	solveKT();
	return 0;
}

// This code is contributed by ShubhamCoder
```

### Rat in a Maze

A Maze is given as N*N binary matrix of blocks where source block is the upper left most block i.e., maze[0][0] and destination block is lower rightmost block i.e., maze[N-1][N-1]. A rat starts from source and has to reach the destination. The rat can move only in two directions: forward and down.
In the maze matrix, 0 means the block is a dead end and 1 means the block can be used in the path from source to destination. Note that this is a simple version of the typical Maze problem. For example, a more complex version can be that the rat can move in 4 directions and a more complex version can be with a limited number of moves.

```cpp
//
// Created by 0x822a5b87 on 2020/9/8.
//

#include <iomanip>
#include "iostream"
#include "vector"

using namespace std;

class Solution
{
public:
	explicit Solution(const vector<vector<int>> &maze) : maze(maze)
	{
	}

	void solve()
	{
		if (solve(0, 0, 1))
		{
			print();
		}
		else
		{
			std::cout << "no valid path!" << std::endl;
		}
	}

	size_t mazeSize()
	{
		return maze.size();
	}

	bool solve(int x, int y, int nthMove)
	{
		if (x == mazeSize() - 1 && y == mazeSize() - 1)
		{
			return true;
		}
		for (const auto &m : move)
		{
			int nextX = x + m[0];
			int nextY = y + m[1];
			// 注意，这里一定要先判断下一个点是否正常才进入判断，否则回溯的时候会修改越界的数组
			if (isSafe(nextX, nextY))
			{
				maze[nextX][nextY] = nthMove;
				++nthMove;
				if (solve(nextX, nextY, nthMove))
				{
					return true;
				}
				else
				{
					--nthMove;
					maze[x][y] = 0;
				}
			}
		}

		return false;
	}

private:

	void print()
	{
		for (auto &i : maze)
		{
			for (int j : i)
			{
				std::cout << setw(2) << j << " ";
			}
			std::cout << std::endl;
		}
	}

	bool isSafe(size_t x, size_t y)
	{
		return x >= 0 && y >= 0 && x < mazeSize() && y < mazeSize() && maze[x][y] == 0;
	}

	vector<vector<int>>       maze;
	const vector<vector<int>> move = {{0, 1},
									  {1, 0}};
};

int main(int argc, char **argv)
{
	vector<vector<int>> maze{
			{0, 10, 0, 0},
			{0, 10, 0, 0},
			{0, 0, 10, 0},
			{0, 0, 0, 0},
	};

	Solution solution(maze);
	for (auto &m : maze)
	{
		m.resize(solution.mazeSize());
	}
	solution.solve();
}
```

### N Queen Problem

The N Queen is the problem of placing N chess queens on an N×N chessboard so that no two queens attack each other. For example, following is a solution for 4 Queen problem.

**The idea is to place queens one by one in different columns, starting from the leftmost column.**When we place a queen in a column, we check for clashes with already placed queens. In the current column, if we find a row for which there is no clash, we mark this row and column as part of the solution. If we do not find such a row due to clashes then we backtrack and return false.

```cpp
class Solution {
public:
    vector<vector<string>> solveNQueens(int n) {
        auto solutions = vector<vector<string>>();
        auto queens = vector<int>(n, -1);
        solve(solutions, queens, n, 0, 0, 0, 0);
        return solutions;
    }

    void solve(vector<vector<string>> &solutions, vector<int> &queens, int n, int row, int columns, int diagonals1, int diagonals2) {
        if (row == n) {
            auto board = generateBoard(queens, n);
            solutions.push_back(board);
        } else {
            int availablePositions = ((1 << n) - 1) & (~(columns | diagonals1 | diagonals2));
            while (availablePositions != 0) {
                int position = availablePositions & (-availablePositions);
                availablePositions = availablePositions & (availablePositions - 1);
                int column = __builtin_ctz(position);
                queens[row] = column;
                solve(solutions, queens, n, row + 1, columns | position, (diagonals1 | position) >> 1, (diagonals2 | position) << 1);
                queens[row] = -1;
            }
        }
    }

    vector<string> generateBoard(vector<int> &queens, int n) {
        auto board = vector<string>();
        for (int i = 0; i < n; i++) {
            string row = string(n, '.');
            row[queens[i]] = 'Q';
            board.push_back(row);
        }
        return board;
    }
};
```
