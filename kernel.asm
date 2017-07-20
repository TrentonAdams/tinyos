BITS 16

	mov si, text_string	  ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	mov si, crlf	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	jmp $

print_string:			; Routine: output string in SI to screen
  push ax
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
  pop ax
	ret

	text_string db 'Kernel loaded!', 0
	crlf db 0x0a,0x0d,0
