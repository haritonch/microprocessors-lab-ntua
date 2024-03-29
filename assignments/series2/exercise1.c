/*
 * Auhtors: Iasonas Nikolaou, Chariton Charitonidis
 */

#include <avr/io.h>

int main(void)
{
    DDRB = 0xFF;
	DDRC = 0x00;

	while (1)
	{
		int A = PINC & 0x01;
		int B = (PINC & 0x02) >> 1;
		int C = (PINC & 0x04) >> 2;
		int D = (PINC & 0x08) >> 3;

		int F0 = (~((~A&B) | (~B&C&D))) & 0x01;
		int F1 = (((A&C) & (B | D)) & 0x01) << 1;

		PORTB  = F0 | F1;
	}

}
