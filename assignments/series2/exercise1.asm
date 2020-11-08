; Authors: Iasonas Nikolaou, Chariton Charitonidis

start:
	clr r26
	out DDRC,r26 ; input
	ser r26
	out DDRB, r26 ; output

loop:
	in r16, PINC
	andi r16,0x0F
	mov r17, r16 ; r17 = A
	mov r18, r16 ; r18 = B
	lsr r18
	mov r19, r18 ; r19 = C
	lsr r19
	mov r20, r19 ; r20 = D
	lsr r20

	mov r21, r17 ; r21 = A
	com r21      ; r21 = A'
	and r21, r18 ; r21 = A'B

	mov r22, r18; r22 = B'CD
	com r22
	and r22, r19
	and r22, r20

	or r21, r22 ; r21 = (A'B + B'CD)
	com r21 ; r21 = (A'B + B'CD)'

	mov r23, r17 ; r23 = AC
	and r23, r19
	mov r24, r18 ; r24 = B+D
	or r24, r20
	mov r25, r23 ; r25 = AC(B+D)
	and r25, r24

	lsl r25
	andi r25, 0x02
	andi r21, 0x01

	or r21, r25
	mov r26, r21

	out PORTB , r26
	rjmp loop
