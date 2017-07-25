;; immediately prints the string reference given.
%macro print 1
  pusha
	mov si, %1	        ; Put string position into SI
	call p_print_string	    ; Call our string-printing routine
	popa
%endmacro

;; immediately prints a single byte of hex to the screen
%macro print_hex 1
  %ifdef EXTRA
  mov al, %1
  call p_prn_hex
  %endif
%endmacro

;; for storing a byte in hex at the current buffer at [di]
%macro to_hex_buf 1
  %ifdef EXTRA
  mov al, %1
  call p_store_hex
  %endif
%endmacro

;; standard stosb, assumes you have [di] setup
%macro sb 1
  mov al, %1
  stosb
%endmacro

;; standard stosw, assumes you have [di] setup
%macro sw 1
  mov ax, %1
  stosw
%endmacro