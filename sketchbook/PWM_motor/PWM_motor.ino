/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 13 has an LED connected on most Arduino boards.
// give it a name:
int led = 10;
int led2 = 11;

// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  pinMode(led, OUTPUT);     
  pinMode(led2, OUTPUT);     
}

void Speed( int v ) {
  if( v > 0 ) {
    digitalWrite(led,LOW);
    analogWrite(led2,v);
  } else {
    v = -v;
    digitalWrite(led2,LOW);
    analogWrite(led,v);
  }
}
// the loop routine runs over and over again forever:
int s = 0;
int d = 1;
void loop() {
  s = s + d;
  Speed( s );
  if( s >= 255 || s <= -255 )
    d = -d;
  delay(20);               // wait for a second
}
