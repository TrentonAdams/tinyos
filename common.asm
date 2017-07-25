
p_print_string:			; Routine: output string in SI to screen
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

;; shows the int13 error status.
p_int13_show_error:
  pusha
  mov dl, ah
  print s_int13_read_status
  cld

  mov di, dst_buf

  sw 0x7830                  ; store ascii '0x' at the buffer
  to_hex_buf dl                  ; al already setup by int13, store in buffer
  sb 0                       ; end string with null 0x00
  print dst_buf
  print s_crlf

  popa
  ret

