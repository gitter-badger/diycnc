#include <PID_v1.h>

double aggKp=4, aggKi=0.2, aggKd=1;
double consKp=1, consKi=0.05, consKd=0.25;
double origKp=2, origKi=5.0, origKd=1;

double custKp=2, custKi=5, custKd=1;

double xSetpoint, xInput, xOutput;
double ySetpoint, yInput, yOutput;
double zSetpoint, zInput, zOutput;
PID xPID(&xInput, &xOutput, &xSetpoint,aggKp,aggKi,aggKd, DIRECT);
PID yPID(&yInput, &yOutput, &ySetpoint,aggKp,aggKi,aggKd, DIRECT);
PID zPID(&zInput, &zOutput, &zSetpoint,aggKp,aggKi,aggKd, DIRECT);

void SetAgg()
{
  xPID.SetTunings(aggKp,aggKi,aggKd);
  yPID.SetTunings(aggKp,aggKi,aggKd);
  zPID.SetTunings(aggKp,aggKi,aggKd);
}
void SetCon()
{
  xPID.SetTunings(consKp,consKi,consKd);
  yPID.SetTunings(consKp,consKi,consKd);
  zPID.SetTunings(consKp,consKi,consKd);
}
void SetCust()
{
  xPID.SetTunings(custKp,custKi,custKd);
  yPID.SetTunings(custKp,custKi,custKd);
  zPID.SetTunings(custKp,custKi,custKd);
}

const int m1A = 3;
const int m1B = 2;
const int m2A = 21;
const int m2B = 20;
const int m3A = 18;
const int m3B = 19;

const int m1F = 7;
const int m1R = 6;
const int m2F = 15;
const int m2R = 14;
const int m3F = 5;
const int m3R = 4;

const int GND = 17;
const int VSS = 16;

const int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};

uint8_t old_AB1 = 0;
uint8_t old_AB2 = 0;
uint8_t old_AB3 = 0;

int8_t read_encoder1()
{
  int8_t s1 = digitalRead(m1A);
  int8_t s2 = digitalRead(m1B);
  uint8_t new_AB1 = (s1<<1)|s2;
  old_AB1 = (old_AB1 << 2) | ( new_AB1 & 0x03 ); //add current state
  return ( enc_states[( old_AB1 & 0x0f )]);
}

int8_t read_encoder2()
{
  int8_t s1 = digitalRead(m2A);
  int8_t s2 = digitalRead(m2B);
  uint8_t new_AB2 = (s1<<1)|s2;
  old_AB2 = (old_AB2 << 2) | ( new_AB2 & 0x03 ); //add current state
  return ( enc_states[( old_AB2 & 0x0f )]);
}

int8_t read_encoder3()
{
  int8_t s1 = digitalRead(m3A);
  int8_t s2 = digitalRead(m3B);
  uint8_t new_AB3 = (s1<<1)|s2;
  old_AB3 = (old_AB3 << 2) | ( new_AB3 & 0x03 ); //add current state
  return ( enc_states[( old_AB3 & 0x0f )]);
}

int pos1 = 0, pos2 = 0, pos3 = 0;
int dest1 = 0, dest2 = 0, dest3 = 0;

void doEncoder1() { pos1 += read_encoder1(); }
void doEncoder2() { pos2 += read_encoder2(); }
void doEncoder3() { pos3 += read_encoder3(); }

void setup()
{
  pinMode(m1A, INPUT);     
  pinMode(m1B, INPUT);     
  pinMode(m2A, INPUT);     
  pinMode(m2B, INPUT);     
  pinMode(m3A, INPUT);     
  pinMode(m3B, INPUT);     

  pinMode(m1F, OUTPUT);     
  pinMode(m1R, OUTPUT);     
  pinMode(m2F, OUTPUT);     
  pinMode(m2R, OUTPUT);     
  pinMode(m3F, OUTPUT);     
  pinMode(m3R, OUTPUT);     


  pinMode(GND, OUTPUT);     
  pinMode(VSS, OUTPUT);     
  digitalWrite(GND, LOW);     
  digitalWrite(VSS, HIGH);     

  Serial.begin(38400);
  delay(1000);

  // encoder pin on interrupt 0 (pin 2)
  attachInterrupt(0, doEncoder1, CHANGE);
  attachInterrupt(1, doEncoder1, CHANGE);
  attachInterrupt(2, doEncoder2, CHANGE);
  attachInterrupt(3, doEncoder2, CHANGE);
  attachInterrupt(4, doEncoder3, CHANGE);
  attachInterrupt(5, doEncoder3, CHANGE);
  
  xInput = pos1;
  yInput = pos2;
  zInput = pos3;
  xSetpoint = 0;
  ySetpoint = 0;
  zSetpoint = 0;
  xPID.SetOutputLimits(-1.0,1.0);
  xPID.SetSampleTime(2);
  xPID.SetMode(AUTOMATIC);
  yPID.SetOutputLimits(-1.0,1.0);
  yPID.SetSampleTime(2);
  yPID.SetMode(AUTOMATIC);
  zPID.SetOutputLimits(-1.0,1.0);
  zPID.SetSampleTime(2);
  zPID.SetMode(AUTOMATIC);
}

static int state = 0;
int frame = 0;

//void M1F( char amount ) { analogWrite( m1F, amount ); digitalWrite( m1R, LOW  ); }
//void M1R( char amount ) { digitalWrite( m1F, LOW  ); analogWrite( m1R, amount ); }
//void M1S() { digitalWrite( m1F, LOW ); digitalWrite( m1R, LOW ); }
//void M2F(char amount) { analogWrite( m2F, amount ); digitalWrite( m2R, LOW  ); }
//void M2R(char amount) { digitalWrite( m2F, LOW  ); analogWrite( m2R, amount ); }
//void M2S() { digitalWrite( m2F, LOW ); digitalWrite( m2R, LOW ); }

void M1F() { digitalWrite( m1F, HIGH ); digitalWrite( m1R, LOW  ); }
void M1R() { digitalWrite( m1F, LOW  ); digitalWrite( m1R, HIGH ); }
void M1S() { digitalWrite( m1F, LOW ); digitalWrite( m1R, LOW ); }
void M2F() { digitalWrite( m2F, HIGH ); digitalWrite( m2R, LOW  ); }
void M2R() { digitalWrite( m2F, LOW  ); digitalWrite( m2R, HIGH ); }
void M2S() { digitalWrite( m2F, LOW ); digitalWrite( m2R, LOW ); }
void M3F() { digitalWrite( m3F, HIGH ); digitalWrite( m3R, LOW  ); }
void M3R() { digitalWrite( m3F, LOW  ); digitalWrite( m3R, HIGH ); }
void M3S() { digitalWrite( m3F, LOW ); digitalWrite( m3R, LOW ); }

void M1F(unsigned char amount) { if( amount > (frame&255) ) M1F(); else M1S(); }
void M1R(unsigned char amount) { if( amount > (frame&255) ) M1R(); else M1S(); }
void M2F(unsigned char amount) { if( amount > (frame&255) ) M2F(); else M2S(); }
void M2R(unsigned char amount) { if( amount > (frame&255) ) M2R(); else M2S(); }
void M3F(unsigned char amount) { if( amount > (frame&255) ) M3F(); else M3S(); }
void M3R(unsigned char amount) { if( amount > (frame&255) ) M3R(); else M3S(); }


int newAngleDecimal = 0;
int newAngle = 0;
int newXAngle = 0;
int newYAngle = 0;
int newZAngle = 0;
bool negative = false;

float getFinalAngle()
{
  float angle = newAngle;
  if( newAngleDecimal )
    angle /= newAngleDecimal;
  if(negative)
    angle *= -1.0;
  newAngle = 0; negative = false; newAngleDecimal = 0;
  return angle;
}


void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
    //Serial.print("rec:");
    //Serial.println(inByte, DEC);
    if( inByte == 'x' ) {
      newXAngle = getFinalAngle();
    } else if( inByte == 'y' ) {
      newYAngle = getFinalAngle();
    } else if( inByte == 'z' ) {
      newZAngle = getFinalAngle();
    } else if( inByte == '.' ) {
      newAngleDecimal = 1;
    } else if( inByte == '-' ) {
      negative = true;
    } else if( inByte == 'p' ) {
      custKp = getFinalAngle();
      SetCust();
    } else if( inByte == 'i' ) {
      custKi = getFinalAngle();
      SetCust();
    } else if( inByte == 'd' ) {
      custKd = getFinalAngle();
      SetCust();
    } else if( inByte == 'f' ) {
      SetCon();
    } else if( inByte == 'c' ) {
      SetAgg();
    } else if( inByte == 'g' ) {
      dest1 = newXAngle;
      dest2 = newYAngle;
      dest3 = newZAngle;
    } else if( inByte == 'h' ) {
      dest1 = newXAngle = 0;
      dest2 = newYAngle = 0;
      dest3 = newZAngle = 0;
    } else if( inByte == 'r' ) {
      getFinalAngle();
      dest1 = 0; dest2 = 0; dest3 = 0;
      pos1 = 0; pos2 = 0; pos3 = 0;
      newXAngle = 0; newYAngle = 0; newZAngle = 0;
    } else {
      int dec = inByte-'0';
      newAngle *= 10;
      newAngleDecimal *= 10;
      newAngle += dec;
    }
  }

  xSetpoint = dest1;
  ySetpoint = dest2;
  zSetpoint = dest3;
  xInput = pos1;
  yInput = pos2;
  zInput = pos3;
  xPID.Compute();
  yPID.Compute();
  zPID.Compute();
  
  if( xOutput > 0.05 )
     M1F((unsigned char)(xOutput * 255));
  else if( xOutput < -0.05 )
     M1R((unsigned char)(-xOutput * 255));
  else
    M1S();
  if( yOutput > 0.05 )
     M2F((unsigned char)(yOutput * 255));
  else if( yOutput < -0.05 )
     M2R((unsigned char)(-yOutput * 255));
  else
    M2S();
  if( zOutput > 0.05 )
     M3F((unsigned char)(zOutput * 255));
  else if( zOutput < -0.05 )
     M3R((unsigned char)(-zOutput * 255));
  else
    M3S();
  
  ++frame;
  char buffer[ 24 ];
  if( ( frame & 255 ) == 0 )
  {
    sprintf( buffer, "%5i,%5i,%5i", pos1, pos2, pos3 );
    Serial.println(buffer);
  }
  delay(2);
}

