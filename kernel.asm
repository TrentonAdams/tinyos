BITS 16

;incbin "myfirst.bin"
%include "macros.asm"


start:
  ; 0x7e0 shr 4 => 0x7e00 - 0x200 => 0x7c00 or 512 bytes past the original
  ; boot loader memory space.
  mov ax, 0x800;
  mov ds, ax
  mov es, ax
  add ax, 288
  mov [boot_drive], dl

	mov si, text_string	    ; Put string position into SI
	call p_print_string	    
	mov si, s_crlf	        ; Put string position into SI
	call p_print_string
	
	call read_disk_stats
	call read_keys
	jmp $


read_keys:
  mov ah, 01h       ; detect key
  int 16h
  jnz print_key     ; only print if key in buffer
	jmp read_keys			; Jump to read_keys - infinite loop!

print_key:
;; simply prints a key from the character buffer
  mov ah, 0         ; 16h read key function
  int 16h           ; al now has character from keyboard
  mov ah, 0Eh       ; TTY output, ah had scan code, we discard
  int 10h           ; prints character in al
  jmp read_keys

read_disk_stats:
  pusha
  ;;print stats
;  print dbg
;  print_hex [boot_drive]
  mov ah, 8
  mov dl, [boot_drive]
  stc
  int 13h
  jc ds_rf
  push di
  print s_dbg
  print drive_found
  print_hex [boot_drive]      ; '0x' + '80' + 0a0d

  mov di, src_buf             ; store results of int 13h f8 (ah = 08)
  sb bl                       ;   si will point to src_buf later
  xchg cl,ch                  ; store them in big endian so we can read them
  xchg dl,dh                  ; as a stream of bytes
  sw cx
  sw dx

  mov cx, 5                   ; loop length 5 for 5 bytes to show in hex
  mov si, src_buf             ; int 13h results at dst_buf, convert to ascii hex
  mov di, dst_buf             ; and store in buffer
results:
  lodsb
  call p_store_hex
  sb 0x20
  loop results                ; <-- decrement cx and loop if cx not 0

  sb 0x00                     ; terminate string
  print dst_buf
  print s_crlf

  mov ax, di                  ; print the pointer of di, not contents
  print_hex ah
  print_hex al
  pop di
  mov ax, di                  ; print the pointer of di, not contents
  print_hex ah
  print_hex al

  print_hex [di]              ; print the contents of di
  print_hex [di + 1]
  print_hex [di + 2]
  print_hex [di + 3]
  print_hex [di + 4]
  jmp ds_done
ds_rf:
  call p_int13_show_error
ds_done:
  popa
  ret

  %include "common.asm"
  %include "common_vars.asm"

  drive_found db 'Using drive: ', 0x00
	text_string db 'Kernel loaded!', 0

  dst_buf times 128 db 0xff
  src_buf times 128 db 0xff