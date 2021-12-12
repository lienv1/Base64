section .data 			
	isone dq "1"
	iszero dq "0"
	TargetString db "        "
	TARGETLEN equ $-TargetString
	isequal db "2"
	emptyspace db "",10
	TargetString2 db "                        " ;16 bits
	;; TargetString2 db "000000000000000000000000"
	TARGETLEN2 equ $-TargetString2
	TargetString2v2 db "            " ;12 bits
	TARGETLEN2v2 equ $-TargetString2v2

	x dq 	'000000'
	y dq 	000000
	z dq 	'100110'
	resetx 	dq '000000'
	max dq	111111
	msg dq  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	TargetString3 db "      "
	TARGETLEN3 equ $-TargetString
	onevar db "1"
	zerovar db "0"
	equalSign dq "="

segment .bss
	varLen equ 1
	var: resb varLen	

	sum resb 6
	sum2 resb 6	
   	BUFFLEN	equ 6		; We read the file 100 bytes at a time
	Buff: 	resq BUFFLEN	; Text buffer itself sum resb 1
	var2 resb 6
	tooshort resb	1	;add '=', if 8 bit left
	tooshort2 resb 1	;add '=', if 8 bit left
	
section .text

global _start
	
_start:
	mov r12d, 0		;for T2 position
	mov r14d,3		;3 for reading 3 char at once
_proceed:
	mov r11d,0		;for T1 position
	
	mov eax,3		;read a char of File
	mov ebx,0
	mov ecx,var		;place the char in ecx
	mov edx,varLen		;varLen is 1 because it is 1 char
	int 80h
	
	cmp eax, 0		;if nothing to read, then exit
	je _fillZeros		;but did r14d reached 3 char yet?
	
		;for checking if we reached 24 bit
	mov edi, TargetString	;prepare char to bin
	mov r13d, TargetString2	;prepare for storing 24 bit
	
	mov ebp,9		;counter for reading 8 bit	
	mov r9b, byte[var] ;get bit of char at position of edi
	call _charToBin
	
_charToBin:
	dec ebp			;counter start
	cmp ebp, 0		;if not 0 then loop
	je _storeInTarget2	;char complete 8-bit now
	
	mov r10b, r9b		;get char
	and r10b, 80h		;test bit with 0x80
	cmp r10b, 80h		;check if bit is 0x80 through 'and'
	je _one			; it is 1
	jne _zero		; it's zero
	ret
_one:
	mov al, byte[isone]	;pass '1' to al
	mov byte [edi+r11d], al	;pass '1' to edi, which is TargetString, at pos r11d
	shl r9b, 1		;move to next bit of char
	inc r11d		;prepare next position
	jmp _charToBin		;and go back to loop
	ret	
_zero:
	mov al, byte [iszero]	;pass '0' to al
	mov byte [edi+r11d], al	;pass '0' to TargetString at position r11d
	shl r9b, 1		;move to next bit of char
	inc r11d		;prepare next position
	jmp _charToBin		;and go back to loop
	ret

	;; experiment
_fillZeros:				
	cmp r14d,3	;no char to read and 24 bit is formable
	je _exit	;then finish
	
	cmp r14d,1 	;if we have 16 bit and want to add 8 more bits to get 24
	je _fillZeros8	;proceed to fill
	
	cmp r14d,2 	;if we have 8 bit and want to add 4  more bits to get 12
	je _fillZeros12	;proceed to fill	
	ret

_fillZeros8:
	mov r15d,[equalSign]
	mov [tooshort], r15d
	
	mov ecx,8		;prepare for passing 8 bits
	counter2:
	mov al, byte [iszero]	;pass 0  to al
	mov byte [r13d+r12d], al;pass 0 or 1 to T2
	inc r12d		;move to next position of T2
	loop counter2		;loop until ecx is 0
	jmp _part3
	ret

_fillZeros12:
	mov r15d,[equalSign]
	mov [tooshort], r15d
	mov [tooshort2],r15d
	;; experiment transfer T2 to T2.5

	mov ebp,0
	mov r8d, TargetString2v2
	mov ecx,8
	counter11:
	mov al, byte[TargetString2+ebp]
	mov byte [r8d+ebp],al
	inc ebp
	loop counter11
	;;

	
	mov ecx,4		;prepare for passing 16 bits
	counter3:
	mov al, byte [iszero]	;pass 0  to al
	mov byte [r8d+r12d], al;pass 0 or 1 to T2
	inc r12d		;move to next position of T2
	loop counter3		;loop until ecx is 0
	jmp _part3v2
	ret		
	;; experiment
	
_storeInTarget2:
	
	mov ecx, 8		;prepare counter
	mov edx, 0		;prepare position
		
	counter:	
	mov al, byte [TargetString+edx]	;pass 0 or 1 from T1 at position edx to al
	mov byte [r13d+r12d], al	;pass 0 or 1 to T2
	inc r12d		;move to next position of T2
	inc edx			;move to next position of T1
	loop counter		;loop until ecx is 0
	
	dec r14d
	cmp r14d,0
	je _part2
	jne _proceed


_part2:				;as long we have char to read, this loop repeat
	mov r14d,3
	mov r12d,0
	
	mov eax,4
	mov ebx,1
	mov ecx,TargetString2
	mov edx,TARGETLEN2
	
	;; print new line removed

	call Read		;this process transform 24 bit to base64
	jmp _proceed
	ret
	
Read:	

;;; ;;;;;;;;;;;;;;;;;;;;;;;
				;pass r13d?  T2 (24-bit) to r9d, r9d is the center now
		
	mov r9d,r13d	
	
	mov eax,4
	mov ebx,1
	mov ecx, r9d
	mov edx,TARGETLEN2
	

	call _turnStringtoNumber
	call _turnStringtoNumber
	call _turnStringtoNumber
	call _turnStringtoNumber
	
	ret
	
_turnStringtoNumber:
	
	xor edx,edx
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx
	xor esi,esi
	xor edi,edi
				;This only works for '000000' format!!!
	
	mov esi, r9d		;put your experiment var

	mov ecx, 6		;This causes error if Buff is not 6 in length

	cld                     ; We want to move upward in mem
	xor edx, edx            ; edx = 0 (We want to have our result here)
	xor eax, eax            ; eax = 0 (We need that later)

	counter5:
	imul edx, 10            ; Multiply prev digits by 10 
	lodsb                   ; Load next char to al
	sub al,48               ; Convert to number
	add edx, eax            ; Add new number
				; Here we used that the upper bytes of eax are zeroed
	loop counter5            ; Move to next digit
	
				; edx now contains the result
	mov eax, edx		; as example mov eax, [z] or mov eax, edx
	;;experiment	;to extend string to 000000, if equal to 000000 then exit
	xor ebx,ebx

		
	mov ebx, [y]
	add ebx, eax
	mov eax, ebx
	xor ebx, ebx
	
	;; experiment
	xor edx, edx
	call _div
	ret
_div:				;this operation transfer binary to decimal
	
	mov ebx, 10
	div ebx
	shl edx, 0
	mov esi, edx
	add edi, esi
	
	xor edx,edx
    
    div ebx
    shl edx, 1
    mov esi, edx
    add edi, esi
    
    xor edx,edx
    
    div ebx
    shl edx, 2
    mov esi, edx
    add edi, esi
    
    xor edx,edx    
    
    div ebx
    shl edx, 3
    mov esi, edx
    add edi, esi
    
    xor edx,edx  
    
    div ebx
    shl edx, 4
    mov esi, edx
    add edi, esi
    
    xor edx,edx  
     
    div ebx
    shl edx, 5
    mov esi, edx
	add edi, esi

	xor edx, edx
 
	mov eax, edi

	mov [sum2], eax

	;; experiment
	cmp eax, 64
	jge Read
	;; experiment

	call _getChar
	ret

_getChar:			;this print char based on base64 
	mov ecx, msg
	add ecx, [sum2]		;move to position of sum2 in base64	
	mov eax,4		;print the char
	mov ebx,1
	mov edx,1
	int 80h
	add r9d, 6
ret

;;; ;;;;;;;;;;;;

Read2:	

;;; ;;;;;;;;;;;;;;;;;;;;;;;
		
	mov r9d,r8d	
	
	mov eax,4
	mov ebx,1
	mov ecx, r9d
	mov edx,TARGETLEN2
	

	call _turnStringtoNumber
	call _turnStringtoNumber
	
	ret

_turnStringtoNumber2: 		;version 2 for 12 bits
	
	xor edx,edx
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx
	xor esi,esi
	xor edi,edi
				;This only works for '000000' format!!!
	
	mov esi, r9d		;put your experiment var

	mov ecx, 6		;This causes error if Buff is not 6 in length

	cld                     ; We want to move upward in mem
	xor edx, edx            ; edx = 0 (We want to have our result here)
	xor eax, eax            ; eax = 0 (We need that later)

	counter9:
	imul edx, 10            ; Multiply prev digits by 10 
	lodsb                   ; Load next char to al
	sub al,48               ; Convert to number
	add edx, eax            ; Add new number
				; Here we used that the upper bytes of eax are zeroed
	loop counter9            ; Move to next digit
	
				; edx now contains the result
	mov eax, edx		; as example mov eax, [z] or mov eax, edx
	;;experiment	;to extend string to 000000, if equal to 000000 then exit
	xor ebx,ebx

		
	mov ebx, [y]
	add ebx, eax
	mov eax, ebx
	xor ebx, ebx
	
	;; experiment
	xor edx, edx
	call _div2
	ret
_div2:				;this operation transfer binary to decimal, same fun as _div, but for left over
	
	mov ebx, 10
	div ebx
	shl edx, 0
	mov esi, edx
	add edi, esi
	
	xor edx,edx
    
    div ebx
    shl edx, 1
    mov esi, edx
    add edi, esi
    
    xor edx,edx
    
    div ebx
    shl edx, 2
    mov esi, edx
    add edi, esi
    
    xor edx,edx    
    
    div ebx
    shl edx, 3
    mov esi, edx
    add edi, esi
    
    xor edx,edx  
    
    div ebx
    shl edx, 4
    mov esi, edx
    add edi, esi
    
    xor edx,edx  
     
    div ebx
    shl edx, 5
    mov esi, edx
	add edi, esi

	xor edx, edx
 
	mov eax, edi

	mov [sum2], eax

	;; experiment
	cmp eax, 64
	jge Read
	;; experiment

	call _getChar
	ret


;;; ;;;;;;;;;;


_part3:				;Every char succesfully transfer to bits

	mov r12d,0
	
	;; print new line removed

	call Read
	call _exit
	ret

_part3v2:				;Every char succesfully transfer to bits

	mov r12d,0
	
	;; print new line removed

	call Read2
	call _exit
	ret
	
_exit:				;finish

	
	mov eax,4
	mov ebx,1
	mov ecx,tooshort
	mov edx,1
	int 80h


	mov eax,4
	mov ebx,1
	mov ecx,tooshort2
	mov edx,1
	int 80h

	int 80h
	
	mov     eax, 1
	int     0x80