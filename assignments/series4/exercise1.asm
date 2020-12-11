.DSEG
_tmp_: .byte 2

.CSEG

.org 0x00
rjmp start
.org 0x10
rjmp ISR_TIMER1_OVF
.org 0x1c
rjmp ISR_ADC

start:
	ldi r24, low(RAMEND) ; initialize stack pointer
	out SPL, r24
	ldi r24, high(RAMEND)
	out SPH, r24

	ser r24		; set PORTB as output
	out DDRB, r24

	clr r30	; initialize counter
	clr r31 ; initialize level state

	; setup lcd screen
	ser r24
	out DDRD, r24
	clr r24
	rcall lcd_init_sim

	; setup keyboard
	ldi r24, 0xf0 ; set 4 MSB of PORTC as output
	out DDRC, r24
	rcall scan_keypad_rising_edge_sim

	; setup timer1
    ldi r24 ,(1<<CS12) | (0<<CS11) | (1<<CS10) ; CK/1024
	out TCCR1B, r24 
	ldi r24, 0xE1    ; initialize TCNT1
	out TCNT1H, r24    ; to overflow after 2 secs
	ldi r24, 0x7B
	out TCNT1L, r24
	ldi r24, (1<<TOIE1)
	out TIMSK, r24

	ldi r24 ,(1<<CS12) | (0<<CS11) | (1<<CS10) ; CK/1024
	out TCCR1B, r24 

	; setup ADC
	rcall ADC_init

	sei ; enable all interrupts

main:
	; read input
input1: ; read while input1 != 0
	rcall scan_keypad_rising_edge_sim
	mov r16, r24
	or r16, r25
	breq input1
	mov r16, r24 ; r17:r16 <- input1
	mov r17, r25
	rcall scan_keypad_rising_edge_sim

input2: ; read while input2 != 0
	rcall scan_keypad_rising_edge_sim
	mov r18, r24
	or r18, r25
	breq input2
	mov r18, r24 ; r19:r18 <- input2
	mov r19, r25

	; convert input1 to ascii1
	mov r24, r16
	mov r25, r17
	rcall keypad_to_ascii_sim
	mov r20, r24 ; r20 <- ascii1

	; convert input2 to ascii2
	mov r24, r18
	mov r25, r19
	rcall keypad_to_ascii_sim
	mov r21, r24 ; r21 <- ascii2

	cpi r20, 'A'
	brne fail
	cpi r21, '1'
	brne fail
	jmp pass

	jmp main

pass:
	cli
	ldi r25, 0x80
	out PORTB, r25
	rcall display_welcome
	ldi r24, low(4000) ; wait 4 secs
	ldi r25, high(4000)
	rcall wait_msec
	clr r24
	rcall lcd_init_sim
	clr r25
	out PORTB, r25
	clr r31 ; initialize level state
	sei
	jmp main

fail:
	ldi r25, 0x80
	mov r13, r25
	rcall wait_half_sec
	clr r13
	rcall wait_half_sec
	ldi r25, 0x80
	mov r13, r25
	rcall wait_half_sec
	clr r13
	rcall wait_half_sec
	ldi r25, 0x80
	mov r13, r25
	rcall wait_half_sec
	clr r13
	rcall wait_half_sec
	ldi r25, 0x80
	mov r13, r25
	rcall wait_half_sec
	clr r13
	rcall wait_half_sec
	jmp main

ISR_TIMER1_OVF:
	push r24
	in r24, ADCSRA
	ori r24, (1<<ADSC) ; start ADC conversion
	out ADCSRA, r24
	ldi r24, 0xfc    ; reset TCNT1
	out TCNT1H, r24    ; to overflow after 100 msecs
	ldi r24, 0xf2
	out TCNT1L, r24
	ldi r24, (1<<TOIE1)
	out TIMSK, r24
	pop r24
	ret

; output: r18
ISR_ADC:
	push r28
	push r29
	in r28, ADCL
	in r29, ADCH
	rcall set_levels
	rcall display_message
	rcall blink
	pop r29
	pop r28
	sei
	ret

; input: r1 (counter), r18 (levels)
blink:
	cpi r18, 0x0f ; if level > 70 then "alarm"
	brlo safe
	cpi r30, 0x05
	brlo lt5
	cpi r30, 0x0A
	brlo lt10
	clr r30
	ret
lt10:
	clr r25
	or r25, r13 ; set MSB (wrong password)
	out PORTB, r25
	inc r30
	ret
lt5:
	mov r25, r18
	or r25, r13 ; set MSB (wrong password)
	out PORTB, r18
	inc r30
	ret
safe:
	clr r30
	mov r25, r18
	or r25, r13 ; set MSB (wrong password)
	out PORTB, r25
	ret

; input: r28, r29
; output: r18 (level of CO)
set_levels:
	push r24
	push r25
	push r28
	push r29
	lsr r28		; shift 2 bits right
	lsr r28
	lsl r29		; shift 6 bits left
	lsl r29
	lsl r29
	lsl r29
	lsl r29
	lsl r29
	or r28, r29
	mov r24, r18
	andi r24, 0x80 ; get MSB of r18
	ldi r18, 0x01
	cpi r28, 0x14	; level 1 = 20
	brlo set_leds
	ldi r18, 0x03
	cpi r28, 0x2d  ; level 2 = 45
	brlo set_leds
	ldi r18, 0x07
	cpi r28, 0x46  ; level 3 = 70
	brlo set_leds
	ldi r18, 0x0f
	cpi r28, 0x64  ; level 4 = 100
	brlo set_leds
	ldi r18, 0x1f
	cpi r28, 0x78  ; level 5 = 120
	brlo set_leds
	ldi r18, 0x3f
	cpi r28, 0x82  ; level 6 = 130
	brlo set_leds
	ldi r18, 0x7f	; level 7 > 130
set_leds:
	pop r29
	pop r28
	pop r25
	pop r24
	ret

display_message:
	cp r18, r31
	brne change_message
	ret
change_message:
	mov r31, r18
	cpi r18, 0x0f ; if level > 70 then "gas detected" else "clear"
	brlo dis_clear
	rcall display_gas_detected
	ret
dis_clear:
	rcall display_clear
	ret

display_welcome:
	push r24
	clr r24
	rcall lcd_init_sim
	ldi r24, 'W'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'L'
	rcall lcd_data_sim
	ldi r24, 'C'
	rcall lcd_data_sim
	ldi r24, 'O'
	rcall lcd_data_sim
	ldi r24, 'M'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	pop r24
	ret
display_gas_detected:
	push r24
	clr r24
	rcall lcd_init_sim
	ldi r24, 'G'
	rcall lcd_data_sim
	ldi r24, 'A'
	rcall lcd_data_sim
	ldi r24, 'S'
	rcall lcd_data_sim
	ldi r24, ' '
	rcall lcd_data_sim
	ldi r24, 'D'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'T'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'C'
	rcall lcd_data_sim
	ldi r24, 'T'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'D'
	rcall lcd_data_sim
	pop r24
	ret

display_clear:
	push r24
	clr r24
	rcall lcd_init_sim
	ldi r24, 'C'
	rcall lcd_data_sim
	ldi r24, 'L'
	rcall lcd_data_sim
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'A'
	rcall lcd_data_sim
	ldi r24, 'R'
	rcall lcd_data_sim
	pop r24
	ret

; help functions

; setup ADC
ADC_init:
	ldi r24,(1<<REFS0) ; Vref: Vcc
	out ADMUX,r24 ;MUX4:0 = 00000 for A0.
	;ADC is Enabled (ADEN=1)
	;ADC Interrupts are Enabled (ADIE=1)
	;Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)
	ldi r24,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out ADCSRA, r24
	ret

wait_half_sec:
	push r24
	push r25
	ldi r24, low(500) ; wait 4 secs
	ldi r25, high(500)
	rcall wait_msec
	pop r25
	pop r24
	ret

wait_msec:
	push r24
	push r25
	ldi r24, low(998)
	ldi r25, high(998)
	rcall wait_usec
	pop r25
	pop r24
	sbiw r24, 1
	brne wait_msec
	ret

wait_usec:
	sbiw r24, 1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret

write_2_nibbles_sim:
    push r24
    push r25
    ldi r24, low(6000)
    ldi r25, high(6000)
    rcall wait_usec
    pop r25
    pop r24
    push r24
    in r25, PIND
    andi r25, 0x0f
    andi r24, 0xf0
    add r24, r25
    out PORTD, r24
    sbi PORTD, PD3
    cbi PORTD, PD3
    push r24
    push r25
    ldi r24, low(6000)
    ldi r25 ,high(6000)
    rcall wait_usec
    pop r25
    pop r24
    pop r24
    swap r24
    andi r24 ,0xf0
    add r24, r25
    out PORTD, r24
    sbi PORTD, PD3
    cbi PORTD, PD3
    ret

lcd_data_sim:
    push r24
    push r25
    sbi PORTD, PD2
    rcall write_2_nibbles_sim
    ldi r24 ,43
    ldi r25 ,0
    rcall wait_usec
    pop r25
    pop r24
    ret

lcd_command_sim:
    push r24
    push r25
    cbi PORTD, PD2
    rcall write_2_nibbles_sim
    ldi r24, 39
    ldi r25, 0
    rcall wait_usec
    pop r25
    pop r24
    ret

lcd_init_sim:
    push r24
    push r25
    ldi r24, 40
    ldi r25, 0
    rcall wait_msec
    ldi r24, 0x30
    out PORTD, r24
    sbi PORTD, PD3
    cbi PORTD, PD3
    ldi r24, 39
    ldi r25, 0
    rcall wait_usec
    push r24
    push r25
    ldi r24,low(1000)
    ldi r25,high(1000)
    rcall wait_usec
    pop r25
    pop r24
    ldi r24, 0x30
    out PORTD, r24
    sbi PORTD, PD3
    cbi PORTD, PD3
    ldi r24,39
    ldi r25,0
    rcall wait_usec
    push r24
    push r25
    ldi r24 ,low(1000)
    ldi r25 ,high(1000)
    rcall wait_usec
    pop r25
    pop r24
    ldi r24,0x20
    out PORTD, r24
    sbi PORTD, PD3
    cbi PORTD, PD3
    ldi r24,39
    ldi r25,0
    rcall wait_usec
    push r24
    push r25
    ldi r24 ,low(1000)
    ldi r25 ,high(1000)
    rcall wait_usec
    pop r25
    pop r24
    ldi r24,0x28
    rcall lcd_command_sim
    ldi r24,0x0c
    rcall lcd_command_sim
    ldi r24,0x01
    rcall lcd_command_sim
    ldi r24, low(1530)
    ldi r25, high(1530)
    rcall wait_usec
    ldi r24 ,0x06
    rcall lcd_command_sim
    pop r25
    pop r24
    ret

scan_row_sim:
	out PORTC, r25
	push r24
	push r25
	ldi r24, low(500)
	ldi r25, high(500)
	rcall wait_usec
	pop r25
	pop r24
	nop
	nop
	in r24,PINC
	andi r24, 0x0f
	ret

scan_keypad_sim:
	push r26
	push r27
	ldi r25, 0x10
	rcall scan_row_sim
	swap r24
	mov r27, r24
	ldi r25, 0x20
	rcall scan_row_sim
	add r27, r24
	ldi r25, 0x40
	rcall scan_row_sim
	swap r24
	mov r26, r24
	ldi r25, 0x80
	rcall scan_row_sim
	add r26, r24
	movw r24, r26
	clr r26
	out PORTC, r26
	pop r27
	pop r26
	ret

scan_keypad_rising_edge_sim:
	push r22
	push r23
	push r26
	push r27
	rcall scan_keypad_sim
	push r24
	push r25
	ldi r24, 15
	ldi r25 ,0
	rcall wait_msec
	rcall scan_keypad_sim
	pop r23
	pop r22
	and r24, r22
	and r25, r23
	ldi r26, low(_tmp_)
	ldi r27, high(_tmp_)
	ld r23, X+
	ld r22, X
	st X, r24
	st -X, r25
	com r23
	com r22
	and r24, r22
	and r25, r23
	pop r27
	pop r26
	pop r23
	pop r22
	ret

keypad_to_ascii_sim:
	push r26
	push r27
	movw r26, r24
	ldi r24,'*'
	sbrc r26, 0
	rjmp return_ascii
	ldi r24,'0'
	sbrc r26, 1
	rjmp return_ascii
	ldi r24,'#'
	sbrc r26, 2
	rjmp return_ascii
	ldi r24, 'D'
	sbrc r26, 3
	rjmp return_ascii
	ldi r24, '7'
	sbrc r26, 4
	rjmp return_ascii
	ldi r24, '8'
	sbrc r26, 5
	rjmp return_ascii
	ldi r24, '9'
	sbrc r26, 6
	rjmp return_ascii
	ldi r24, 'C'
	sbrc r26, 7
	rjmp return_ascii
	ldi r24, '4'
	sbrc r27, 0
	rjmp return_ascii
	ldi r24, '5'
	sbrc r27, 1
	rjmp return_ascii
	ldi r24, '6'
	sbrc r27, 2
	rjmp return_ascii
	ldi r24, 'B'
	sbrc r27, 3
	rjmp return_ascii
	ldi r24, '1'
	sbrc r27, 4
	rjmp return_ascii
	ldi r24, '2'
	sbrc r27, 5
	rjmp return_ascii
	ldi r24, '3'
	sbrc r27, 6
	rjmp return_ascii
	ldi r24, 'A'
	sbrc r27, 7
	rjmp return_ascii
	clr r24
	rjmp return_ascii
return_ascii:
	pop r27
	pop r26
	ret