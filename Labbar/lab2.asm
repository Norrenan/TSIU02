HW_INIT:
	ldi r16, HIGH(RAMEND) 
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	
	ldi r16,$ff
	out DDRB,r16
	clr r16

	ldi ZH, HIGH(MESSAGE*2) 
	ldi ZL, LOW(MESSAGE*2) 

	.equ TID =12 

MORSE:
	call GET_CHAR 
	cpi r16, $00
	breq END
	cpi r16, $20 
	breq SPACE
	call LOOKUP 
	call SEND 
	jmp MORSE

SPACE: 
	ldi r26, (4*TID)
	call DELAY
	jmp MORSE

SEND:
	cpi r18,$80 
	breq DONE_BEEP
	call BEEP
	call GET_BIT  
	call DELAY
	call NO_BEEP
	ldi r26, TID
	call DELAY
	jmp SEND
DONE_BEEP:
	ldi r26, (TID*2)
	call DELAY
	ret

GET_BIT:	
	lsl r18
	brcs LONG
SHORT:
	ldi r26, TID
	jmp RETURN
LONG:
	ldi r26, (3*TID)
RETURN:
	ret

END:
	jmp END

LOOKUP:
	push ZL
	push ZH

	ldi ZH, HIGH(BTAB*2)  
	ldi ZL, LOW(BTAB*2) 
	
	subi r16, $41
	add	ZL,r16
	brcc NO_CARRY
	inc ZH
NO_CARRY:
	lpm r18, Z

	pop ZH
	pop ZL
	ret

GET_CHAR: 
	lpm r16, Z+ 
	ret	
		
BEEP:
	sbi	PORTB,4 
	ret
	
NO_BEEP:
	cbi PORTB,4 
	ret

DELAY:
D_1:
	ldi r29,1
D_2:
	adiw r28,1
	brne D_2
	dec r26
	brne D_1
	ret

MESSAGE: 
.db "LING", $00

BTAB:		
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8