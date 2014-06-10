#include <PinChangeInt.h>

int Xpos = 11;
int Xneg = 10;

float kp = 0.2f;
float ki = 0.0000f;
float kd = 0.8f;

int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
uint8_t old_values = 0;

struct Motion {
  int8_t x,y,z;
} m;

uint32_t read_encoder()
{
  uint8_t new_values = PINC;
  m.x = -enc_states[((3&old_values)<<2)|(3&new_values)];
  m.y = enc_states[(((12&old_values)<<2)|(12&new_values))>>2];
  m.z = enc_states[(((48&old_values)<<2)|(48&new_values))>>4];
  old_values = new_values;
  return 1;
}

int positionX = 0;
int positionY = 0;
int positionZ = 0;
int lastPosition = 0;
int destination = 0;


void doEncoder()
{
  int8_t tmpdata;
  //Motion m =
  read_encoder();
  positionX += m.x;
  positionY += m.y;
  positionZ += m.z;
}

void setup()
{
  pinMode(2, INPUT);     
  pinMode(3, INPUT);     
  pinMode(Xpos, OUTPUT);     
  pinMode(Xneg, OUTPUT);     

  digitalWrite(Xpos, LOW);
  digitalWrite(Xneg, LOW);

  Serial.begin(9600);
  delay(1000);

#if 0
  // encoder pin on interrupt 0 (pin 2)
  attachInterrupt(0, doEncoder, CHANGE);
  // encoder pin on interrupt 1 (pin 3)
  attachInterrupt(1, doEncoder, CHANGE);
#else
  PCintPort::attachInterrupt(A0,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A1,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A2,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A3,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A4,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A5,doEncoder,CHANGE);
#endif
}

static int state = 0;

void Speed( int v ) {
  if( v > 0 ) {
    digitalWrite(Xpos,LOW);
    analogWrite(Xneg,v);
  } else {
    v = -v;
    digitalWrite(Xneg,LOW);
    analogWrite(Xpos,v);
  }
}
void Speed2( float v ) {
  if( v > 1.0f )
    Speed( 255 );
  else if( v < -1.0f )
    Speed( -255 );
  else
    Speed( 255 * v );
}

void stop()
{
  digitalWrite( Xpos, LOW );
  digitalWrite( Xneg, LOW );
}

int neg = 1;
int newAngle = 0;
void ResetAngle() {
  neg = 1;
  newAngle = 0;
}
int frame = 0;
int comp = 0;
int I = 0;
int motion = 0;
void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
    Serial.print("rec:");
    Serial.println(inByte, DEC);
    if( inByte == 'p' ) {
      kp = neg*newAngle / 100.0f;
      ResetAngle();
    } else if( inByte == 'i' ) {
      ki = neg*newAngle / 10000.0f;
      ResetAngle();
    } else if( inByte == 'd' ) {
      kd = neg*newAngle / 1000.0f;
      ResetAngle();
    } else if( inByte == 'g' ) {
      destination = neg*newAngle;
      ResetAngle();
    } else if( inByte == 'm' ) {
      motion = neg*newAngle;
      ResetAngle();
    } else if( inByte == 'r' ) {
      destination = 0;
      positionX = 0;
    } else if( inByte == '-' ) {
      neg = -neg;
    } else {
      int dec = inByte-'0';
      newAngle *= 10;
      newAngle += dec;
    }
  }
  
  destination += motion;

  int dir = 0;
  int dist = dist = destination - positionX;
  int speed = positionX - lastPosition;
  I += dist;

  float PID = kp * dist + ki * I - kd * speed;
    
  if( destination > positionX )
  {
    dir = 1;
  }
  
  if( destination < positionX )
  {
    dir = -1;
    dist = -dist;
    speed = -speed;
  }
  
  Speed2( PID );
  
  lastPosition = positionX;
  ++frame;
  if( ( frame & 31 ) == 0 )
  {
    char buffer[ 24 ];
    //sprintf( buffer, "%5i %4i  -> %5i : %5i %2i", positionX, speed, destination, dist, dir );
    sprintf( buffer, "%5i %5i %5i  %x %x",
      positionX, positionY, positionZ, old_values, PINC );
    Serial.println(buffer);
  }
  //Serial.println(old_AB, DEC);
  delay(5);
}


