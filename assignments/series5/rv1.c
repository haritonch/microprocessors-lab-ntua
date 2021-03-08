// memory-mapped I/O addresses
#define GPIO_SWs    0x80001400
#define GPIO_LEDs   0x80001404
#define GPIO_INOUT  0x80001408

#define READ_GPIO(dir) (*(volatile unsigned *)dir)
#define WRITE_GPIO(dir, value) { (*(volatile unsigned *)dir) = (value); }

int main ( void )
{
    int En_Value=0xFFFF, switches_value;
    int MSB, LSB, LEDS;

    WRITE_GPIO(GPIO_INOUT, En_Value);
  
    while (1) { 
        switches_value = READ_GPIO(GPIO_SWs);   // read value on switches
        switches_value = switches_value >> 16;

        MSB = (switches_value & 0xF000) >> 12;
        LSB = switches_value & 0x000F;
        LEDS = LSB + MSB;
        WRITE_GPIO(GPIO_LEDs, LEDS);  // display switch value on LEDs
    }

    return(0);
}
