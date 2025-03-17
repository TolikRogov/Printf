;==============================================================================
;					My Printf 16.03.2025 @Rogov Anatoliy
;==============================================================================

section .data										;start of data segment
String: 		db 'Hello, World!', 0x0a, '$'		;String for printf
Stdout: 		equ 0x01							;descriptor of stdout
buffer_size: 	equ 128								;size of buffer

section .bss										;start non-prog segment
Buffer: 		resb buffer_size					;Init buffer

section .text										;start of code segment
	global _start									;make global for linker

_start:												;input pointer

	;prolog
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15

	;cdecl
	mov rsi, String									;rsi = $String
	push rsi										;first argument
	call printf										;function call
	pop rsi											;clear stack

	;epilog
	pop r15
	pop r14
	pop r13
	pop rdx
	pop rcx
	pop rax

	mov rax, 60										;rax = exit(rdi)
	xor rdi, rdi									;rdi = 0 | exit code
	syscall											;system instruction

;==============================================================================
;	Prints string to stdout
;	Entry:		RSI - address of string
;	Exit:		None
;	Destroy:	None
;==============================================================================
printf:												;printf(char* string, ...)
	mov rsi, [rsp + 8]								;&string

	mov rdi, Buffer									;copy destination
	xor rcx, rcx									;loop counter
	copy_to_buffer:									;<------------------------------|
		lodsb										;mov al, ds:[rsi] / inc rsi		|
		cmp al, '$'									;if (al == '$') zf = 1			|
 		je end_printf								;if (zf == 1) goto end_printf---|---|
		stosb										;mov ds:[rdi], al / inc rdi		|	|
		add rcx, 2									;rcx += 2						|	|
	loop copy_to_buffer								;-------------------------------|	|
													;									|
	end_printf:										;<----------------------------------|
	call flush_buffer								;flush the buffer
	ret
;==============================================================================

;==============================================================================
;	Calculate string length
;	Entry:		RSI - address of string
;	Exit:		RCX - string length
;	Destroy:	RCX, AL
;==============================================================================
strlen:												;strlen(rsi)
	push rsi										;save rsi
	xor rcx, rcx									;rcx = 0
	count:											;<----------------------------------|
		lodsb										;mov al, ds:[rsi] / inc rsi			|
		cmp al, '$'									;if (al == '$') zf = 1				|
		je end_count								;if (zf == 1) goto end_count----|	|
		add rcx, 2									;rcx += 2						|	|
	loop count										;-------------------------------|---|
	end_count:										;<------------------------------|
	pop rsi											;back rsi | string start
	ret
;==============================================================================

;==============================================================================
;	Flush buffer
;	Entry:		None
;	Exit:		None
;	Destroy:	RCX, AL
;==============================================================================
flush_buffer:
	mov rsi, Buffer									;rsi = &Buffer
	mov rdx, buffer_size							;rdx = buffer len
	mov rax, 0x01									;write
	mov rdi, Stdout									;output descriptor
	syscall											;system instruction
	ret
;==============================================================================
