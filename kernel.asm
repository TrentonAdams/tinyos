BITS 16

;incbin "myfirst.bin"

start:
  ; 0x7e0 shr 4 => 0x7e00 - 0x200 => 0x7c00 or 512 bytes past the original
  ; boot loader memory space.
  mov ax, 0x7e0;
  mov ds, ax
	mov si, text_string	  ; Put string position into SI
	call p_print_string	    
	mov si, crlf	        ; Put string position into SI
	call p_print_string
	call read_keys
	jmp $


print_key:
  mov ah, 0         ; 16h read key function
  int 16h           ; al now has character from keyboard
  mov ah, 0Eh       ; TTY output, ah had scan code, we discard
  int 10h           ; prints character in al

read_keys:
  mov ah, 01h       ; detect key
  int 16h
  jnz print_key     ; only print if key in buffer
	jmp read_keys			; Jump to read_keys - infinite loop!

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

;read_disk_stats:
;  pusha
;  ;;print stats
;;  print dbg
;;  print_hex [boot_drive]
;  mov ah, 8
;;  mov dl, [boot_drive]
;  stc
;  int 13h
;  jc ds_rf
;  print drive_found
;  print_hex [boot_drive]      ; '0x' + '80' + 0a0d
;
;  mov di, buf_16              ; store results of int 13h f8 (ah = 08)
;  sb bl
;  xchg cl,ch                  ; store them in sequence, not little endian
;  xchg dl,dh
;  sw cx
;  sw dx
;
;  mov cx, 5                   ; loop length
;  mov si, buf_16              ; int 13h results at buf_16, convert to ascii hex
;  mov di, buffer              ; and store in buffer
;results:
;  lodsb
;  call p_store_hex
;  sb 0x20
;  loop results                ; <-- decrement cx and loop if cx not 0
;
;  sb 0x00                     ; terminate string
;  print buffer
;  print crlf
;  jmp ds_done
;ds_rf:
;  call int13_show_error
;ds_done:
;  popa
;  ret

	crlf db 0x0a,0x0d,0
	text_string db 'Kernel loaded!', 0
