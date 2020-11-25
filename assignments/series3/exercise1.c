/*
 * Auhtors: Iasonas Nikolaou, Chariton Charitonidis
 */

#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>

int keypad_to_ascii(int x) {
	int ascii[] = {'*','0','#','D','7','8','9','C','4','5','6','B','1','2','3','A'};
	for (int i=0; i<16; i++) {
		if (x & (1 << i)) {
			return ascii[i];
		}
	}
	return 'Z';
}

int scan_row_sim(char row) {
	PORTC = row << 4;
	_delay_us(500);
	asm volatile ("nop");
	asm volatile ("nop");
	return (PINC & 0x0f);
}

int scan_keypad_sim() {
	int output = 0;
	for (int row=1; row<=8; row <<= 1) {
		output <<= 4;
		output = output | scan_row_sim(row);
	}
	PORTC = 0x00;
	return output;
}

int prev_input;

int scan_keypad_rising_edge() {
	int input = scan_keypad_sim();
	_delay_ms(15);
	input &= scan_keypad_sim(); // bouncing
	int tmp = input;
	input = input & ~prev_input;
	prev_input = tmp;
	return input;
}

int main(void)
{
	while (42) {
		DDRC = 0xf0;
		DDRB = 0xff; // B: output
		int input1, input2;
		char key1, key2;
		scan_keypad_rising_edge();
		while (1) { // read 1st digit
			input1 = scan_keypad_rising_edge();
			if (input1) {
				break;
			}
		}
		scan_keypad_rising_edge();
		while (1) { // read 2nd digit
			input2 = scan_keypad_rising_edge();
			if (input2) {
				break;
			}
		}

		key1 = keypad_to_ascii(input1);
		key2 = keypad_to_ascii(input2);

		if (key1 == 'A' && key2 == '1') {
			PORTB = 0xff;
			_delay_ms(4000);
			PORTB = 0x00;
		}
		else {
			for (int i=0; i<4; ++i) {
				PORTB = 0xff;
				_delay_ms(500);
				PORTB = 0x00;
				_delay_ms(500);
			}
		}
	}

}
