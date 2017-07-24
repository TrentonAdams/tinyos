	s_int13_read_status db 'Call status: ', 0
	s_crlf db 0x0a,0x0d,0
 	reg_16 db 0xFF,0xFF   ; temporary 16 bit storage for a register
 	; use "print s_dbg" anywhere to get an idea where you are when debugging
 	s_dbg db ' --> debug <-- ',0x0a,0x0d,0x00
	boot_drive db 0x00
	; p_prn_hex needs it's own buffer so we can do print_hex macro whenever we
	; feel like it, even if another buffer is in use.
	buf_p_prn_hex times 64 db 0xff
	; hex to ascii table
	s_hex_ascii db '0123456789ABCDEF',0

