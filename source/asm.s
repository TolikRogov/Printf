;==============================================================================
;					My Printf & Scanf 16.03.2025 @Rogov Anatoliy
;==============================================================================

global main											;make global for linker

extern printf										;link function printf from standard library
extern scanf
extern exit
extern my_printf
extern my_scanf

section .data										;start of data segment
String 			db "Your number: %d", 10, 0
ScanfString		db "%d", 0
SpecifierS 		db "I love", 0
Number 			dd 0
MyNumber		dd 0

section .text										;start of code segment
main:												;input pointer
	sub rsp, 8										;alignment in 16 bytes
	mov rdi, ScanfString							;format string
	mov rsi, Number
	call scanf										;call standard printf
	add rsp, 8										;return stack pointer to default alignment

	mov rbp, rsp									;save rsp
	mov rdi, ScanfString							;format string
	mov rsi, MyNumber								;first argument
	call my_scanf									;function call
	mov rsp, rbp									;return rsp to flush parameters in stack

	sub rsp, 8										;alignment in 16 bytes
	mov rdi, String									;format string
	mov rsi, [Number]								;first argument
	call printf										;call standard printf
	add rsp, 8										;return stack pointer to default alignment

	mov rbp, rsp									;save rsp
	mov rdi, String									;format string
	mov rsi, [MyNumber]								;first argument
	call my_printf									;function call
	mov rsp, rbp									;return rsp to flush parameters in stack

	call exit
