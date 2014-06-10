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
int ls1 = 0, ls2 = 0, ls3 = 0;
int lpos1 = 0, lpos2 = 0, lpos3 = 0;
int dest1 = 0, dest2 = 0, dest3 = 0;
int start1 = 0, start2 = 0, start3 = 0;

void doEncoder1()
{
  int8_t tmpdata = read_encoder1();
  if( tmpdata ) pos1 += tmpdata;
}
void doEncoder2()
{
  int8_t tmpdata = read_encoder2();
  if( tmpdata ) pos2 += tmpdata;
}
void doEncoder3()
{
  int8_t tmpdata = read_encoder3();
  if( tmpdata ) pos3 += tmpdata;
}

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
}

static int state = 0;

void M1F() { digitalWrite( m1F, HIGH ); digitalWrite( m1R, LOW  ); }
void M1R() { digitalWrite( m1F, LOW  ); digitalWrite( m1R, HIGH ); }
void M1S() { digitalWrite( m1F, HIGH ); digitalWrite( m1R, HIGH ); }
void M2F() { digitalWrite( m2F, HIGH ); digitalWrite( m2R, LOW  ); }
void M2R() { digitalWrite( m2F, LOW  ); digitalWrite( m2R, HIGH ); }
void M2S() { digitalWrite( m2F, HIGH ); digitalWrite( m2R, HIGH ); }
void M3F() { digitalWrite( m3F, HIGH ); digitalWrite( m3R, LOW  ); }
void M3R() { digitalWrite( m3F, LOW  ); digitalWrite( m3R, HIGH ); }
void M3S() { digitalWrite( m3F, HIGH ); digitalWrite( m3R, HIGH ); }

int frame = 0;

void M1( int dir ) {
  switch( dir ) {
    case 0: M1S(); return;
    case 1: M1F(); return;
    case -1: M1R(); return;
  }
}
void M2( int dir ) {
  switch( dir ) {
    case 0: M2S(); return;
    case 1: M2F(); return;
    case -1: M2R(); return;
  }
}
void M3( int dir ) {
  switch( dir ) {
    case 0: M3S(); return;
    case 1: M3F(); return;
    case -1: M3R(); return;
  }
}

int newAngle = 0;
int newXAngle = 0;
int newYAngle = 0;
int newZAngle = 0;
bool negative = false;

int slowzone = 90;
int nearEnough = 5;

void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
    Serial.print("rec:");
    Serial.println(inByte, DEC);
    if( inByte == 'x' ) {
      newXAngle = negative?-newAngle:newAngle;
      newAngle = 0; negative = false;
    } else if( inByte == 'y' ) {
      newYAngle = negative?-newAngle:newAngle;
      newAngle = 0; negative = false;
    } else if( inByte == 'z' ) {
      newZAngle = negative?-newAngle:newAngle;
      newAngle = 0; negative = false;
    } else if( inByte == '-' ) {
      negative = true;
    } else if( inByte == 'f' ) {
      nearEnough = 3;
    } else if( inByte == 'c' ) {
      nearEnough = 10;
    } else if( inByte == 'g' ) {
      dest1 = newXAngle;
      dest2 = newYAngle;
      dest3 = newZAngle;
      start1 = pos1;
      start2 = pos2;
      start3 = pos3;
    } else if( inByte == 'h' ) {
      dest1 = newXAngle = 0;
      dest2 = newYAngle = 0;
      dest3 = newZAngle = 0;
      start1 = pos1;
      start2 = pos2;
      start3 = pos3;
    } else if( inByte == 'r' ) {
      dest1 = 0; dest2 = 0; dest3 = 0;
      start1 = 0; start2 = 0; start3 = 0;
      pos1 = 0; pos2 = 0; pos3 = 0;
      lpos1 = 0; lpos2 = 0; lpos3 = 0;
      newXAngle = 0; newYAngle = 0; newZAngle = 0;
      newAngle = 0; negative = false;
    } else {
      int dec = inByte-'0';
      newAngle *= 10;
      newAngle += dec;
    }
  }

  int speed = 0;
  int dir = 0;
  int dist = 0;
    
  if( dest1 > pos1 ) {
    dir = 1; dist = dest1 - pos1; speed = pos1 - lpos1;
  }
  if( dest1 < pos1 ) {
    dir = -1; dist = pos1 - dest1; speed = lpos1 - pos1;
  }  
  if( dist < nearEnough )
    dir = 0;
  if( dist <= slowzone && ( (speed > 0) || (ls1 > 0) ) )
    dir = 0;
  M1(dir);
  ls1 = speed;

  if( dest2 > pos2 ) {
    dir = 1; dist = dest2 - pos2; speed = pos2 - lpos2;
  }
  if( dest2 < pos2 ) {
    dir = -1; dist = pos2 - dest2; speed = lpos2 - pos2;
  }  
  if( dist < nearEnough )
    dir = 0;
  if( dist <= slowzone && ( (speed > 0) || (ls2 > 0) )  )
    dir = 0;
  M2(dir);
  ls2 = speed;
  
  if( dest3 > pos3 ) {
    dir = 1; dist = dest3 - pos3; speed = pos3 - lpos3;
  }
  if( dest3 < pos3 ) {
    dir = -1; dist = pos3 - dest3; speed = lpos3 - pos3;
  }  
  if( dist < nearEnough )
    dir = 0;
  if( dist <= slowzone && ( (speed != 0) || (ls3 != 0) )  )
    dir = 0;
  M3(dir);
  ls3 = speed;
  
  lpos1 = pos1;
  lpos2 = pos2;
  lpos3 = pos3;
  ++frame;
  char buffer[ 24 ];
  if( ( frame & 63 ) == 0 )
  {
    sprintf( buffer, "%5i,%5i,%5i", pos1, pos2, pos3 );
    Serial.println(buffer);
  }
  delay(2);
}

