// memory-mapped I/O addresses
#define GPIO_SWs    0x80001400
#define GPIO_LEDs   0x80001404
#define GPIO_INOUT  0x80001408

#define READ_GPIO(dir) (*(volatile unsigned *)dir)
#define WRITE_GPIO(dir, value) { (*(volatile unsigned *)dir) = (value); }

int aces(int switches_value) {
    int res = 0;
    while (switches_value) {
        res += switches_value & 1;
        switches_value >>= 1;
    }
    return res;
}

int main ( void )
{
    int En_Value=0xFFFF, switches_value, LEDS;

    WRITE_GPIO(GPIO_INOUT, En_Value);

    while (1) { 
         switches_value = READ_GPIO(GPIO_SWs);  // read value on switches
        // switches_value = switches_value >> 16;

        int initialMSB = switches_value & 0x8000;
        int nAces = aces(~switches_value & 0x0000ffff);
        for (int i = 0; i < nAces; ++i) {
            LEDS = ~switches_value & 0xFFFF;
            WRITE_GPIO(GPIO_LEDs, LEDS);  // display switch value on LEDs
            // delay
            WRITE_GPIO(GPIO_LEDs, 0);  // turn off LEDs
            // delay
        }
        while (1) {
             switches_value = READ_GPIO(GPIO_SWs);
            // switches_value = switches_value >> 16;
            int newMSB = switches_value & 0x8000;
            if (newMSB != initialMSB) {
                break;
            }
        }
    }
    return(0);
}