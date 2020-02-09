# [Dynamic_programming](https://en.wikipedia.org/wiki/Dynamic_programming)

1. dynamic programming refers to simplifying a complicated problem by breaking it down into simpler sub-problems in a recursive manner. 
2. If sub-problems can be nested recursively inside larger problems, so that dynamic programming methods are applicable, then there is a relation between the value of the larger problem and the values of the sub-problems.

## Computer programming

There are two key attributes that a problem must have in order for dynamic programming to be applicable: [optimal substructure](https://en.wikipedia.org/wiki/Optimal_substructure) and [overlapping sub-problems](https://en.wikipedia.org/wiki/Overlapping_subproblems). **If a problem can be solved by combining optimal solutions to non-overlapping sub-problems, the strategy is called "[divide and conquer](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm)" instead**. This is why merge sort and quick sort are not classified as dynamic programming problems.

>简单来说，分治法用来解决各个子问题相互独立的问题；动态规划用来解决各个问题重叠

### Optimal_substructure

>optimal substructure == 局部最优解

**Optimal substructure** means that the solution to a given optimization problem can be obtained by the combination of optimal solutions to its sub-problems. Such optimal substructures are usually described by means of recursion. 

For example, given a graph G=(V,E), the shortest path p from a vertex u to a vertex v exhibits optimal substructure: take any intermediate vertex w on this shortest path p. If p is truly the shortest path, then it can be split into sub-paths p1 from u to w and p2 from w to v such that these, in turn, are indeed the shortest paths between the corresponding vertices (by the simple cut-and-paste argument described in Introduction to Algorithms).Hence, one can easily formulate the solution for finding shortest paths in a recursive manner

>In computer science, a problem is said to have optimal substructure if an optimal solution can be constructed from optimal solutions of its subproblems. This property is used to determine the usefulness of dynamic programming and greedy algorithms for a problem.

Typically, a greedy algorithm is used to solve a problem with optimal substructure if it can be proven by induction that this is optimal at each step. Otherwise, provided the problem exhibits overlapping subproblems as well, dynamic programming is used. If there are no appropriate greedy algorithms and the problem fails to exhibit overlapping subproblems, often a lengthy but straightforward search of the solution space is the best alternative.

### Overlapping sub-problems

Overlapping sub-problems means that the space of sub-problems must be small, that is, any recursive algorithm solving the problem should solve the same sub-problems over and over, rather than generating new sub-problems.For example, consider the recursive formulation for generating the Fibonacci series: Fi = Fi−1 + Fi−2, with base case F1 = F2 = 1. Then F43 = F42 + F41, and F42 = F41 + F40. **Now F41 is being solved in the recursive sub-trees of both F43 as well as F42**. Even though the total number of sub-problems is actually small (only 43 of them), we end up solving the same problems over and over if we adopt a naive recursive solution such as this. Dynamic programming takes account of this fact and solves each sub-problem only once.

>看我们标出的部分，这就是我们动态规划中的优化点。F41 在 F43 和 F42 中都被计算了，我们可以在数组或者二维数组中存下来 F41 的值，随后在必要的时候直接查表

This can be achieved in either of two ways:

1. Top-down approach: This is the direct fall-out of the recursive formulation of any problem. If the solution to any problem can be formulated recursively using the solution to its sub-problems, and if its sub-problems are overlapping, then one can easily memoize or store the solutions to the sub-problems in a table. Whenever we attempt to solve a new sub-problem, we first check the table to see if it is already solved. If a solution has been recorded, we can use it directly, otherwise we solve the sub-problem and add its solution to the table

2. Bottom-up approach: Once we formulate the solution to a problem recursively as in terms of its sub-problems, we can try reformulating the problem in a bottom-up fashion: **try solving the sub-problems first and use their solutions to build-on and arrive at solutions to bigger sub-problems.** This is also usually done in a tabular form by iteratively generating solutions to bigger and bigger sub-problems by using the solutions to small sub-problems. For example, if we already know the values of F41 and F40, we can directly calculate the value of F42.

## Examples: Computer algorithms

```c
   function fib(n)
       if n <= 1 return n
       return fib(n − 1) + fib(n − 2)
```

### Top-down approach

```c
   var m := map(0 -> 0, 1 -> 1)
   function fib(n)
       if key n is not in map m 
           m[n] := fib(n − 1) + fib(n − 2)
       return m[n]
```

### Bottom-up approach

```c
   function fib(n)
       if n = 0
           return 0
       else
           var previousFib := 0, currentFib := 1
           repeat n − 1 times // loop is skipped if n = 1
               var newFib := previousFib + currentFib
               previousFib := currentFib
               currentFib  := newFib
       return currentFib
```

### A type of balanced 0-1 matrix

>Consider the problem of assigning values, either zero or one, to the positions of an n × n matrix, with n even, so that each row and each column contains exactly n / 2 zeros and n / 2 ones. We ask how many different assignments there are for a given {\displaystyle n}n. For example, when n = 4, four possible solutions are

[0 1 0 1]       [0 0 1 1]		[1 1 0 0]		[1 0 0 1]
[1 0 1 0]		[0 0 1 1]		[0 0 1 1]		[0 1 1 0]
[0 1 0 1]		[1 1 0 0]		[1 1 0 0]		[0 1 1 0]
[1 0 1 0]		[1 1 0 0]		[0 0 1 1]		[1 0 0 1]

There are at least three possible approaches: brute force, [backtracking](https://en.wikipedia.org/wiki/Backtracking), and dynamic programming.

Backtracking for this problem consists of choosing some order of the matrix elements and recursively placing ones or zeros, while checking that in every row and column the number of elements that have not been assigned plus the number of ones or zeros are both at least n / 2. While more sophisticated than brute force, this approach will visit every solution once, making it impractical for n larger than six, since the number of solutions is already 116,963,796,250 for n = 8, as we shall see.


