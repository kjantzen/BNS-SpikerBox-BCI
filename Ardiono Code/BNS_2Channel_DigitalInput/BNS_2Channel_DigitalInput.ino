//
// Heart & Brain based on ATMEGA 328 (UNO)
// V1.0
// Made for Heart & Brain SpikerBox (V0.62)
// Backyard Brains
// Stanislav Mircic
// https://backyardbrains.com/
//
// Carrier signal is at DIO 10 
//
//This code has been modified to read a single analog channel and 2 digital channels at Fs=1000
//the channels combined into 3 bytes

#define CURRENT_SHIELD_TYPE "HWT:HBLEOSB;"

//KJ - to keep the number of samples in teh buffer consistent (which may not be important but I will probably do anyway)
//KJ - I can increase this by 1/3 from 256 to 384.  The additional byte will store the trigger or status channel which only needs to be 8 bits
//#define BUFFER_SIZE 256  //sampling buffer size
#define BUFFER_SIZE 384  
#define SIZE_OF_COMMAND_BUFFER 30 //command buffer size

// defines for setting and clearing register bits
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

//KJ - this seems redunant since BUFFER_SIZE is already defined as a constant and it is never actually used, so I will comment it
//int buffersize = BUFFER_SIZE;

int head = 0;//head index for sampling circular buffer
int tail = 0;//tail index for sampling circular buffer

//KJ - this variable is also never used so I will comment it to
//byte writeByte;

//KJ - these variables are for retuning information querried over the serial port by the host
//KJ - the only informaiton that is currently returnable is the board type
char commandBuffer[SIZE_OF_COMMAND_BUFFER];//receiving command buffer
byte reading[BUFFER_SIZE]; //Sampling buffer
#define ESCAPE_SEQUENCE_LENGTH 6
byte escapeSequence[ESCAPE_SEQUENCE_LENGTH] = {255,255,1,1,128,255};
byte endOfescapeSequence[ESCAPE_SEQUENCE_LENGTH] = {255,255,1,1,129,255};

//KJ - define the input and ouput pin values
#define CARRIER_PIN 10
#define POWER_LED_PIN 13
//KJ - needs to define the input pins here for reading digital signals
#define TRIGGER_PIN9 9  //digital input pin 9
#define TRIGGER_PIN11 11 //digital input pin 11


/// Interrupt number - very important in combination with bit rate to get accurate data
//KJ  - the interrupt (confifgured below) will trigger an interrupt whenever the value in the timer reaches this number
//KJ - It is clear that the base clock rate (16 * 10^6) is being divided by the sameple rate to get the number of clock ticks between samples
//KJ - I am guessing that the same rate is multiplied by 8 to account for the prescaling applied below?
//KJ - I am not sure why the actual value is 198 instead of 199
//KJ - my plan is to adjust this to get a much lower sample rate since 10000 is close to the maximum for AD conversion using analogRead
//KJ - according to https://www.arduino.cc/en/Reference/AnalogRead
//KJ - 1000 Hz sampling is more than adequate for EEG and ECG
//int interrupt_Number=198;// Output Compare Registers  value = (16*10^6) / (Fs*8) - 1  set to 1999 for 1000 Hz sampling, set to 3999 for 500 Hz sampling, set to 7999 for 250Hz sampling, 199 for 10000 Hz Sampling
int interrupt_Number = 1999; // 1000 Hz sample rate

int numberOfChannels = 1;//current number of channels sampling <-(KJ) this variable is never used
int tempSample = 0; 
int digitalSample1 = 0;  //KJ - these will be used to store the digital inputs read on each sample
int digitalSample2 = 0;
int digitalOutput = 0;
int commandMode = 0;//flag for command mode. Don't send data when in command mode

void setup(){ 
  Serial.begin(230400); //Serial communication baud rate (alt. 115200)
  //while (!Serial)
  //{}  // wait for Serial comms to become ready
  delay(300); //whait for init of serial
  Serial.println("StartUp!");
  Serial.setTimeout(2);

  //KJ-set the mode of the AM modulation and power LED pints to output
  pinMode(CARRIER_PIN, OUTPUT);
  pinMode(POWER_LED_PIN, OUTPUT);
  //pinMode(TRIGGER_PIN9, INPUT);  //setup the two digital input trigger pins
  //pinMode(TRIGGER_PIN11, INPUT);
  
  //KJ-turn on the power LED
  digitalWrite(POWER_LED_PIN, HIGH);

  //KJ-The pins appear to go to LED's on the borad according to the schematic
  //VU meter LEDs
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);

//KJ-turn off all the LEDs
  digitalWrite(2, LOW);   
  digitalWrite(3, LOW);   
  digitalWrite(4, LOW);  
  digitalWrite(5, LOW);  
  digitalWrite(6, LOW);  
  digitalWrite(7, LOW);  
  digitalWrite(8, LOW);    

   
  // TIMER SETUP- the timer interrupt allows precise timed measurements of the read switch
  //for more info about configuration of arduino timers see http://arduino.cc/playground/Code/Timer1 ,- this link is dead
  cli();//stop interrupts

  //Make ADC sample faster. Change ADC clock
  //Change prescaler division factor to 16 ,- (KJ) I am not sure why this is done - it does not factor into the calculation of sample rate 
  //which are still based on the base 16MHz clock speed - probably because the timer is running in CTC mode?
  //KJ - the first 3 bits of the ADCSRA register control the prescale value
  //KJ - 100 (bits 2,1,0 respectively) is a prescale or division factor of 16
  sbi(ADCSRA,ADPS2);//1 
  cbi(ADCSRA,ADPS1);//0 
  cbi(ADCSRA,ADPS0);//0

  //set timer1 interrupt at 10kHz
  //KJ - this just initializes things
  TCCR1A = 0;// set entire TCCR1A register to 0
  TCCR1B = 0;// same for  TCCR1B
  TCNT1  = 0;//initialize counter value to 0;

  //KJ - assign our clock tick number assigned above to the output compare register
  //KJ - this register holds the value that will be compared against the clock count (TCNT1)
  //KJ - many things can happen when they match depending on the mode and flags that are set
  OCR1A = interrupt_Number;// Output Compare Registers 
  
  // turn on CTC mode
  //KJ - CTC is Clear Timer on Compare Match
  // in CTC mode the timer counter (TCNT1 in our case) is reset when it reaches the number of samples in the OCR1A register
  //this is used to set the sample frequency to an exact desired value
  //and generate an interrupt when the number of samples is reached
  TCCR1B |= (1 << WGM12);
  
  // Set CS11 bit for 8 prescaler
  //KJ - a prescaler value of 8 is being set which will sample at fclk/8 or fs=2x10^8 
  TCCR1B |= (1 << CS11);   
  
  // enable timer compare interrupt
  //KJ this line sets the OCIE pin for output compare register A which enables 
  //KJ - the interrupt when a match occurs
  //KJ - this indicates that an interrupt will fire when the value at OCR1A equals the nunber of ticks since the last interrupt
  TIMSK1 |= (1 << OCIE1A);

  //KJ - this enables interrupts generall by setting the interrupt flag in teh status register
  sei();//allow interrupts

    //END TIMER SETUP
    //KJ - this is the same as the line above and I have no idea what it is doing
  TIMSK1 |= (1 << OCIE1A);
}



//this is the callback function called when the interrupt fires
ISR(TIMER1_COMPA_vect) 
{
   PORTB ^= B00000100;//generate 5kHz carrier signal for AM modulation on D10 (bit 2 on port B on ATMEGA 328)
   
   if(commandMode!=1)
   {
     //Put samples in sampling buffer "reading". Since Arduino Leonardo has 10bit ADC we will split every sample to 2 bytes
     //First byte will contain 3 most significant bits and second byte will contain 7 least significat bits.
     //First bit in all byte will not be used for data but for marking begining of the frame of data (array of samples from N channels)
     //Only first byte in frame will have most significant bit set to 1
     
       //Sample first channel and put it into buffer
       tempSample = analogRead(A0);
       digitalSample1 = digitalRead(TRIGGER_PIN9);
       digitalSample2 = digitalRead(TRIGGER_PIN11);
       digitalWrite(2, digitalSample1);
       digitalWrite(3, digitalSample2);
       
       digitalOutput = (digitalSample2<<1) + digitalSample1;
       
       reading[head] =  (tempSample>>7)|0x80;//Mark begining of the frame by setting MSB to 1
       head = head+1;
       if(head==BUFFER_SIZE)
       {
         head = 0;
       }
       reading[head] =  tempSample & 0x7F;  //KJ - using the decimal 127 here as a mask to include only the lower 7 bits
       head = head+1;
       if(head==BUFFER_SIZE)
       {
         head = 0;
       }

       //KJ - might be able to just add another channel here or sample a digital channel and multiplex that into the data stream.
       reading[head] = digitalOutput;
       head += 1;  
       if(head==BUFFER_SIZE) {
        head = 0;    
       }
       
   }
   
   
}
  

//push message to main sending buffer
//timer for sampling must be dissabled when 
//we call this function
void sendMessage(const char * message)
{

  int i;
  //send escape sequence
  for(i=0;i< ESCAPE_SEQUENCE_LENGTH;i++)
  {
      reading[head++] = escapeSequence[i];
      if(head==BUFFER_SIZE)
      {
        head = 0;
      }
  }

  //send message
  i = 0;
  while(message[i] != 0)
  {
      reading[head++] = message[i++];
      if(head==BUFFER_SIZE)
      {
        head = 0;
      }
  }

  //send end of escape sequence
  for(i=0;i< ESCAPE_SEQUENCE_LENGTH;i++)
  {
      reading[head++] = endOfescapeSequence[i];
      if(head==BUFFER_SIZE)
      {
        head = 0;
      }
  }
  
}




void loop(){
    
    while(head!=tail && commandMode!=1)//While there are data in sampling buffer waiting 
    {
      Serial.write(reading[tail]);
      //Move tail for one byte
      tail = tail+1;
      if(tail>=BUFFER_SIZE)
      {
        tail = 0;
      }
    }

    if(Serial.available()>0)
    {
                  commandMode = 1;//frag that we are receiving commands through serial
                  //TIMSK1 &= ~(1 << OCIE1A);//disable timer for sampling 
                  // read untill \n from the serial port:
                  String inString = Serial.readStringUntil('\n');
                
                  //convert string to null terminate array of chars
                  inString.toCharArray(commandBuffer, SIZE_OF_COMMAND_BUFFER);
                  commandBuffer[inString.length()] = 0;
                  
                  
                  // breaks string str into a series of tokens using delimiter ";"
                  // Namely split strings into commands
                  char* command = strtok(commandBuffer, ";");
                  while (command != 0)
                  {
                      // Split the command in 2 parts: name and value
                      char* separator = strchr(command, ':');
                      if (separator != 0)
                      {
                          // Actually split the string in 2: replace ':' with 0
                          *separator = 0;
                          --separator;
                          if(*separator == 'c')//if we received command for number of channels
                          {
                            separator = separator+2;
                            numberOfChannels = 1;//atoi(separator);//read number of channels
                          }
                           if(*separator == 's')//if we received command for sampling rate
                          {
                            //do nothing. Do not change sampling rate at this time.
                            //We calculate sampling rate further below as (max Fs)/(Number of channels)
                          }

                          if(*separator == 'b')//if we received command for impuls
                          {
                            sendMessage(CURRENT_SHIELD_TYPE);
                          }
                      }
                      // Find the next command in input string
                      command = strtok(0, ";");
                  }
                  //calculate sampling rate
                  
                  //TIMSK1 |= (1 << OCIE1A);//enable timer for sampling
                  commandMode = 0;
      }
    
}
