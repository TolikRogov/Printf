default: debug

release:
	@cmake -S ./ -B build/Release -DCMAKE_BUILD_TYPE=Release
	@cmake --build build/Release
	@./build/Release/Printf

debug:
	@cmake -S ./ -B build/Debug -DCMAKE_BUILD_TYPE=Debug
	@cmake --build build/Debug
	@./build/Debug/Printf

ld:
	@nasm -f elf64 source/printf.s -o build/printf.o -l build/printf.lst
	@ld build/printf.o -static -lc -o build/printf
	@./build/printf

gcc:
	@nasm -f elf64 source/printf.s -o build/printf.o -l build/printf.lst
	@gcc build/printf.o -static -o build/printf -z noexecstack
	@./build/printf
