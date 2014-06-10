#include <Servo.h> 

struct Spindle {
  Spindle( int signal, int ground ) : dest(90), curr(90), g(ground), s(signal) {
  }
  void Setup()
  {
    pinMode( g, OUTPUT );
    digitalWrite( g, LOW );
    pinMode( s, OUTPUT );
    digitalWrite( s, LOW );
    servo.attach( s );
    servo.write( 90 );    
  }
  void On() { dest = 100; }//servo.write( 120 ); }
  void Off() { dest = 90; }//servo.write( 90 ); }
  void Update()
  {
    if( dest != curr )
    {
      if( dest < curr )
      {
        --curr;
      }
      else
      {
        ++curr;
      }
      servo.write( curr );
    }
  }
  int dest,curr;
  int g,s;
  Servo servo;
};

Spindle s1(10,11); /// cutter

void setup()
{
  Serial.begin(19200);
  s1.Setup();
  delay(1000);
}
int frame = 0;
void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    inByte = Serial.read();
    if( inByte == 'C' ) {
      s1.On();
    } else if( inByte == 'c' ) {
      s1.Off();
    }
  }
  s1.Update();
  delayMicroseconds(200);
}

