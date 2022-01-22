.equ RS = $00
.equ E = $01

.equ E_MODE = $06
.equ FN_SET = $2B
.equ LCD_CLEAR = $01
.equ DISP_ON = $0F
.equ HOME = $02

.dseg
TIME: .byte 6
LINE: .byte 17
CUR_POS: .byte 1
.cseg

START:
	ldi r16, LOW(RAMEND) 
	out SPL, r16
	ldi r16, HIGH(RAMEND)
	out SPH, r16

	call MRCLEAN
	call PORT_INIT
	call WAIT
	call DISPLAY_INIT
	clr r16	
	
MAIN:
	call KEY_READ
	call LCD_COL
	jmp MAIN

LCD_COL:
	ldi XH,HIGH(LINE)
	ldi XL,LOW(LINE)

	cpi r16, 1 
	breq SELECT 
	cpi r16,2
	breq LEFT
	cpi r16, 3
	breq DOWN
	cpi r16, 4
	breq UP
	cpi r16, 5
	breq RIGHT
	
SELECT:
	lds r16,CUR_POS
	cpi r20, 1
	breq OFF
ON:
	call BACKLIGHT_ON
	sts CUR_POS,r16
	jmp RETURN
OFF:
	call BACKLIGHT_OFF
	sts CUR_POS, r16
	jmp RETURN

DOWN:
	call INIT_PEKARE 
	cpi r16, $00 
	breq IS_Z_NOW 
	cpi r16, $41
	breq IS_Z_NOW
	dec r16
	jmp store
IS_Z_NOW:	
	ldi r16, $5A
	jmp STORE

UP:
	call INIT_PEKARE 
	cpi r16, $00
	breq IS_A_NOW
	cpi r16, $5A
	breq IS_A_NOW
	inc r16
	jmp store
IS_A_NOW:
	ldi r16, $41
	jmp STORE

LEFT:
	lds r16,CUR_POS
	cpi r16,0
	breq RETURN
	dec r16 
	sts CUR_POS,r16
	ldi r16, $10 
	jmp EXECUTE

RIGHT:
	lds r16,CUR_POS
	cpi r16,15 
	breq RETURN
	inc r16
	sts CUR_POS,r16
	ldi r16 , $16 
	jmp EXECUTE
STORE:
	st x,r16 
	call LCD_ASCII
	ldi r16,$10 
EXECUTE:
	call LCD_COMMAND
RETURN:
	ret

INIT_PEKARE:
	lds XL, CUR_POS
	ld r16,x 
	ret


ADC_READ8: 
	ldi r16,(1<<REFS0)|(1<<ADLAR)|0 
	sts ADMUX,r16 
	ldi r16,(1 << ADEN)|7 
	sts ADCSRA,r16
CONVERT:
	lds r16,ADCSRA
	ori r16,(1<<ADSC)
	sts ADCSRA,r16
ADC_BUSY:
	lds r16,ADCSRA
	sbrc r16,ADSC 
	jmp ADC_BUSY 
	lds r16,ADCH 
	ret

KEY_READ: 
	call KEY
	tst r16
	brne KEY_READ
KEY_WAIT_FOR_PRESS:
	call KEY
	tst r16
	breq KEY_WAIT_FOR_PRESS
	ret

KEY:
	call ADC_READ8 
	cpi r16,12 
	brlo K5 
	cpi r16,43 
	brlo K4
	cpi r16,82 
	brlo K3
	cpi r16,130 
	brlo K2
	cpi r16,207 
	brlo K1
K0:
	ldi r16,0
	jmp DONE
K1:
	ldi r16,1
	jmp DONE
K2:
	ldi r16,2
	jmp DONE
K3:
	ldi r16,3
	jmp DONE
K4:
	ldi r16,4
	jmp DONE
K5:
	ldi r16,5
DONE:
	ret


PORT_INIT: 
	ldi r16, $FF
	out DDRB, r16
	out DDRD, r16
	clr r16
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
	ldi r20, 1
	sbi PORTB,2
	ret

BACKLIGHT_OFF:
	ldi r20,0
	cbi PORTB,2
	ret

LCD_ASCII:
	sbi PORTB,RS
	call LCD_WRITE8
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

MRCLEAN:
    ldi XH,HIGH(TIME)
    ldi XL,LOW(TIME)
    ldi r17, 40
CLEAN_1:
    ldi r16, $00
    st X+, r16
    dec r17
    brne CLEAN_1
    ret
	
/*LCD_PRINT_HEX:
	call NIB2HEX
NIB2HEX:
	swap r16
	push r16
	andi r16,$0F
	ori  r16, $30
	cpi  r16,':'
	brlo NOT_AF
	subi r16, -$07
NOT_AF:
	call LCD_ASCII
	pop r16
	ret*/
