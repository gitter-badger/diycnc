#include <PinChangeInt.h>

int Xpos = 11;
int Xneg = 10;

#define Xa A0
#define Xb A1
#define Ya A2
#define Yb A3

float kp = 0.2f;
float ki = 0.0000f;
float kd = 0.8f;

int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
//uint8_t old_AB = 0;

int8_t read_encoder(uint8_t &old_AB, int8_t a, int8_t b)
{
  int sensor1Value = digitalRead(a);
  int sensor2Value = digitalRead(b);
  uint8_t new_AB = (sensor1Value<<1)|sensor2Value;
  //uint8_t new_AB = ENC_PORT;

  old_AB <<= 2; //shift the old values up
  
  old_AB |= ( new_AB & 0x03 ); //add current state
  return ( enc_states[( old_AB & 0x0f )]);
}

int positionX = 0;
int positionY = 0;
uint8_t old_XAB, old_YAB;
int lastPosition = 0;
int destination = 0;


void doEncoder()
{
  int8_t tmpdata;
  positionX += read_encoder(old_XAB, Xa,Xb);
  positionY += read_encoder(old_YAB, Ya,Yb);
}

void setup()
{
  pinMode(2, INPUT);     
  //pinMode(5, OUTPUT);     
  pinMode(3, INPUT);     
  //pinMode(7, OUTPUT);     
  pinMode(Xpos, OUTPUT);     
  pinMode(Xneg, OUTPUT);     

  //digitalWrite(4, HIGH);
  //digitalWrite(5, HIGH);
  //digitalWrite(6, HIGH);
  //digitalWrite(7, LOW);
  digitalWrite(pos, LOW);
  digitalWrite(neg, LOW);

  Serial.begin(9600);
  delay(1000);

#if 0
  // encoder pin on interrupt 0 (pin 2)
  attachInterrupt(0, doEncoder, CHANGE);
  // encoder pin on interrupt 1 (pin 3)
  attachInterrupt(1, doEncoder, CHANGE);
#else
  PCintPort::attachInterrupt(Xa,doEncoder,CHANGE);
  PCintPort::attachInterrupt(Xb,doEncoder,CHANGE);
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
  digitalWrite( pos, LOW );
  digitalWrite( neg, LOW );
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
      kp = newAngle / 100.0f;
      ResetAngle();
    } else if( inByte == 'i' ) {
      ki = newAngle / 10000.0f;
      ResetAngle();
    } else if( inByte == 'd' ) {
      kd = newAngle / 1000.0f;
      ResetAngle();
    } else if( inByte == 'g' ) {
      destination = newAngle;
      ResetAngle();
    } else if( inByte == 'm' ) {
      motion = newAngle;
      ResetAngle();
    } else if( inByte == 'r' ) {
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

//  if( dist > 90 )
//  {
//    Speed(dir*255);
//  }
//  else
//  {
//    if( speed == 0 && dist > 10 )
//    {
//      comp += 1;
//      Speed(dir*(dist+comp));
//    }
//    else
//    {
//      comp = 0;
//      stop();
//    }
//  }

  
  lastPosition = positionX;
  ++frame;
  if( ( frame & 31 ) == 0 )
  {
    char buffer[ 24 ];
    sprintf( buffer, "%5i %4i  -> %5i : %5i %2i", positionX, speed, destination, dist, dir );
    Serial.println(buffer);
  }
  //Serial.println(old_AB, DEC);
  delay(5);
}


