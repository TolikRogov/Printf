;==============================================================================
;					My Scanf 22.05.2025 @Rogov Anatoliy
;==============================================================================

global my_scanf										;make global for linker

section .data										;start of data segment
	Stdin 			equ 0x00						;descriptor of stdin
	buffer_size 	equ 128							;size of buffer

section .rodata
jump_table 	dq 	_b_
			dq	_c_
			dq 	_d_
			times 'o' - 'd' - 1 dq _default_
			dq 	_o_
			times 's' - 'o' - 1 dq _default_
			dq	_s_
			times 'x' - 's' - 1 dq _default_
			dq	_x_

section .bss										;start non-prog segment
Buffer 			resb buffer_size					;Init buffer

section .text										;start of code segment

;==============================================================================
;	Scnafs string to stdin
;	Entry:		RDI - address of string
;				... - other arguments
;	Exit:		None
;	Destroy:	None
;==============================================================================
my_scanf:											;scanf(char* string, int* digit)
	pop r10											;returning address
	push r9											;6th argument
	push r8											;5th argument
	push rcx										;4th argument
	push rdx										;3th argument
	push rsi										;2th argument
	push rdi										;1th argument
	mov r11, rsp									;start of parameters in stack

	push rbp
	push rbx
	push r12
	push r13										;saved registers
	push r14
	push r15

	mov rsi, [r11]									;first format string
	add r11, 8										;next argument

	mov rdi, Buffer									;copy destination
	copy_to_buffer:									;<------------------------------|
		lodsb										;mov al, ds:[rsi] / inc rsi		|
													;								|
		cmp al, '%'									;if (al == '%') zf = 1			|
		je GetArg									;if (zf == 1) goto GetArg		|
													;								|
		cmp al, 0									;if (al == 0) zf = 1			|
 		je end_printf								;if (zf == 1) goto end_printf---|---|
													;								|	|
	jmp copy_to_buffer								;-------------------------------|	|
													;									|
	end_printf:										;<----------------------------------|

	pop rax
	pop r15
	pop r14
	pop r13
	pop r12											;return saved registers
	pop rbx
	pop rbp

	add rsp, 56										;return rsp above the 6th arguments

	push rax
	push r10										;put return address
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
	jmp _default_									;goto _default_						|
													;									|
	skip_percent:									;<----------------------------------|
	sub al, 'b'										;al -= 'b'
	cmp al, 'x' - 'b'								;if (al == 'x' - 'b') zf = 1
	ja _default_									;if (>) goto _default_
	and rax, 0xFF									;rax &= 0xFF
	shl rax, 3										;rax *= 8
	add rax, jump_table								;rax += &jump_table

	push rsi										;save rsi
	mov rsi, [r11]									;rsi = new arg
	add r11, 8

	jmp [rax]										;goto jump_table + al * 8
;==============================================================================

;==============================================================================
;	Handler of parameters
;	Entry:		None
;	Exit:		None
;	Destroy:	None
;==============================================================================
_s_:
	pop rsi											;return rsi to format string
	jmp _default_									;goto _default_

_c_:
	mov rax, rsi									;rax = rsi | put symbol to rax
	pop rsi											;return rsi to format string
	jmp _default_									;goto _default_

_b_:
	mov rcx, 1										;amount of bytes per one symbol
	mov rbx, 0x01									;mask for binary
	pop rsi											;return current format string ip
	jmp _default_									;goto _default_

_o_:
	mov rcx, 3										;amount of bytes per one symbol
	mov rbx, 0x07									;mask for oct
	pop rsi											;return current format string ip
	jmp _default_									;goto _default_

_x_:
	mov rcx, 4										;amount of bytes per one symbol
	mov rbx, 0x0F									;mask for hex
	pop rsi											;return current format string ip
	jmp _default_									;goto _default_

_default_:
	jmp copy_to_buffer								;goto copy_to_buffer
;==============================================================================

;==============================================================================
;	Handler %d parameter
;	Entry:		RSI - number to transform
;	Exit:		None
;	Destroy:	None
;==============================================================================
_d_:
	push rsi
	push rdi										;save before read
	push rdx

	mov rax, 0          							; sys_read
    mov rdi, Stdin      							; stdin
    mov rsi, Buffer     							; &buffer
    mov rdx, buffer_size    						; max length
    syscall

	pop rdx
	pop rdi											;return
	pop rsi

	mov rdi, rsi									;rdi = destination
	mov rsi, Buffer									;rsi = &Buffer
	xor eax, eax									;rax = 0
	lodsb											;mov al, [rsi] / inc rsi

	push r13
	push rbx										;save
	push rdx

	xor ebx, ebx									;rbx = 0
	xor r13, r13									;r13 = 0
	xor edx, edx									;rdx = 0

	cmp al, '-'										;if (al == '-') zf = 1
	je signed										;if (zf == 1) goto signed

	dec rsi											;rsi -= 1
	jmp unsigned									;goto unsigned

	signed:											;
	mov r13, 1										;r13 = 1

	unsigned:										;
	xor eax, eax									;rax = 0
	mov bl, [rsi]									;bl = *rsi
	inc rsi											;rsi++

	over_div:										;<------------------------------|
		mov rdx, rax								;rdx = rax						|
		shl rax, 3									;rax *= 8						|
		add rax, rdx								;rax += rdx						|
		add rax, rdx								;rax += rdx						|
		sub bl, '0'									;bl -= 30						|
		add rax, rbx								;rax += rbx						|
		mov bl, [rsi]								;bl = *rsi						|
		inc rsi										;rsi++							|
		cmp bl, 10									;if (bl == '\n') zf = 1			|
	jne over_div									;if (zf != 1) goto over_div ----|

	cmp r13, 1										;if (r13 == 1) zf = 1
	jne no_negative									;if (zf != 1) goto no_negative--|
		neg eax										;rax *= -1						|
	no_negative:									;<------------------------------|

	mov [rdi], rax									;destination = rax

	pop rdx
	pop rbx											;return
	pop r13											;return
	pop rsi											;return current format string ip
	push rax
	jmp _default_									;goto _default_
;==============================================================================
