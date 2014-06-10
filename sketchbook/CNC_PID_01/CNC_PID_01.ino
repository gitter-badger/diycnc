#include <Servo.h>
#include <PinChangeInt.h>
float kp = 0.2f;
float ki = 0.0000f;
float kd = 0.8f;

int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
uint8_t old_values = 0;

struct MotorPinPair {
  int a,b;
};

struct D3 {
  int8_t x,y,z;
};

struct V3 {
  long x,y,z;
};

D3 m;

uint32_t read_encoder()
{
  uint8_t new_values = PINC;
  m.x = -enc_states[((3&old_values)<<2)|(3&new_values)];
  m.y = enc_states[(((12&old_values)<<2)|(12&new_values))>>2];
  m.z = enc_states[(((48&old_values)<<2)|(48&new_values))>>4];
  old_values = new_values;
  return 1;
}

V3 motorPos;
V3 destination;

void doEncoder() {
  int8_t tmpdata;
  read_encoder();
  motorPos.x += m.x;
  motorPos.y += m.y;
  motorPos.z += m.z;
}

#define Xneg 3
#define Xpos 5
#define Yneg 6
#define Ypos 9
#define Zneg 10
#define Zpos 11

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
}
void Stop( int axis ) {
  long *pos = &motorPos.x;
  long *val = &destination.x;
  val[axis] = pos[axis];
}
V3 operator-( const V3 &a, const V3 &b ) {
  V3 v;
  v.x = a.x - b.x;
  v.y = a.y - b.y;
  v.z = a.z - b.z;
  return v;
}
V3 operator+( const V3 &a, const V3 &b ) {
  V3 v;
  v.x = a.x + b.x;
  v.y = a.y + b.y;
  v.z = a.z + b.z;
  return v;
}

V3 lastPos;
V3 I;

void UpdatePID() {
  V3 dist = destination - motorPos;
  V3 speed = motorPos - lastPos;
  I = I + dist;
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
}

const int max_vel = 720;

struct Motor {
  Motor( int _axis ) : axis(_axis) {
    vel = max_vel;
    Reset();
  }
  void Setup() {
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
  bool Arrived() {
    if( inMotion ) {
      if( Idle() ) {
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

struct Spindle {
  Spindle( int signal ) : s(signal) {
  }
  void Setup()
  {
    pinMode( s, OUTPUT );
    digitalWrite( s, LOW );
  }
  void On() { digitalWrite(s,1); }
  void Off() { digitalWrite(s,0); }
  int s;
 };

Motor m1(0); ///x
Motor m2(1); ///y
Motor m3(2); ///z
Spindle s1(7); /// cutter


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
  
  m1.Setup();
  m2.Setup();
  m3.Setup();
  s1.Setup();
  
  Serial.begin(9600);
  delay(1000);
}
int frame = 0;
void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    inByte = Serial.read();
    if( inByte == 'x' ) {
      newXAngle = getFinalAngle();
    } else if( inByte == 'C' ) {
      s1.On();
    } else if( inByte == 'c' ) {
      s1.Off();
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
    } else if( inByte == '.' ) {
      newAngleDecimal = 1;
    } else if( inByte == '-' ) {
      negative = true;
    } else if( inByte == 'g' ) {
      m1.Go(newXAngle);
      m2.Go(newZAngle);
      m3.Go(newYAngle);
    } else if( inByte == 'h' ) {
      s1.Off();
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
    } else if( inByte == 's' ) {
      if( m1.Idle() )
        Serial.write("x");
      if( m2.Idle() )
        Serial.write("z");
      if( m3.Idle() )
        Serial.write("y");
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

  if( m1.Arrived() )
    Serial.write("x");
  if( m2.Arrived() )
    Serial.write("z");
  if( m3.Arrived() )
    Serial.write("y");
  delayMicroseconds(200);
}
