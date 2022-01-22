jmp START
.org OC1Aaddr
	jmp TIME_INT
BTAB:.db $A, $06, $A, $06, $A, $06
	.dseg
TIME: .byte 6
LINE: .byte 16 + 1 
	.cseg
	.equ RS = $00
	.equ E = $01

	.equ E_MODE = $06
	.equ FN_SET = $2B
	.equ LCD_CLEAR = $01
	.equ DISP_ON = $0F
	.equ HOME = $02

	.equ SECOND_TICKS = 62500 - 1'

START:
	ldi r16, LOW(RAMEND) 
	out SPL, r16
	ldi r16, HIGH(RAMEND)
	out SPH, r16

	call MRCLEAN		
	call PORT_INIT		
	call WAIT		
	call DISPLAY_INIT	
	call KLOCKANINNAN24 
	call TIMER1_INIT	
	sei
	
MAIN:
	call TIME_FORMAT
	call LINE_PRINT
	jmp MAIN
	
TIME_INT: 
	push r16
	in r16, SREG
	call TIME_TICK
	out SREG, r16
	pop r16
	reti	

PORT_INIT:
	ldi r16, $FF
	out DDRB, r16
	out DDRD, r16
	clr r16
	ret

KLOCKANINNAN24: 
	ldi	XH, HIGH(TIME)
	ldi	XL, LOW(TIME)
	ldi r16,5
	sts TIME, r16
	ldi r16, 4
	sts TIME+1, r16
	ldi r16, 9
	sts TIME+2, r16
	ldi r16, 5
	sts TIME+3, r16
	ldi r16, 3
	sts TIME+4, r16
	ldi r16, 2
	sts TIME+5, r16
	ret

DISPLAY_INIT: 
	Call BACKLIGHT_ON
	call WAIT

	ldi r16, $30
	call LCD_WRITE4
	call LCD_WRITE4
	call LCD_WRITE4
	ldi r16, $20
	call LCD_WRITE4

	ldi r16, FN_SET
	call LCD_COMMAND

	ldi r16, DISP_ON
	call LCD_COMMAND

	ldi r16, LCD_CLEAR
	call LCD_COMMAND

	ldi r16, E
	call LCD_COMMAND
	ret
	
BACKLIGHT_ON:
	sbi PORTB,2
	ret

TIMER1_INIT:
	ldi r16,(1<<WGM12)|(1<<CS12)
	sts TCCR1B, r16
	ldi r16, HIGH(SECOND_TICKS)
	sts OCR1AH, r16
	ldi r16, LOW(SECOND_TICKS)
	sts OCR1AL, r16
	ldi r16,(1<<OCIE1A)
	sts TIMSK1, r16
	ret

LINE_PRINT:
	call LCD_HOME
	ldi ZH,HIGH(LINE)
	ldi ZL,LOW(LINE)
	call LCD_PRINT
	ret

LCD_PRINT:
	ld r16, Z+ 
	cpi r16, $00
	breq RETURN
	call LCD_ASCII
	jmp LCD_PRINT
RETURN:
	ret

LCD_HOME:
	ldi r16, HOME
	call LCD_COMMAND	
	ret

LCD_ERASE:
	ldi r16, LCD_CLEAR
	call LCD_COMMAND
	ret

LCD_ASCII:
	sbi PORTB,RS
	call LCD_WRITE8
	cbi PORTB,RS
	ret

LCD_COMMAND:
	cbi PORTB,RS
	call LCD_WRITE8
	ret

LCD_WRITE4:
	sbi PORTB,E
	out PORTD, r16
	cbi PORTB,E
	call WAIT
	ret

LCD_WRITE8:
	call LCD_WRITE4
	swap r16
	call LCD_WRITE4
	ret

WAIT: 
	adiw r24,1
	brne WAIT
	ret

TIME_FORMAT: 
	ldi	XH, HIGH(TIME)
	ldi	XL, LOW(TIME)

	ldi	YH, HIGH(LINE)
	ldi YL, LOW(LINE)

	ldi	r22, $00 
	sts	LINE+8, r22 
	
	ldi	r22, $3A 
	sts	LINE+5, r22 
	sts	LINE+2, r22 

	call TRANSLATE
	ret

TRANSLATE:
	adiw YL, 8
	ldi r24,6
T1:
	ld r16, -Y
T2:
	cpi r16, $3A 
	breq T1
	ld r16, X+ 
	ldi	r21, $30 
	add	r21, r16 
	st Y, r21	
	dec r24
	brne T1
	ret

TIME_TICK:
	push ZH
	push ZL
	push XH
	push XL
	push r16
	push r17
	push r18 
	push r19

	ldi XH, HIGH(TIME)
	ldi XL, LOW(TIME)
	ldi ZH, HIGH(BTAB*2)
	ldi ZL, LOW(BTAB*2)

TIME_LOOP:
	lpm r18, Z+
	ld r16, x 
	inc r16 
	cp r16, r18 
	brne STORE_TIME 
	clr r16 
	st x+, r16 
	jmp TIME_LOOP

STORE_TIME:
	st x, r16
	cpi r16, 4
	breq TIMME20
	jmp KLAR

TIMME20:
	ldi r17, 4
	lds r19, TIME+4
	cpse r19, r17 
	jmp KLAR

	ldi r17, $02
	lds r19, TIME+5   
	cpse r19, r17
	jmp KLAR
	call SET_NOLL
KLAR:
	pop r19
	pop r18
	pop r17
	pop r16
	pop XL
	pop XH
	pop ZL
	pop ZH
	ret

SET_NOLL:
	ldi r17, 6
	call CLEAR
	ret

MRCLEAN: 
	ldi r17, 30
	call CLEAR
	ret

CLEAR: 
    ldi XH,HIGH(TIME)
    ldi XL,LOW(TIME)
	ldi r16, $00
CLEAR_1:
    st X+, r16
    dec r17
    brne CLEAR_1
    ret

//FUNGERANDE TIME_TICK MEN KODDUP AF.
/*TIME_TICK:

	push XL
	push XH
	push r16
	

	ldi XH, HIGH(TIME)
	ldi XL, LOW(TIME)

	call ENTAL
	brne STORE_TIME
	call CLEAR_STORE
	call TIOTAL
	brne STORE_TIME
	call CLEAR_STORE
	call ENTAL
	brne STORE_TIME
	call CLEAR_STORE
	CAll TIOTAL
	brne STORE_TIME
	call CLEAR_STORE
	lds r20, TIME+5 //om tiotal timmar = 2, gör nått, annars räkna som vanligt(STS r20, TID*5
	cpi r20, 2
	breq TIMME20
	Call ENTAL
	brne STORE_TIME
	call CLEAR_STORE
	ldi r17,3 //tiotal TIM
	call COUNT
	jmp STORE_TIME
	

TIMME20: //om vi är uppe i timme 20 går den endast till 24 och sen reset.
	ldi r17,4 //tiotal min
	call COUNT
	brne STORE_TIME
	call CLEAR_STORE
	st x, r16
	jmp KLAR

STORE_TIME:
	st x, r16
KLAR:
	
	pop r16
	pop XH
	pop XL
	ret

CLEAR_STORE:
	clr r16
	st x+, r16
	ret

ENTAL:
	ldi r17,10 //ental sek
	call COUNT
	ret

TIOTAL:
	ldi r17,6 //tiotal sek
	call COUNT
	ret

COUNT:
	ld r16,x
	inc r16
	cp r16, r17
	ret*/