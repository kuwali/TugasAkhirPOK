.include "m16def.inc"

.def temp =r16	; Define temporary variable
.def EW = r17	; for PORTA
.def INDA = r18	; values sent to PORTC
.def A  = r19   ; value to be printed

; PORTA.0 as EN of LCD
; PORTA.1 as RS of LCD
; PORTA.2 as RW of LCD
; PORTB used by Keypad
; PORTC as INSTRUCTION OR DATA to LCD
; PORTD for LED


RESET:
	JMP     INIT		

.org 0x26
	JMP     SERV_ROUTINE
	JMP     GOTORESET	
INIT:
	CLR     R1               
	OUT     SREG,R1          
	LDI     YL,LOW(RAMEND) 
	LDI     YH,HIGH(RAMEND)
	OUT     SPH,R29        
	OUT     SPL,R28
	LDI     R17,0x00
	LDI     XL,0x60
	LDI     XH,0x00 
	LDI     ZL,0x16 
	LDI     ZH,0x04 
	RJMP    SKIP	
	LPM     R0,Z+
	ST      X+,R0
SKIP:
	CPI     XL,0x62
	CPC     XH,R17 
	BRNE    PC-0x04
	LDI     R17,0x00 
	LDI     XL,0x62  
	LDI     XH,0x00  
	RJMP    CONT	;PC+0x0002 
LOOP:
	ST      X+,R1     
;.org 0x40
CONT:
	CPI     XL,0x9A
	CPC     XH,R17 
	BRNE    LOOP	;PC-0x03
	CALL    MAIN
GOTORESET:
	JMP     RESET
MAIN:
	rcall INIT_LCD
	rcall CLEAR_LCD

	ldi	temp,$ff
	out	DDRA,temp	; Set port A as output
	out	DDRC,temp	; Set port B as output

;	ldi	ZH,high(2*message)	; Load high part of byte address into ZH
;	ldi	ZL,low(2*message)	; Load low part of byte address into ZL

;LOADBYTE:
;	lpm				; Load byte from program memory into r0

;	tst	r0			; Check if we've reached the end of the message
;	breq quit		; If so, quit

;	mov A, r0		; Put the character onto Port B
;	rcall WRITE_TEXT
;	adiw ZL,1		; Increase Z registers
;	rjmp LOADBYTE

;QUIT:	;rjmp QUIT
	SEI 
	CALL    START_TIMER	  
NEED_UPDATE:	
	CALL    PAD_UPDATE
	CALL    PAD_PRESS
	TST     R24  
	BREQ    NEED_UPDATE ;PC-0x05
	CALL    PAD_READ
	OUT     PORTC,R24
	CALL 	GET_ASCII
	mov 	A, r24		; Put the character onto Port B
	rcall 	WRITE_TEXT
	ldi 	r24, 0

	RJMP    NEED_UPDATE 

PAD_READ:
	LDS     R24,0x0060
	RET        

PAD_PRESS:
	LDS     R24,0x0062
	STS     0x0062,R1 
	RET  

PAD_UPDATE:
	LDS     R24,0x0063
	TST     R24
	BRNE    PC+0x22 ;GOCPI	
	SER     R25 
	OUT     DDRB,R25
	LDI     R24,0x0F 
	OUT     DDRB,R24 
	OUT     PINB,R25
	LDS     R24,0x0064 
	SUBI    R24,0xFF
	STS     0x0064,R24 
	CPI     R24,0x04
	BRCS    PC+0x03 ;STROBE0	; 
	STS     0x0064,R1
STROBE0:
	LDI     R24,0xF7
	LDI     R25,0x00
	LDS     R0,0x0064
	RJMP    THIS	
BFORE:
	ASR     R25 
	ROR     R24 
THIS:
	DEC     R0
	BRPL    BFORE
	ORI     R24,0xF0
	OUT     PORTB,R24
	LDI     R24,0x01
	LDI     R25,0x00
	CALL    TIMER_GET
	STS     0x0000,R24
	LDI     R24,0x01 
	RJMP    PROCLDI	
GOCPI:
	CPI     R24,0x01 
	BRNE    GOLDS		
	LDS     R24,0x0065 
	CALL    TIMER_EXPIRED
	TST     R24
	BREQ    GOLDS	
	IN      R24,0x16 
	STS     0x0066,R24 
	LDS     R24,0x0065 
	LDI     R22,0x01
	LDI     R23,0x00 
	CALL    TIMER_RESET	
	LDI     R24,0xF7
	LDI     R25,0x00  
	LDS     R0,0x0064
	RJMP    DCR		
	ASR     R25 
	ROR     R24 
DCR:
	DEC     R0 
	BRPL    PC-0x03 
	ORI     R24,0xF0
	LDS     R18,0x0066 
	CP      R18,R24
	BRNE    PADSTATE2	
	STS     0x0063,R1
	LDS     R24,0x0065
	CALL    CASEx
	RET  
PADSTATE2:
	LDI     R24,0x02  
PROCLDI:
	STS     0x0063,R24  
	RET
GOLDS:	  
	LDS     R24,0x0063
	CPI     R24,0x02 
	BRNE    B4RET	;PC+0x3A 
	LDS     R24,0x0065
	CALL    TIMER_EXPIRED
	TST     R24   
	BREQ    PC+0x34
	STS     0x0063,R1
	LDS     R24,0x0065
	CALL    CASEx
	IN      R18,0x16
	LDS     R24,0x0066
	CP      R18,R24
	BRNE    PC+0x29
	LDS     R24,0x0064
	LDI     R25,0x00
	LSL     R24  
	ROL     R25 
	LSL     R24 
	ROL     R25 
	MOV     R25,R24
	STS     0x0060,R24 
	LDI     R19,0x00  
	ANDI    R18,0xF0 
	ANDI    R19,0x00 
	CPI     R18,0xB0 
	CPC     R19,R1
	BREQ    PC+0x11 
	CPI     R18,0xB1
	CPC     R19,R1
	BRGE    GO_CPI	
	CPI     R18,0x70
	CPC     R19,R1
	BRNE    PC+0x10 
	RJMP    GOSUBI	
GO_CPI:
	CPI     R18,0xD0
	CPC     R19,R1  
	BREQ    PC+0x05 
	CPI     R18,0xE0 
	CPC     R19,R1
	BRNE    PC+0x09 
	RJMP    PC+0x0006
	SUBI    R25,0xFF 
	RJMP    PC+0x0004
	SUBI    R25,0xFE 
	RJMP    PC+0x0002
GOSUBI:
	SUBI    R25,0xFD 
	STS     0x0060,R25
	LDI     R24,0x01 
	STS     0x0062,R24 
B4RET:
	RET 

START_TIMER:
	LDI     R24,0x0D 
	OUT     TCCR0,R24 
	LDI     R24,0x01
	OUT     OCR0,R24 
	IN      R24,0x39
	ORI     R24,0x02
	OUT     TIMSK,R24 
	RET  

SERV_ROUTINE:
	PUSH    R1
	PUSH    R0 
	IN      R0,0x3F
	PUSH    R0 
	CLR     R1 
	PUSH    R24
	PUSH    R25
	PUSH    R30
	PUSH    R31 
	LDS     R24,0x0067
	LDS     R25,0x0068 
	ADIW    R24,0x01
	STS     0x0068,R25 
	STS     0x0067,R24 
	OR      R24,R25
	BRNE    PC+0x0D 
	LDI     ZL,0x69
	LDI     ZH,0x00
	LDD     R24,Z+0
	TST     R24
	BREQ    PC+0x03 
	SUBI    R24,0x01 
	STD     Z+0,R24  
	ADIW    Z,0x03 
	LDI     R24,0x00 
	CPI     ZL,0x99  
	CPC     ZH,R24
	BRNE    PC-0x09 
	POP     R31
	POP     R30
	POP     R25
	POP     R24
	POP     R0  
	OUT     SREG,R0  
	POP     R0
	POP     R1
	RETI 

TIMER_RESET:
	LDS     R18,0x0067
	LDS     R19,0x0068
	ADD     R18,R22 
	ADC     R19,R23
	CPI     R22,0x01 
	CPC     R23,R1
	BRNE    LENGTHREC  ;PC+0x02
	OUT     TCNT0,R1 
LENGTHREC:
	LDI     R25,0x00
	MOVW    Z,R24 
	LSL     ZL 
	ROL     ZH 
	ADD     ZL,R24 
	ADC     ZH,R25
	SUBI    ZL,0x97 
	SBCI    ZH,0xFF
	STD     Z+2,R19 
	STD     Z+1,R18 
	CP      R18,R22
	CPC     R19,R23
	BRCC    NOTDONE  
	LDI     R24,0x05
	RJMP    GOSTD	 
NOTDONE:
	LDI     R24,0x04  
GOSTD:
	STD     Z+0,R24  
	RET  

TIMER_GET:
	PUSH    R17 
	MOVW    R22,R24
	LDI     ZL,0x69 
	LDI     ZH,0x00
	LDI     R17,0x00
	LDD     R24,Z+0
	TST     R24 
	BRNE    TIM1	
	MOV     R24,R17 
	CALL    TIMER_RESET	
	RJMP    TIM0	
TIM1:
	SUBI    R17,0xFF 
	ADIW    Z,0x03
	CPI     R17,0x10
	BRNE    PC-0x0A 
TIM0:
	MOV     R24,R17
	POP     R17 
	RET 

TIMER_EXPIRED:
	IN      R25,0x39 
	ANDI    R25,0xFD 
	OUT     TIMSK,R25 
	LDI     R25,0x00 
	MOVW    Z,R24 
	LSL     ZL
	ROL     ZH
	ADD     ZL,R24
	ADC     ZH,R25
	SUBI    ZL,0x97
	SBCI    ZH,0xFF 
	LDD     R24,Z+0 
	CPI     R24,0x04 
	BRCS    PC+0x0E 
	CPI     R24,0x04  
	BRNE    PC+0x0E 
	LDD     R18,Z+1 
	LDD     R19,Z+2 
	LDS     R24,0x0067
	LDS     R25,0x0068
	CP      R24,R18 
	CPC     R25,R19 
	BRCS    PC+0x05 
	LDI     R24,0x03 
	STD     Z+0,R24   
	LDI     R25,0x01
	RJMP    PC+0x0002  
	LDI     R25,0x00
	IN      R24,0x39  
	ORI     R24,0x02 
	OUT     TIMSK,R24  
	MOV     R24,R25 
	RET   

CASEx:
	LDI     R25,0x00 
	MOVW    Z,R24 
	LSL     ZL 
	ROL     ZH 
	ADD     ZL,R24
	ADC     ZH,R25  
	SUBI    ZL,0x97
	SBCI    ZH,0xFF
	STD     Z+0,R1  
	RET   

STOPWATCH_GET:
	LDI     ZL,0x69  
	LDI     ZH,0x00  
	LDI     R18,0x00  
	LDI     R19,0x00
	MOV     R20,R18  
	LDD     R24,Z+0
	TST     R24     
	BRNE    PC+0x11 
	MOVW    Z,R18 
	LSL     ZL 
	ROL     ZH  
	ADD     ZL,R18 
	ADC     ZH,R19  
	SUBI    ZL,0x97 
	SBCI    ZH,0xFF 
	LDI     R24,0x04 
	STD     Z+0,R24 
	LDS     R24,0x0067 
	LDS     R25,0x0068 
	STD     Z+2,R25  
	STD     Z+1,R24  
	RJMP    CONT1		
	SUBI    R20,0xFF  
	SUBI    R18,0xFF  
	SBCI    R19,0xFF
	ADIW    Z,0x03    
	CPI     R18,0x10     
	CPC     R19,R1 
	BRNE    PC-0x1A 
CONT1:
	MOV     R24,R20  
	RET  

	LDI     R25,0x00 
	MOVW    Z,R24 
	LSL     ZL 
	ROL     ZH    
	ADD     ZL,R24  
	ADC     ZH,R25  
	SUBI    ZL,0x97  
	SBCI    ZH,0xFF    
	LDI     R24,0x04 
	STD     Z+0,R24 
	LDS     R24,0x0067 
	LDS     R25,0x0068 
	STD     Z+2,R25 
	STD     Z+1,R24 
	RET 

STOPWATCH_CHECK:
	LDI     R25,0x00
	MOVW    Z,R24
	LSL     ZL 
	ROL     ZH
	ADD     ZL,R24 
	ADC     ZH,R25 
	SUBI    ZL,0x97  
	SBCI    ZH,0xFF 
	LDD     R24,Z+0  
	CPI     R24,0x03 
	BRCS    CONT3	;PC+0x18  
	LDS     R20,0x0067 
	LDS     R21,0x0068 
	CPI     R24,0x04  
	BRNE    CONT4	;PC+0x07 
	LDD     R24,Z+1 
	LDD     R25,Z+2 
	MOVW    R18,R20 
	SUB     R18,R24 
	SBC     R19,R25  
	RJMP    CONT2	
CONT4:
	LDD     R24,Z+1
	LDD     R25,Z+2 
	CP      R20,R24 
	CPC     R21,R25
	BRCC    CONT3	
	MOVW    R18,R24  
	COM     R18 
	COM     R19 
	ADD     R18,R20
	ADC     R19,R21
	RJMP    CONT2	
CONT3:
	SER     R18 
	SER     R19
CONT2:
	MOVW    R24,R18 
	RET 

DELAY:
	PUSH    R17 
	CALL    TIMER_GET
	MOV     R17,R24  
	MOV     R24,R17  
	CALL    TIMER_EXPIRED
	TST     R24
	BREQ    PC-0x04  
	MOV     R24,R17 
	LDI     R25,0x00 
	MOVW    Z,R24 
	LSL     ZL
	ROL     ZH 
	ADD     ZL,R24 
	ADC     ZH,R25
	SUBI    R30,0x97
	SBCI    R31,0xFF 
	STD     Z+0,R1
	POP     R17
	RET   
;************** LCD DRIVER STARTS HERE *******************
WAIT_LCD:
;	ldi	r20, 1
;	ldi	r21, 2
;	ldi	r22, 2
;CONT:	dec	r22
;	brne	CONT
;	dec	r21
;	brne	CONT
;	dec	r20
;	brne	CONT
	nop
	nop
	nop
	nop
	ret

INIT_LCD: ; PORTC was originally PORTB
	cbi PORTA,1	; CLR RS
	ldi INDA,0x38	; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTC,INDA
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1	; CLR RS
	ldi INDA,$0E	; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTC,INDA
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1	; CLR RS
	ldi INDA,$06	; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTC,INDA
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

CLEAR_LCD:
	cbi PORTA,1	; CLR RS
	ldi INDA,$01	; MOV DATA,0x01
	out PORTC,INDA
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT: ; A stores ASCII to be printed on LCD
	sbi PORTA,1	; SETB RS
	out PORTC, A
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

; Routine for converting scanned binary to ASCII
GET_ASCII: ; scanned binary is stored in R24
	cpi R24, 12 ; check if it's 1
	breq ONE
	cpi R24, 8 ; check if it's 2
	breq TWO
	cpi R24, 4
	breq THREE
	cpi R24, 13
	breq FOUR
	cpi R24, 9
	breq FIVE
	cpi R24, 5
	breq SIX
	cpi R24, 14
	breq SEVEN
	cpi R24, 10
	breq EIGHT
	cpi R24, 6
	breq NINE
	cpi R24, 11
	breq ZERO
	cpi R24, 0
	breq UPKEY
	cpi R24, 1
	breq DOWNKEY
	cpi R24, 2
	breq RIGHTKEY
	cpi R24, 3
	breq LEFTKEY
	cpi R24, 7
	breq ENTER
	cpi R24, 15
	breq CLEARKEY
	rjmp NEXT

	
ONE:
	LDI R24, 0x31
	rjmp NEXT
TWO:
	LDI R24, 0x32
	rjmp NEXT
THREE:
	LDI R24, 0x33
	rjmp NEXT
FOUR:
	LDI R24, 0x34
	rjmp NEXT
FIVE:
	LDI R24, 0x35
	rjmp NEXT
SIX:
	LDI R24, 0x36
	rjmp NEXT
SEVEN:
	LDI R24, 0x37
	rjmp NEXT
EIGHT:
	LDI R24, 0x38
	rjmp NEXT
NINE:
	LDI R24, 0x39
	rjmp NEXT
ZERO:
	LDI R24, 0x30
	rjmp NEXT
UPKEY:
	LDI R24, 0x55
	rjmp NEXT
DOWNKEY:
	LDI R24, 0x44
	rjmp NEXT
RIGHTKEY:
	LDI R24, 0x52
	rjmp NEXT
LEFTKEY:
	LDI R24, 0x4C
	rjmp NEXT
ENTER:
	LDI R24, 0x45
	rjmp NEXT
CLEARKEY:
	LDI R24, 0x43
	rjmp NEXT
NEXT:
	ret

message:
.db	"Please be happy!"
.db	0


