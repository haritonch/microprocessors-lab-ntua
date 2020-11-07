; Authors: Iasonas Nikolaou, Chariton Charitonidis

start:
	.org 0x0
	rjmp init
	.org 0x4
	rjmp ISR1
init:
	ser r26
	out DDRC , r26 ; counter output
	out DDRB, r26 ; interrupt counter output
	clr r26
	out DDRA, r26 ; input
	clr r26 ; counter = 0
	clr r16 ; interupt counter = 0

reset:
	ldi r24 ,( 1 << ISC11) | ( 1 << ISC10)
	out MCUCR , r24 ; enable at positive edge
	ldi r24 ,( 1 << INT1) ; enable interrupt INT1
	out GICR , r24
	sei
loop:
	out PORTC , r26
	inc r26 ; increase counter
	rjmp loop

ISR1:
	in r17, PINA ; read PA7-PA6
	andi r17, 0xC0
	cpi r17, 0xC0
	brne end_if
	inc r16 ; increase interrupt counter
	out PORTB, r16
end_if:
	rjmp reset
