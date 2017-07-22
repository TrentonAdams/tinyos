BITS 16

;incbin "myfirst.bin"

stage2:
	mov si, text_string	  ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	mov si, crlf	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	call read_keys
	jmp $


print_key:
  mov ah, 0         ; 16h read key function
  int 16h           ; al now has character from keyboard
  mov ah, 0Eh       ; TTY output, ah had scan code, we discard
  int 10h           ; prints character in ah

read_keys:
  mov ah, 01h       ; detect key
  int 16h
  jnz print_key     ; only print if key in buffer
	jmp read_keys			; Jump to read_keys - infinite loop!

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

	crlf db 0x0a,0x0d,0
	text_string db 'Kernel loaded!', 0
  buffer2 times 1024-($-$$) db 0

