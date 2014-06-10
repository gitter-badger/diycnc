#define SPINDLE 7
#define Xneg 6
#define Xpos 9
#define Yneg 5
#define Ypos 3
#define Zneg 10
#define Zpos 11
#define COMSPEED 19200

#include <PinChangeInt.h>

float kp = 0.2f;
float ki = 0.0000f;
float kd = 0.8f;

int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
uint8_t old_values = 0;

struct MotorPinPair { int a,b; };
struct D3 { int8_t x,y,z; };
struct V3 { long x,y,z; };
V3 operator-( const V3 &a, const V3 &b ) {
  V3 v = { a.x-b.x, a.y-b.y, a.z-b.z };
  return v;
}
V3 operator+( const V3 &a, const V3 &b ) {
  V3 v = { a.x+b.x, a.y+b.y, a.z+b.z };
  return v;
}
V3 operator+( const V3 &a, const D3 &b ) {
  V3 v = { a.x+b.x, a.y+b.y, a.z+b.z };
  return v;
}

D3 m;

void read_encoder() {
  uint8_t new_values = PINC;
  m.x = enc_states[(((12&old_values)<<2)|(12&new_values))>>2];
  m.y = enc_states[((3&old_values)<<2)|(3&new_values)];
  m.z = enc_states[(((48&old_values)<<2)|(48&new_values))>>4];
  old_values = new_values;
}

V3 motorPos, destination;

void doEncoder() {
  int8_t tmpdata;
  read_encoder();
  motorPos = motorPos + m;
}

MotorPinPair motorPins[3] = { { Xpos, Xneg }, { Ypos, Yneg }, { Zpos, Zneg } };

void SetupMotorOutputs() {
  for( int i = 0; i < 3; ++i ) {
    pinMode(motorPins[i].a, OUTPUT);
    pinMode(motorPins[i].b, OUTPUT);
    digitalWrite(motorPins[i].a, LOW);
    digitalWrite(motorPins[i].b, LOW);
  }
}

void Speed( int axis, int v ) {
  if( v > 0 ) {
    digitalWrite(motorPins[axis].a,LOW);
    analogWrite(motorPins[axis].b,v);
  } else {
    v = -v;
    analogWrite(motorPins[axis].a,v);
    digitalWrite(motorPins[axis].b,LOW);
  }
}
void Speed2( int axis, float v ) {
  if( v > 1.0f )
    Speed( axis, 255 );
  else if( v < -1.0f )
    Speed( axis, -255 );
  else
    Speed( axis, 255 * v );
}

void stop( int axis )
{
  digitalWrite(motorPins[axis].a,LOW);
  digitalWrite(motorPins[axis].b,LOW);
}

void SetPos( int axis, long dest ) {
  long *val = &destination.x;
  val[axis] = dest;
#if 0
  char buffer[128];
  sprintf( buffer, "Set(%i)%5i", axis, dest ); Serial.println(buffer);
  sprintf( buffer, "Post set %li,%li,%li", destination.x, destination.y, destination.z ); Serial.println(buffer);
#endif
}
int Reached( int axis ) {
  long *pos = &motorPos.x;
  long *val = &destination.x;
  unsigned int dist = val[axis] - pos[axis];
  if( dist < 10 )
    return 1;
  return 0;
}
void Stop( int axis ) {
  long *pos = &motorPos.x;
  long *val = &destination.x;
  //val[axis] = pos[axis];
}

V3 lastPos;
//V3 lastDest;
V3 I;
#define Iclamp 10000
float lastPIDx;
inline void clamp(long &v, long low, long high ) {
  v = v > high ? high : v < low ? low : v;
}
V3 zeroV;
void ResetPID() {
  motorPos = zeroV;
  lastPos = zeroV;
  destination = zeroV;
  I = zeroV;
}
void UpdatePID() {
  V3 dist = destination - motorPos;
  V3 speed = motorPos - lastPos;
  //V3 controlDiff = destination - lastDest;
  //lastDest = destination;
  
  I = I + dist;
  I = I;// + controlDiff - speed;
  clamp( I.x, -Iclamp, Iclamp );
  clamp( I.y, -Iclamp, Iclamp );
  clamp( I.z, -Iclamp, Iclamp );
  int dir = 0;
  float PID = kp * dist.x + ki * I.x - kd * speed.x;
  if( dist.x > 0 )
    dir = 1;
  if( dist.x < 0 ) {
    dir = -1;
    dist.x = -dist.x;
    speed.x = -speed.x;
  }
  Speed2(0, PID );
#if 0
  static long lastPrint = 0;
  if( millis() - lastPrint > 4000 ) {
    lastPrint = millis();
    char buffer[128];
    sprintf( buffer, "PID %i->%i P%i I%i D%i -> %i",
      (int)motorPos.x, (int)destination.x,
      (int)dist.x, (int)I.x, (int)speed.x,
      (int)(PID * 1000)
      ); Serial.println(buffer);
  }
#endif
  // y axis
  dir = 0;
  PID = kp * dist.y + ki * I.y - kd * speed.y;
  if( dist.y > 0 )
    dir = 1;
  if( dist.y < 0 ) {
    dir = -1;
    dist.y = -dist.y;
    speed.y = -speed.y;
  }
  Speed2(1, PID );
  // z axis
  dir = 0;
  PID = kp * dist.z + ki * I.z - kd * speed.z;
  if( dist.z > 0 )
    dir = 1;
  if( dist.z < 0 ) {
    dir = -1;
    dist.z = -dist.z;
    speed.z = -speed.z;
  }
  Speed2(2, PID );
  
  lastPos = motorPos;
}

const int max_vel = 1200;

struct Motor {
  Motor( int _axis ) : axis(_axis) {
    vel = max_vel;
    Reset();
  }
  void Reset() {
    pos = dest = start = 0;
    vel = max_vel;
    inMotion = false;
  }
  void Go( long destination ) {
    if( destination != pos ) {
      int currentDir = 0;
      start = pos;
      dest = destination;
      if( start < dest ) { total = dest - start; currentDir = 1; }
      else { total = start - dest; currentDir = -1; }
      lastTime = micros();
      inMotion = true;
    }
  }
  bool Idle() { return pos == dest; }
  bool AtDest() {
    return Idle() && Reached( axis );
  }
  bool Arrived() {
    if( inMotion ) {
      if( Idle() && Reached( axis ) ) {
        inMotion = false;
        return true;
      }
    }
    return false;
  }
  
  void Update() {
    if( dest != pos ) {
      long ms = micros() - lastTime;
      long d = ms / 1000 * vel / 1000;
      if( d >= total ) {
        pos = dest;
      } else {
        if( dest > start )
          pos = start + d;
	else
	  pos = start - d;
      }
      SetPos( axis, pos );
    } else {
      Stop( axis );
    }
  }
    
  const int axis;
  long pos;
  long start;
  long dest;
  long vel;
  long total;
  long lastTime;
  bool inMotion;
};

Motor m1(0); ///x
Motor m2(1); ///y
Motor m3(2); ///z

long newAngleDecimal = 0;
long newAngle = 0;
long newXAngle = 0;
long newYAngle = 0;
long newZAngle = 0;
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

void setup()
{
  SetupMotorOutputs();

  PCintPort::attachInterrupt(A0,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A1,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A2,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A3,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A4,doEncoder,CHANGE);
  PCintPort::attachInterrupt(A5,doEncoder,CHANGE);
    
  Serial.begin(COMSPEED);
  delay(1000);
}
int frame = 0;
void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    inByte = Serial.read();
    if( inByte == 'C' ) {
      digitalWrite(SPINDLE,1);
    } else if( inByte == 'c' ) {
      digitalWrite(SPINDLE,0);
    } else if( inByte == 'x' ) {
      newXAngle = getFinalAngle();
    } else if( inByte == 'y' ) {
      newYAngle = getFinalAngle();
    } else if( inByte == 'z' ) {
      newZAngle = getFinalAngle();
    } else if( inByte == 'X' ) {
      m1.vel = getFinalAngle();
    } else if( inByte == 'Y' ) {
      m2.vel = getFinalAngle();
    } else if( inByte == 'Z' ) {
      m3.vel = getFinalAngle();
    } else if( inByte == 'g' ) {
      m1.Go(newXAngle);
      m2.Go(newYAngle);
      m3.Go(newZAngle);
    } else if( inByte == 'h' ) {
      digitalWrite(SPINDLE,0);
      m1.vel = max_vel;
      m2.vel = max_vel;
      m3.vel = max_vel;
      m1.Go(0);
      m2.Go(0);
      m3.Go(0);
      newXAngle = newYAngle = newZAngle = 0;
    } else if( inByte == 'r' ) {
      m1.Reset();
      m2.Reset();
      m3.Reset();
      newXAngle=0;
      newZAngle=0;
      newYAngle=0;
      ResetPID();
    } else if( inByte == 's' ) {
      if( m1.Idle() )
        Serial.write("x");
      if( m2.Idle() )
        Serial.write("y");
      if( m3.Idle() )
        Serial.write("z");
    } else if( inByte == '.' ) {
      newAngleDecimal = 1;
    } else if( inByte == '-' ) {
      negative = true;
    } else {
      if( newAngleDecimal == 0 ) {
        int dec = inByte-'0';
        newAngle *= 10;
        //newAngleDecimal *= 10;
        newAngle += dec;
      }
    }
  }
  
  m1.Update();
  m2.Update();
  m3.Update();

  UpdatePID();

#if 0
  static long lastPrint = 0;
  if( millis() - lastPrint > 4000 ) {
    lastPrint = millis();
    Serial.println("Report");
    char buffer[128];
    sprintf( buffer, "X %5li -> %5li", motorPos.x, destination.x ); Serial.println(buffer);
    sprintf( buffer, "Y %5li -> %5li", motorPos.y, destination.y ); Serial.println(buffer);
    sprintf( buffer, "Z %5li -> %5li", motorPos.z, destination.z ); Serial.println(buffer);
    sprintf( buffer, "PID %i", (int)(10000*lastPIDx) ); Serial.println(buffer);
  }
#endif

  if( m1.Arrived() )
    Serial.write("x");
  if( m2.Arrived() )
    Serial.write("y");
  if( m3.Arrived() )
    Serial.write("z");
  delayMicroseconds(1000);
}
