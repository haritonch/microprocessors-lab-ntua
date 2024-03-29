/*
 * Auhtors: Iasonas Nikolaou, Chariton Charitonidis
 */

#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>

int countBits(int num)
{
	int c = 0;
	while (num)
	{
		c += num & 1;
		num >>= 1;
	}
	return c;
}

ISR (INT0_vect)
{
	int numOfSetBits = countBits(PINB);
	if (PINA & 2)
	{
		PORTC = numOfSetBits;
	}
	else
	{
		int out = 0;
		while (numOfSetBits--)
		{
			out = (out << 1) | 1;
		}
		PORTC = out;
	}
}

int main()
{
	DDRA = 0x00;
	DDRB = 0x00;
	DDRC= 0xff;

	GICR = 0x40;
	MCUCR = 0x03;

	sei();

	while(42)
	{

	}
}
