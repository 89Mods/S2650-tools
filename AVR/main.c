#ifndef F_CPU
#define F_CPU 20000000UL
#endif

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>

//#define SIM_UART

//write char over UART
static int uart_putchar(char c, FILE *stream){
	
	while(!(UCSRA & (1<<UDRE)));	//busy loop
	UDR = c;
	
	return 0;
}

//get char over UART (currently not needed)
static int uart_getchar(FILE *stream){
	if(UCSRA & (1<<RXC)) return UDR;
	return _FDEV_EOF;
}

char waitForChar(){
	int a = _FDEV_EOF;
	while(a == _FDEV_EOF){
		a = uart_getchar(NULL);
	}
	return (char)a;
}

const uint8_t stockPrescalers[] = {
	(1 << CS11) | (1 << CS10),
	(1 << CS11) | (1 << CS10),
	(1 << CS10),
	(1 << CS10),
	(1 << CS10),
	(1 << CS10),
	(1 << CS10)
};

const uint16_t stockDivisors[] = {
	15624, //10Hz
	1561, //100Hz
	9999, //1KHz
	999, //10KHz
	99, //100KHz
	9, //1MHz
	6, //1.42MHz
};

void debugger();
void divisorSelectionMenu();

void cpuReset() {
	PORTB |= (1 << PB2);
	_delay_ms(1);
	for(uint8_t i = 0; i < 6; i++){
		PORTD |= (1 << PD5);
		_delay_us(240);
		PORTD &= ~(1 << PD5);
		_delay_us(240);
	}
}

int main(void){
	//Configure UART
	UBRRH = 0;
	//UBRRL = 10;
	UBRRL = 21;
	UCSRA = (1 << U2X);
	UCSRC = (1 << UCSZ1) | (1 << UCSZ0) | (1 << URSEL);
	UCSRB = (1 << RXEN) | (1 << TXEN);
	
	DDRA = 0;
	PORTA = 0;
	DDRC = 0;
	PORTC = 0;
	DDRD = (1 << PD5) | (1 << PD7);
	PORTD = 0;
	DDRB = 0b00000101;
	PORTB = 0b00000101;
	
	//Define stream for printf
	{
		static FILE uart_str = FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);
		stdout = stderr = &uart_str;
	}
	
	printf("Signetics 2650 microcomputer v1\r\n");
	cpuReset();
	_delay_ms(500);
	
#ifdef SIM_UART
	DDRA = 0xFF;
	for(uint8_t i = 0; i < 8; i++){
		PORTA = (1 << i);
		_delay_ms(128);
	}
#endif
	DDRA = 0x00;
	PORTA = 0x00;
	printf("Press Enter to continue");
	while(true){
		char c = waitForChar();
		if(c == 'p'){ //ROM programming mode
			cpuReset();
			DDRA = 0xFF;
			DDRC = 0xFF;
			DDRD = 0b11111110;
			DDRB = 0b00010111;
			PORTB = 0b00000111;
			uart_putchar('a', NULL);
			
			uint16_t dataLength = waitForChar() - 'A';
			dataLength |= (waitForChar() - 'A') << 4;
			dataLength |= (waitForChar() - 'A') << 8;
			dataLength |= (waitForChar() - 'A') << 12;
			
			uint8_t val = 0;
			uint16_t currAddr = 0;
			for(uint16_t i = 0; i < dataLength; i++){
				uart_putchar('n', NULL);
				val = waitForChar();
				
				PORTC = currAddr & 0xFF;
				PORTD &= 0b00100011;
				PORTD |= ((currAddr >> 8) & 7) << 2;
				PORTD |= ((currAddr >> 11) & 1) << 6;
				PORTA = val;
				PORTB &= ~(1 << PB0);
				_delay_us(24);
				PORTB |= (1 << PB0);
				_delay_ms(1);
				currAddr++;
			}
			uart_putchar('d', NULL);
			
			DDRA = 0x00;
			PORTA = 0x00;
			currAddr = 0;
			for(uint16_t i = 0; i < dataLength; i++){
				waitForChar();
				PORTC = currAddr & 0xFF;
				PORTD &= 0b00100011;
				PORTD |= ((currAddr >> 8) & 7) << 2;
				PORTD |= ((currAddr >> 11) & 1) << 6;
				PORTB &= ~(1 << PB1);
				_delay_us(24);
				val = PINA;
				PORTB |= (1 << PB1);
				currAddr++;
				uart_putchar((val & 15) + 48, NULL);
				uart_putchar((val >> 4) + 48, NULL);
				_delay_us(24);
			}
			
			PORTB |= (1 << PB4);
			goto loopForever;
		}else if(c == '\r'){
			break;
		}
	}
	
	DDRB = 0b00000101;
	PORTB = 0b00000101;
	DDRA = 0x00;
	PORTA = 0x00;
	DDRC = 0x00;
	PORTC = 0x00;
	DDRD = 0b10100010;
	PORTD = 0x00;
	printf("\r\nSelect CPU speed\r\n1) Single step (debug)\r\n2) 10Hz\r\n3) 100Hz\r\n4) 1KHz\r\n5) 10KHz\r\n6) 100KHz\r\n7) 1MHz\r\n8) 1.42MHz\r\n");
	PORTB &= ~(1 << PB2);
	TCCR1A = (1 << COM1A0);
	TCCR1B = (1 << WGM12);
#ifndef SIM_UART
	OCR2 = 3;
	TCCR2 = (1 << WGM21) | (1 << COM20) | (1 << CS20);
#endif
	cpuReset();
	
	uint8_t tccr = 0;
	while(true){
		char c = waitForChar();
		if(c == '1'){
			TCCR1A = TCCR1B = 0;
			debugger();
			goto loopForever;
		}
		if(c >= '2' && c <= '8'){
			OCR1A = stockDivisors[c - '2'];
			TCCR1B |= stockPrescalers[c - '2'];
			tccr = TCCR1B;
			break;
		}
	}
	PORTB &= ~(1 << PB2);
	
	loopForever:
	DDRA = 0;
	PORTA = 0;
#ifndef SIM_UART
	DDRB |= (1 << PB7);
	/*DDRB &= ~(1 << PB7);
	uint32_t time = 0;
	uint16_t count = 0;
	uint8_t last = 0;*/
#endif
	while(1){
#ifdef SIM_UART
		if(!(PINB & 0b1000)){
			TCCR1B = 0;
			uart_putchar(PINA, NULL);
			while(!(UCSRA & (1<<UDRE)));
			TCCR1B = tccr;
			while(!(PINB & 0b1000));
		}
#else
	PORTB ^= (1 << PB7);
	_delay_us(104.166666667f);
	/*time++;
	if((PINB & (1 << PB7)) != last) {
		last = PINB & (1 << PB7);
		count++;
	}
	_delay_us(10);
	if(time == 100000) {
		time = 0;
		count >>= 1;
		printf("%d\r\n", count);
		count = 0;
	}*/
#endif
	}
}

void debugger(){
	cpuReset();
	PORTB &= ~(1 << PB2);
	printf("\r\nEntered system debugger\r\nPress Enter to single-step\r\n");
	uint16_t currAddr;
	uint8_t currVal;
	uint32_t cycleCntr = 0;
	uint8_t read;
	uint8_t uartRead = 0;
	while(true){
		char c = waitForChar();
		if(c == '\r'){
			if(uartRead){
				DDRA = 0xFF;
				PORTA = 'a';
			}
			PORTD |= (1 << PD5);
			_delay_us(240);
			PORTD &= ~(1 << PD5);
			_delay_us(240);
			cycleCntr++;
			if(uartRead){
				DDRA = 0x00;
				PORTA = 0x00;
				uartRead = 0;
			}
			
			currVal = PINA;
			currAddr = PINC;
			currAddr |= (PIND & 0b00011100) << 6;
			currAddr |= (PIND & 0b01000000) << 5;
			//currAddr |= (PINB & 0b11000000) << 7;
			read = !((PINB & 0b10) >> 1);
			printf("%04lx\t%02d %04d %01d", cycleCntr, currVal, currAddr, currAddr >> 13);
			if(read) printf(" R");
			printf("\r\n");
#ifdef SIM_UART
			if(!(PINB & 0b1000)){
				printf("CPU requests UART");
				if(read){
					printf(" read.\r\n");
					uartRead = 1;
				}else{
					printf(" write. It says: '%c'.\r\n", currVal);
				}
			}
#endif
		}
	}
}

void divisorSelectionMenu(){
	
}
