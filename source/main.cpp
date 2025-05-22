#include <stdio.h>

extern "C" void my_printf(const char*, ...);

extern "C" int main() {

	my_printf("My string: %s %x %d%%%c %d\n", "I love", 3802, 100, '!', -52);
	printf("My string: %s %x %d%%%c %d\n", "I love", 3802, 100, '!', -52);

	return 0;
}
