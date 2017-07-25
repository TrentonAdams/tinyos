BITS 16

;incbin "myfirst.bin"
%include "macros.asm"

%define EXTRA

; figure out how memory segmentation works.  Presumably you can just
; temporarily adjust ds, es, etc within code that is being executed within that
; section.

start:
  dw 0x1234               ; kernel identification signature
  mov [boot_drive], dl

	mov si, text_string	    ; Put string position into SI
	call p_print_string
	; debug to show boot drive was transferred
	;mov di, dst_buf
	;sb 0x20
	;to_hex_buf [boot_drive]
	;sb 0x0
	;print dst_buf
	
	mov si, s_crlf	        ; Put string position into SI
	call p_print_string

	call read_disk_stats

read_keyboard:
	call read_keys
	jmp $


load_segment:
; loads another program into a different segment.
  mov ah, 0             ; reset disk
  mov dl, [boot_drive]  ; drive 0
  stc
  int 13h
  jc load_fail      ; return, we're a failure

  mov bx, [program2_sector]       ; place in memory [sector2] bytes past where the MBR is loaded.
  mov ah, 0x02 ; function
  mov al, 0x01 ; sectors to read
  mov ch, 0x00 ; track/cyl
  mov cl, 0x0A ; sector start
  mov dh, 0x00 ; head
  mov dl, [boot_drive] ; drive

  stc
  int 13h
  jc load_fail
  jmp read_keyboard

;; bad kernel, show the first 3 bytes loaded from sector 2.
bad_code:
  ;call p_show_first_bytes
  jmp $

;; simple disk read failure
load_fail:
  call p_int13_show_error
  jmp $                         ; super failure, halt.

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
  %include "extra.asm"
  %include "common_vars.asm"

  drive_found db 'Using drive: ', 0x00
	text_string db 'Kernel loaded:', 0

	program2_sector dw 0xA00

  dst_buf times 128 db 0xff
  src_buf times 128 db 0xff