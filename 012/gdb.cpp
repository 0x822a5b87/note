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
