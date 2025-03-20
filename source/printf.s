;==============================================================================
;					My Printf 16.03.2025 @Rogov Anatoliy
;==============================================================================

global main											;make global for linker

extern printf										;link function printf from standard library
extern exit											;link function exit from standard library

section .data										;start of data segment
String 			db "%s %x %d%%%c ", 10, 0
SpecifierS 		db "I love", 0
SpecifierX		dq 3802
SpecifierD		dq 100
SpecifierC		db '!'
Stdout 			equ 0x01							;descriptor of stdout
buffer_size 	equ 128								;size of buffer

section .bss										;start non-prog segment
Buffer 			resb buffer_size					;Init buffer

section .text										;start of code segment
main:												;input pointer
	sub rsp, 8										;alignment in 16 bytes
	mov rdi, String									;format string
	mov rsi, SpecifierS								;first argument
	mov rdx, [SpecifierX]							;second argument
	mov rcx, [SpecifierD]							;third argument
	mov r8, [SpecifierC]							;fourth argument
	call printf										;call standard printf
	add rsp, 8										;return stack pointer to default alignment

	;prolog
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15

	;cdecl
	mov rdi, String									;format string
	push rdi										;first argument
	call my_printf									;function call
	pop rdi											;clear stack

	;epilog
	pop r15
	pop r14
	pop r13
	pop rdx
	pop rcx
	pop rax

	call exit

;==============================================================================
;	Prints string to stdout
;	Entry:		RSI - address of string
;	Exit:		None
;	Destroy:	None
;==============================================================================
my_printf:											;printf(char* string, ...)
	mov rsi, [rsp + 8]								;&string

	mov rdi, Buffer									;copy destination
	copy_to_buffer:									;<------------------------------|
		lodsb										;mov al, ds:[rsi] / inc rsi		|
													;								|
		cmp al, '%'									;if (al == '%') zf = 1			|
		je GetArg									;if (zf == 1) goto GetArg		|
													;								|
		cmp al, 0									;if (al == '$') zf = 1			|
 		je end_printf								;if (zf == 1) goto end_printf---|---|
													;								|	|
		stosb										;mov ds:[rdi], al / inc rdi		|	|
	jmp copy_to_buffer								;-------------------------------|	|
													;									|
	end_printf:										;<----------------------------------|
	call flush_buffer								;flush the buffer
	ret
;==============================================================================

;==============================================================================
;	Flush buffer
;	Entry:		None
;	Exit:		None
;	Destroy:	RSI, RDX, RAX, RDI
;==============================================================================
flush_buffer:
	mov rsi, Buffer									;rsi = &Buffer
	mov rdx, buffer_size							;rdx = buffer len
	mov rax, 0x01									;write
	mov rdi, Stdout									;output descriptor
	syscall											;system instruction
	ret
;==============================================================================

;==============================================================================
;	Get argument for printf
;	Entry:		RSI - current position in printf string
;	Exit:		None
;	Destroy:	RCX, AL
;==============================================================================
GetArg:
	lodsb

	jmp copy_to_buffer
;==============================================================================
