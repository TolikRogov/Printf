;==============================================================================
;					My Printf 16.03.2025 @Rogov Anatoliy
;==============================================================================

global my_printf									;make global for linker

extern printf										;link function printf from standard library
extern exit											;link function exit from standard library

section .data										;start of data segment
String 			db "My string: %s %x %d%%%c %b", 10, 0
SpecifierS 		db "I love", 0
SpecifierX		dq 3802
SpecifierD		dd 100
SpecifierC		db '!'
SuperSpecifier	dd -52
Stdout 			equ 0x01							;descriptor of stdout
buffer_size 	equ 128								;size of buffer
trans_buff_size	equ 64								;size of translator buffer

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
symbols_array db '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'

section .bss										;start non-prog segment
Buffer 			resb buffer_size					;Init buffer
trans_buffer 	resb trans_buff_size				;Init trans buffer

section .text										;start of code segment
; main:												;input pointer
; 	sub rsp, 8										;alignment in 16 bytes
; 	mov rdi, String									;format string
; 	mov rsi, SpecifierS								;first argument
; 	mov rdx, [SpecifierX]							;second argument
; 	mov rcx, [SpecifierD]							;third argument
; 	mov r8, [SpecifierC]							;fourth argument
; 	mov r9, [SuperSpecifier]						;fifth argument
; 	call printf										;call standard printf
; 	add rsp, 8										;return stack pointer to default alignment
;
; 	mov rbp, rsp									;save rsp
; 	mov rdi, String									;format string
; 	mov rsi, SpecifierS								;first argument
; 	mov rdx, [SpecifierX]							;second argument
; 	mov ecx, [SpecifierD]							;third argument
; 	mov r8, [SpecifierC]							;fourth argument
; 	mov r9, [SuperSpecifier]						;fifth argument
; 	call my_printf									;function call
; 	mov rsp, rbp									;return rsp to flush parameters in stack
;
; 	call exit

;==============================================================================
;	Prints string to stdout
;	Entry:		RSI - address of string
;				... - other arguments
;	Exit:		None
;	Destroy:	None
;==============================================================================
my_printf:											;printf(char* string, ...)
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
		call check_buffer							;flush buffer before put symbol?|	|
	jmp copy_to_buffer								;-------------------------------|	|
													;									|
	end_printf:										;<----------------------------------|
	call flush_buffer								;flush the buffer

	pop r15
	pop r14
	pop r13
	pop r12											;return saved registers
	pop rbx
	pop rbp

	add rsp, 48										;return rsp above the 6th arguments

	push r10										;put return address
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
	sub rbx, Buffer									;rbx -= Buffer

	cmp rbx, buffer_size							;if (rbx == buffer_size) zf = 1
	jb skip_flush									;if (zf < 0) goto skip_flush ---|
		call flush_buffer							;call buffer flush				|
		mov rdi, Buffer								;set rdi on buffer start		|
													;								|
	skip_flush:										;<------------------------------|
	stosb											;mov [rdi], al / inc rdi
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
	push rdx										;save rdx
	push rax										;save rax
	push rcx										;save rcx
	push r11										;save r11 which is changed by syscall
	mov rsi, Buffer									;rsi = &Buffer
	mov rdx, buffer_size							;rdx = buffer len
	mov rax, 0x01									;write
	mov rdi, Stdout									;output descriptor
	syscall				 							;system instruction

	mov rcx, buffer_size							;rcx = size of buffer
	mov rdi, Buffer									;rdi = buffer start
	xor rax, rax									;rax = 0
	rep stosb										;while (rcx--) stosb
	pop r11											;return r11
	pop rcx											;return rcx
	pop rax											;return rax
	pop rdx											;return rdx
	pop rsi											;return rsi
	ret
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
		cmp al, 0									;if (al == 0) zf = 1				|
		je end_count								;if (zf == 1) goto end_count----|	|
		add rcx, 1									;rcx += 2						|	|
	jmp count										;-------------------------------|---|
	end_count:										;<------------------------------|
	pop rsi											;back rsi | string start
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
	call strlen										;calc len of string
	str_to_buffer:									;put str symbol to Buffer <---------|
		lodsb										;mov al, [rsi] / inc rsi			|
		call check_buffer							;check buffer overflow / put symbol	|
	loop str_to_buffer								;-----------------------------------|
	pop rsi											;return rsi to format string
	jmp _default_									;goto _default_

_c_:
	mov rax, rsi									;rax = rsi | put symbol to rax
	call check_buffer								;check buffer overflow / put symbol
	pop rsi											;return rsi to format string
	jmp _default_									;goto _default_

_b_:
	mov rcx, 1										;amount of bytes per one symbol
	mov rbx, 0x01									;mask for binary
	jmp _numbers_2_systems_							;goto _numbers_2_systems_

_o_:
	mov rcx, 3										;amount of bytes per one symbol
	mov rbx, 0x07									;mask for oct
	jmp _numbers_2_systems_							;goto _numbers_2_systems_

_x_:
	mov rcx, 4										;amount of bytes per one symbol
	mov rbx, 0x0F									;mask for hex
	jmp _numbers_2_systems_							;goto _numbers_2_systems_

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
	mov rax, rsi									;rax = rsi | put number to rax

	shr rax, 31										;get sign bit
	cmp rax, 1										;if (rax == 1) zf = 0
	jne unsigned									;if (zf != 0) goto unsigned	--------|
	mov rax, '-'									;rax = '-'							|
	call check_buffer								;check buffer overflow | put symbol	|
	mov rax, rsi									;prepare number to negative			|
	neg eax											;rax *= -1							|
	mov rsi, rax									;rsi = rax							|
													;									|
	unsigned:										;<----------------------------------|
		push rdi									;save current Buffer ip
		mov rdi, trans_buffer						;rdi = &trans_buffer
		mov rcx, 10									;rcx = 10 | ss base
		mov rax, rsi								;rax = rsi

	division:										;<----------------------------------------------|
		cqo											;dd rax -> dq rdx:rax by sign bit duplicating	|
		div rcx										;rdx:rax /= rcx // rax - result // rdx - part	|
		add rdx, '0'								;rdx += 30										|
		mov [rdi], rdx								;trans_buffer[i] = 'c'							|
		inc rdi										;rdi++											|
		cmp rax, 0									;if (rax == 0) zf = 0							|
	ja division										;if (zf > 0) goto division ---------------------|

	jmp _to_printf_buffer_							;goto _to_printf_buffer_
;==============================================================================

;==============================================================================
;	Handler of binary system parameter
;	Entry:		RCX - binary base
;				RBX - mask
;				RSI - number
;	Exit:		None
;	Destroy:	None
;==============================================================================
_numbers_2_systems_:
	push rdi										;save current Buffer ip
	mov rdi, trans_buffer							;rdi = &trans_buffer_

	transform:										;<----------------------------------|
		mov rax, rsi								;rax = rsi							|
		and rax, rbx								;use mask							|
		mov rdx, symbols_array						;rdx = &symbols_array				|
		add rdx, rax								;rdx += rax | get symbol ASCII code	|
		mov al, [rdx]								;al = [rdx] | symbol				|
		stosb										;mov [rdi], al / inc rdi			|
		shr rsi, cl									;rsi >> cl							|
		cmp rsi, 0									;if (rsi == 0) zf = 0				|
	ja transform									;if (zf > 0) goto transform --------|

	jmp _to_printf_buffer_							;goto _to_printf_buffer_
;==============================================================================

;==============================================================================
;	From transform buffer to printf buffer
;	Entry:		RDI - pointer to end of transform buffer
;	Exit:		None
;	Destroy:	None
;==============================================================================
_to_printf_buffer_:
	mov rsi, rdi									;rsi = rdi
	pop rdi											;return current Buffer ip

	mov rcx, rsi									;rcx = rsi
	sub rcx, trans_buffer							;rcx = rsi - trans_buffer
	inc rcx											;rcx++

	put_to_buffer:									;<--------------------------------------|
		mov al, [rsi]								;al = [rsi] | symbol from trans_buffer	|
		call check_buffer							;check Buffer overflow | put symbol		|
		mov [rsi], dword 0							;[rsi] = 0								|
		dec rsi										;rsi--									|
	loop put_to_buffer								;while(rcx--) goto put_to_buffer -------|

	pop rsi											;return current format string ip
	jmp _default_									;goto _default_
;==============================================================================
