;==============================================================================
;					My Printf 16.03.2025 @Rogov Anatoliy
;==============================================================================

global main											;make global for linker

extern printf										;link function printf from standard library
extern exit											;link function exit from standard library

section .data										;start of data segment
String 			db "My string: %s %x %d%%%c", 10, 0
SpecifierS 		db "I love", 0
SpecifierX		dq 3802
SpecifierD		dq 100
SpecifierC		db '!'
Stdout 			equ 0x01							;descriptor of stdout
buffer_size 	equ 128								;size of buffer

section .rodata
jump_table 	dq 	_b_
			dq	_c_
			dq 	_d_
			times 's' - 'd' dq _default_
			dq	_s_
			times 'x' - 's' dq _default_
			dq	_x_

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
	mov rbp, rsp
	push SpecifierS									;second argument
	push String										;first argument
	call my_printf									;function call
	mov rsp, rbp

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
;				... - other arguments
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
		call check_buffer							;flush buffer before put symbol?|	|
	jmp copy_to_buffer								;-------------------------------|	|
													;									|
	end_printf:										;<----------------------------------|
	call flush_buffer								;flush the buffer
	ret
;==============================================================================

;==============================================================================
;	Check buffer on overflow
;	Entry:		RDI - current ip in buffer
;	Exit:		None
;	Destroy:	RDI
;==============================================================================
check_buffer:
	push rbx										;save rbx
	xor rbx, rbx									;rbx = 0
	add rbx, rdi									;rbx += rdi
	sub rbx, Buffer									;rbx - Buffer

	cmp rbx, buffer_size							;if (rbx == buffer_size) zf = 1
	jne skip_flush									;if (zf != 1) goto skip_flush---|
		call flush_buffer							;call buffer flush				|
		mov rdi, Buffer								;set rdi on buffer start		|
													;								|
	skip_flush:										;<------------------------------|
	stosb											;mov ds:[rdi], al / inc rdi
	pop rbx											;return rbx
	ret
;==============================================================================

;==============================================================================
;	Flush buffer
;	Entry:		None
;	Exit:		None
;	Destroy:	RSI, RDX, RAX, RDI
;==============================================================================
flush_buffer:
	push rsi										;save rsi
	mov rsi, Buffer									;rsi = &Buffer
	mov rdx, buffer_size							;rdx = buffer len
	mov rax, 0x01									;write
	mov rdi, Stdout									;output descriptor
	syscall				 							;system instruction

	mov rcx, buffer_size							;rcx = size of buffer
	mov rdi, Buffer									;rdi = buffer start
	xor rax, rax									;rax = 0
	rep stosb										;while (rcx--) stosb
	pop rsi											;return rsi
	ret
;==============================================================================

;==============================================================================
;	Get argument for printf
;	Entry:		RSI - current position in printf string
;	Exit:		None
;	Destroy:	RCX, AL
;==============================================================================
GetArg:
	lodsb											;mov al, ds:[rsi] / inc rsi

	cmp al, '%'										;if (al == '%') zf = 1
	jne skip_percent								;if (zf != 1) goto skip_percent	----|
	call check_buffer								;call buffer checking				|
	jmp _default_									;goto _default_						|
													;									|
	skip_percent:									;<----------------------------------|
	sub al, 'b'										;al -= 'b'
	cmp al, 'x' - 'b'								;if (al == 'x' - 'b') zf = 1
	ja _default_									;if (>) goto _default_
	and rax, 0xFF									;rax &= 0xFF
	shl rax, 3										;rax *= 8
	add rax, jump_table								;rax += &jump_table
	jmp [rax]										;goto jump_table + al * 8

	_b_:
		jmp _default_

	_c_:
		jmp _default_

	_d_:
		jmp _default_

	_s_:
		jmp _default_

	_x_:
		jmp _default_

	_default_:
		jmp copy_to_buffer
;==============================================================================
