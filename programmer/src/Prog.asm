.LISTMAC 
;.include "m103def.inc"
.include "4414def.inc"

.def	t0 =		r16
.def	t1 =		r17
.def	s0 =		r18
.def	s1 =		r19
.def	s2 =		r20
.def	s3 =		r21
.def	c0 =		r22
.def	c1 =		r23
.def	crcl =	r24
.def	crch =	r25

.cseg
	.org	0
	rjmp	main
	.org	URXCaddr
	ret ;rjmp	rxd_int	;UART Receive Complete Interrupt Vector Address
	.org	UDREaddr
	ret ;rjmp			;UART Data Register Empty Interrupt Vector Address
	.org	UTXCaddr
	ret ;rjmp			;UART Transmit Complete Interrupt Vector Address

; UDR is data register
; USR is status register
; USR.RXC is 1 end of receiving
; USR.TXC is 1 end of sending
; USR.UDR is 1 start sending
; USR.FE  is 1 frame error (self reset)
; USR.DOR is 1 overflow (self reset)
; UCR is control register
; UCR.RXCIE is 1 enable interrupt when end of receiving
; UCR.TXCIE is 1 same for end of transmiting
; UCR.UDRIE is 1 enable interrupt when transmiter empty
; UCR.RXEN is 1 enable receiving
; UCR.TXEN is 1 enable transmiting
; UCR.CHR9 is 1 enable 9 bits
; UCR.RXB8 is 9th bit of receiver
; UCR.TXB8 is 9th bit of transmiter
; UBRR BAUD generator
; For  4МГц crystall
; UBRR = 12 is 19200
; UBRR = 25 is 9600
; UBRR = 51 is 4800
; UBRR = 103 is 2400

;*****************************************************************
; Set baudrate

.equ	rate19200 =	12
.equ	rate9600  =	25
.equ	rate4800  =	51
.equ	rate2400  =	103

set_speed:
	ldi	t0,rate19200
	out	UBRR,t0
	ret

com_ena:
	sbi	UCR,RXEN
	sbi	UCR,TXEN
	ldi	t0,'>'
	out	UDR,t0
	ret
	
;*****************************************************************
; The Data-Address controll

.equ	port_adl =		PORTA
.equ	port_adh =	PORTB
.equ	portin_adl =	PINA
.equ	portin_adh =	PINB
.equ	dir_adl =		DDRA
.equ	dir_adh =		DDRB

dir_o:	
	ldi	t0,255
	out	dir_adl,t0
	out	dir_adh,t0
	ret

dir_i:	
	clr	t0
	out	dir_adl,t0
	out	dir_adh,t0
	ret

;*****************************************************************
; Strobe's controll

.equ	port_control =	PORTC
.equ	dir_control =	DDRC
.equ	balel =		0
.equ	baleh =		1
.equ	bwr = 		2
.equ	brd =		3
.equ	breset= 		7

control_init:
	ldi	t0,255
	out	dir_control,t0
	ret

aleh1:
	sbi	port_control,baleh
	ret
aleh0:
	cbi	port_control,baleh
	ret
alel1:
	sbi	port_control,balel
	ret
alel0:
	cbi	port_control,balel
	ret
wr1:
	sbi	port_control,bwr
	ret
wr0:
	cbi	port_control,bwr
	ret
rd1:
	sbi	port_control,brd
	ret
rd0:
	cbi	port_control,brd
	ret
res1:
	sbi	port_control,breset
	ret
res0:
	cbi	port_control,breset
	ret
;*****************************************************************
; Set address for FLASH access

.def	Lal =	r28
.def    Lah =	r29
.def	Hal =	r30
.def    Hah =	r31

address:
	rcall	aleh1		; Strobe aleh
	rcall	alel1
	rcall	dir_o			; Output
	out	port_adl,Hal	; Out address
	out	port_adh,Hah
	rcall	aleh0	
	out	port_adl,Lal	; 
	out	port_adh,Lah
	rcall	alel0			; strobe alel
	ret

inc_address:
	ldi	t0,2
	add	Lal,t0
	ldi	t0,0
	adc	Lah,t0
	adc	Hal,t0
	adc	Hah,t0
	ret
	
;*****************************************************************
; Read the word dl and dh

.def	dl =	r26
.def    dh =	r27
 
read_word:
	rcall	address		; set address
read_wordnext:
	rcall	dir_i			; input
	rcall	rd0			; rd to 0
	in	dl,portin_adl
	in	dh,portin_adh
	rcall	rd1			; rd to 1
	ret
	

;*****************************************************************
; Write the word dl and dh
 
write_word:
	rcall	address		; set address
	out	port_adl,dl
	out	port_adh,dh
	rcall	wr0			; rd to 0
	nop
	nop
	rcall	wr1			; rd to 1
	ret

;*****************************************************************
; programming FLASH из dl-dh

; Set address to constant
a0000:
	clr	Lal
	clr	Lah
	clr	Hal
	clr	Hah
	ret
a5555:
	ldi	Lal,LOW((0x5555<<1))
	ldi	Lah,HIGH((0x5555<<1))
	ret
a2AAA:
	ldi	Lal,LOW((0x2AAA<<1))
	ldi	Lah,HIGH((0x2AAA<<1))
	ret
; Set constant	
d5555:
	ldi	dl,0x55
	ldi	dh,0x55
	ret
dAAAA:
	ldi	dl,0xAA
	ldi	dh,0xAA
	ret
dFFFF:
	ldi	dl,0xFF
	ldi	dh,0xFF
	ret
dA0A0:
	ldi	dl,0xA0
	ldi	dh,0xA0
	ret
d8080:
	ldi	dl,0x80
	ldi	dh,0x80
	ret
d1010:
	ldi	dl,0x10
	ldi	dh,0x10
	ret
d3030:
	ldi	dl,0x30
	ldi	dh,0x30
	ret
; the programming		
prog_word:
	push	dl
	push	dh
	push	Lal
	push	Lah
	push	Hal
	push	Hah
	rcall	a5555
	rcall	dAAAA
	rcall	write_word
	rcall	a2AAA
	rcall	d5555
	rcall	write_word
	rcall	a5555
	rcall	dA0A0	
	rcall	write_word
	pop	Hah
	pop	Hal
	pop	Lah
	pop	Lal
	pop	dh
	pop	dl
	rcall	write_word
	rcall	data_polling
	ret
; ожидание завершения
data_polling:
	mov	s0,dl
	mov	s1,dh
d_p_0:
	rcall	read_word
	eor	dl,s0
	eor	dh,s1
	or	dl,dh
	brne	d_p_0		; if T = 1 repeat
	mov	dl,s0
	mov	dh,s1
	ret 
	
;*****************************************************************
; Clear sector

clr_sec:
	push	Lal
	push	Lah
	push	Hal
	push	Hah
	rcall	a5555
	rcall	dAAAA
	rcall	write_word
	rcall	a2AAA
	rcall	d5555
	rcall	write_word
	rcall	a5555
	rcall	d8080	
	rcall	write_word
	rcall	a5555
	rcall	dAAAA
	rcall	write_word
	rcall	a2AAA
	rcall	d5555
	rcall	write_word
	pop	Hah
	pop	Hal
	pop	Lah
	pop	Lal
	rcall	d3030
	rcall	write_word
	rcall	dFFFF
	rcall	data_polling
	ret

;*****************************************************************
; Clear all IC

clr_chip:
	push	Lal
	push	Lah
	push	Hal
	push	Hah
	rcall	a5555
	rcall	dAAAA
	rcall	write_word
	rcall	a2AAA
	rcall	d5555
	rcall	write_word
	rcall	a5555
	rcall	d8080	
	rcall	write_word
	rcall	a5555
	rcall	dAAAA
	rcall	write_word
	rcall	a2AAA
	rcall	d5555
	rcall	write_word
	rcall	a5555
	rcall	d1010
	rcall	write_word
	rcall	dFFFF
	rcall	data_polling
	pop	Hah
	pop	Hal
	pop	Lah
	pop	Lal
	ret
	
;*****************************************************************
;	Read byte

read_byte:
	sbis	USR,RXC
	rjmp	read_byte
	in	s0,UDR
	ret

read_char:
	rcall	read_byte
	cpi	s0,' '
	brlo	read_char	; < 0x20
	ret
	
;*****************************************************************
; 	Send byte

write_byte:
	sbis	USR,UDRE
	rjmp	write_byte
	out	UDR,s0
	ret

;*****************************************************************
; Read address

read_address:
	rcall	clr_address
	rcall	rladdress
	rcall	rladdress
	rcall	rladdress
	rcall	rladdress
	rcall	rladdress
	rcall	rladdress
	ret

clr_address:
	clr	Lal
	clr	Lah
	clr	Hal
	clr	Hah
	ret

;*****************************************************************
; Read data

read_data:
	rcall	clr_data
	rcall	rldata
	rcall	rldata
	rcall	rldata
	rcall	rldata
	ret

clr_data:
	clr	dl
	clr	dh
	ret

;*****************************************************************
; the symbol to number

char_to_byte:
	andi	s0,0x7F	
	cpi	s0,'a'
	brlo	hichar
	subi	s0,0x20
hichar:
	cpi	s0,'9'
	breq	digit		; s0 == 9
	brlo	digit		; s0 < 9
	subi	s0,'A' - 10	; s0 > 9
	ret
digit:
	subi	s0,'0'	; s0 =<9
	ret
	
;*****************************************************************
; Add the number to address
; address = SHIFTLEFT ( address,4 ) or s0

rladdress:
	rcall	read_char
	rcall	write_byte
	rcall	char_to_byte	; s0 = number ( s0 )
	ldi	t0,4			; for t0=4 to 0
rl_0:
	lsl	Lal
	rol	Lah
	rol	Hal
	rol	Hah			; shiftleft ( address )
	dec	t0
	brne	rl_0
	
	or	Lal,s0		; address # s0
	ret
	
;*****************************************************************
; Add the number to address
; data = SHIFTLEFT ( data,4 ) or s0

rldata:
	rcall	read_char
	rcall	write_byte
	rcall	char_to_byte	; s0 = number ( s0 )
	ldi	t0,4			; for t0=4 to 0
rl_d0:
	lsl	dl
	rol	dh			; shiftleft ( address )
	dec	t0
	brne	rl_d0
	
	or	dl,s0			; address # s0
	ret
	
;*****************************************************************
; Send data

send_data:
	mov	s0,dh
	rcall	bintohex
	mov	s0,s3
	rcall	write_byte
	mov	s0,s2
	rcall	write_byte
		
	mov	s0,dl
	rcall	bintohex
	mov	s0,s3
	rcall	write_byte
	mov	s0,s2
	rcall	write_byte
	ret

bintohex:
	mov	s1,s0
	rcall	b2h
	mov	s2,s0		; s2 = hex ( s0 and 0xF )
	mov	s0,s1
	swap	s0			; Hi 4 bits
	rcall	b2h
	mov	s3,s0		; s3 = hex ( shifright( s0,4) and 0xF) 
	ret
	
b2h:
	andi	s0,0xF		; low 4 bits
	cpi	s0,0xA
	brlo	b2h_digit	; < 0xA
	subi	s0,0-'A'+ 10
	ret
b2h_digit:
	subi	s0,0-'0'
	ret
	
;*****************************************************************
; Programm All IC

prog_all:
	rcall	counter_set
p_a_0:
	rcall	read_byte
	rcall   write_byte
	mov	dl,s0
	rcall	read_byte
	mov	dh,s0
	rcall	prog_word
	mov	s0,dh
	rcall	write_byte
	rcall	inc_address
	rcall	dec_counter
	brcc	p_a_0		
	ret
	
;*****************************************************************
; Read all IC

read_all:
	rcall	counter_set
r_a_0:
	rcall	read_word
	mov	s0,dl
	rcall	write_byte
	rcall	read_byte
	mov	s0,dh
	rcall	write_byte
	rcall	read_byte
	rcall	inc_address
	rcall	dec_counter
	brcc	r_a_0		
	ret


counter_set:
	ldi	c0,0xFF
	ldi	c1,0xFF
	ret
	
dec_counter:
	subi	c0,2
	sbci	c1,0
	ret
;*****************************************************************
; Проверка контрольной суммы
crc_all:
	clr	Lal
	clr	Lah
	rcall	counter_set
	rcall	crc_clr
crc_a_0:
	rcall	read_word
	rcall	crc_add
	rcall	inc_address
	rcall	dec_counter
	brcc	crc_a_0	
	mov	dl,crcl
	mov	dh,crch	
	rcall	send_data
	ret
		
crc_add:
	add	crcl,dl
	adc	crch,dh
	ret
crc_clr:
	clr	crcl
	clr	crch
	ret	
	
;*****************************************************************
; COMMANDER

command:
	rcall	read_char
	rcall	write_byte
	cpi	s0,'P'
	breq	prog_all
	cpi	s0,'x'
	breq	crc_all
	cpi	s0,'R'
	breq	read_all
	cpi	s0,'r'
	breq	com_r
	cpi	s0,'w'
	breq	com_w
	cpi	s0,'+'
	breq	com_plus
	cpi	s0,'a'
	breq	com_a
	cpi	s0,'i'
	breq	com_init
	cpi	s0,'p'
	breq	com_prog
	cpi	s0,'e'
	breq	com_echo
	cpi	s0,'t'
	breq	com_seta
	cpi	s0,'c'
	breq	com_clrs
	cpi	s0,'C'
	breq	com_clrchip
	cpi	s0,'n'
	breq	com_next
	ret
prompt:
	ldi	s0,'>'
	rcall	write_byte
	ret

;*****************************************************************
; The commands list

com_prog:
	rcall	read_data
	rcall	prog_word
	ret
com_w:
	rcall	read_data
	rcall	write_word
	ret
com_r:
	rcall	read_word
	rcall	send_data
	ret
com_a:
	rcall	read_address
	rcall	address
	ret
	
com_plus:
	rcall	inc_address
	rcall	address
	rjmp	com_r

com_init:
	rcall	res0
	nop
	rcall	aleh0
	rcall	alel0
	rcall	wr1
	rcall	rd1
	nop
	rcall	res1
	ret
	
com_echo:
	rcall	read_byte
	rcall	write_byte
	rjmp	com_echo
			
com_seta:
	rcall	address
	rjmp	com_seta
	
com_clrs:
	rcall	clr_sec
	ret

com_clrchip:
	rcall	clr_chip
	ret

com_next:
	rcall	read_wordnext
	rcall	send_data
	ret
;*****************************************************************
;*****************************************************************

main:
	ldi	t0,LOW(RAMEND)
	out	SPL,t0
	ldi	t0,HIGH(RAMEND)
	out	SPH,t0
	rcall	set_speed		; Set baud rate
	rcall	com_ena		; the com port now on
	rcall	control_init
	rcall	com_init
loop:
	rcall	command
	rcall	prompt
	rjmp	loop
	ret


	