p_prn_hex:
  pusha
  ; dual use stage2 as a buffer until kernel loaded, or if the kernel was bad
  mov di, buf_p_prn_hex
  call p_store_hex
  sw 0x0d0a
  sb 0x00
  print buf_p_prn_hex
  popa
  ret


p_store_hex:
;; Takes al, and converts it into two byte ascii hex, and stores the results
;; at [di] and [di + 1]
;;
;; al = byte to convert to 2 bytes of hex  e.g. 0x2D would now be a two
;; byte '2D' string, without a null byte.
;;
;; es:di = your buffer
;;
;; return: es:di = end of your buffer (i.e. next byte where you can store 0x00
;; to make it a string).  if al was 0x2D, the buffer will now contain two ascii
;; bytes representing 0x2D as '2D'. If you want it to be a string, store
;; a 0x00 at [di] (stosb 0x00)
  pusha
;; make hex display callable/reusable
  mov bx, s_hex_ascii           ; lookup table
	mov ah, al                  ; copy high nibble
	shr ah, 4                   ;     to ah
	and al, 0x0f                ; mask off low nibble in al
	and ah, 0x0f                ; mask off high nibble in ah
	xlat                        ; lookup low nibble in table pointed to by bx.
	xchg al, ah                 ; swap the high/low nibble
	xlat                        ; lookup high nibble in table pointed to by bx.
	stosw                       ; store ax (ascii hex of orig al) in the buffer
	mov [reg_16],di             ; save di for the pop

	popa
	mov di, [reg_16]            ; restore di for return, for continued use
  ret

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

