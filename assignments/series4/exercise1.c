#include <avr/io.h>
#define F_CPU 8000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
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

ISR(TIMER1_OVF_vect) {
	ADCSRA |= (1<<ADSC); // start ADC conversion
	TCNT1H = 0xfc; // reset counter
	TCNT1L = 0xf2;
}

int set_levels(unsigned char adc_input) {
	int level;
	if (adc_input < 20) level = 0x01;
	else if (adc_input < 45) level = 0x03;
	else if (adc_input < 70) level = 0x07;
	else if (adc_input < 100) level = 0x0f;
	else if (adc_input < 120) level = 0x1f;
	else if (adc_input < 130) level = 0x3f;
	else level = 0x7f;
	return level;
}

int counter = 0;
char wrong_pass = 0;

void blink(int level) {
	if (level < 0x0f) { // leds on
		counter = 0;
		PORTB = wrong_pass | level;
	}
	else { // blink
		if (counter < 5) {
			counter++;
			PORTB = wrong_pass | level;
		}
		else {
			counter++;
			PORTB = wrong_pass;
		}
		if (counter == 10) {
			counter = 0;
			PORTB = wrong_pass;
		}
	}
}

ISR(ADC_vect) {
	char adc_low = ADCL;
	char adc_high = ADCH;
	adc_low >>= 2;
	adc_high <<= 6;
	unsigned char adc_input = adc_high | adc_low;
	int level = set_levels(adc_input);
	blink(level);
}

int main(void) {
	//setup ADC
	ADMUX = 1 << REFS0;
	ADCSRA = (1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
	
	//setup timer1
	TCCR1B = (1 << CS12) | (0 << CS11) | (1 << CS10);
	TCNT1H = 0xfc;
	TCNT1L = 0xf2;
	TIMSK = 1 << TOIE1;
	
	// setup keypad
	DDRC = 0xf0;
	int input1, input2;
	char key1, key2;
	
	// set PORTB as output
	DDRB = 0xff;
	
	blink(1);
	sei();
	
	while (1) {
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

		if (key1 == 'A' && key2 == '1') { // pass
			cli();
			PORTB = 0x80;
			_delay_ms(4000);
			sei();
		}
		else {
			for (int i=1; i<=4; ++i) {
				wrong_pass = 0x80;
				_delay_ms(500);
				wrong_pass = 0x00;
				_delay_ms(500);
			}
		}
	}
}



