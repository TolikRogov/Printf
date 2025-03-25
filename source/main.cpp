#include <stdio.h>

extern "C" void my_printf(const char*, ...);

extern "C" int main() {

	my_printf("Fuck you%c\n", '!');
	my_printf("Fuck you %s\n", "SOSI");
	my_printf("Fuck you gsdh asgh kash jkashdflsjhd flashdf hsadf ashdf asgh2uog abzxccbv zxcb uwa ughwa G ASD AWD GA ff gae gaeaer gawer gaer gjdfhgkdfhg %d\n", -52);
	my_printf("Fuck you %x\n", 3802);
	my_printf("Fuck you %b\n", -52);
	printf("AAAAAAAAAAAAAAAAAa\n");

	return 0;
}
