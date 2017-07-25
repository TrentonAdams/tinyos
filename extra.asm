%ifdef EXTRA
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
%endif