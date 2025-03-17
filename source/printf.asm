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
	mov rsi, [rsp + 8]								;rsi = &string
	call strlen										;calc string length
	mov rdx, rcx									;rdx = str_len
	mov rax, 0x01									;write
	mov rdi, Stdout									;output descriptor
	syscall											;system instruction
	ret
;==============================================================================

;==============================================================================
;	Calculate string length
;	Entry:		RSI - address of string
;	Exit:		RCX - string length
;	Destroy:	RCX, AL
;==============================================================================
strlen:
	push rsi
	xor rcx, rcx
	count:
		lodsb
		cmp al, '$'
		je end_count
		add rcx, 2
	loop count
	end_count:
	pop rsi
	ret
;==============================================================================
