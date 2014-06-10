const int aval[] = { 1,1,1,0,0,0,0,0 };
const int bval[] = { 0,0,0,0,1,1,1,0 };
const int cval[] = { 0,0,1,1,1,0,0,0 };
const int dval[] = { 1,0,0,0,0,0,1,1 };

const int max_vel = 500;

struct Motor
{
  Motor( int _a, int _b, int _c, int _d ) : a(_a), b(_b), c(_c), d(_d)
  {
    vel = max_vel;
    Reset();
  }
  void Setup()
  {
    pinMode(a, OUTPUT); pinMode(b, OUTPUT); pinMode(c, OUTPUT); pinMode(d, OUTPUT);
    digitalWrite(a, LOW); digitalWrite(b, LOW); digitalWrite(c, LOW); digitalWrite(d, LOW);
  }
  void Reset()
  {
    pos = dest = start = 0;
    vel = max_vel;
    inMotion = false;
  }
  void Go( int destination )
  {
    start = pos;
    dest = destination;
    if( start < dest ) total = dest - start;
    else total = start - dest;
    lastTime = micros();
    inMotion = total > 0;
  }
  bool Idle() { return pos == dest; }
  bool Arrived()
  {
    if( inMotion )
    {
      if( Idle() )
      {
        inMotion = false;
        return true;
      }
    }
    return false;
  }
  
  void Update()
  {
    if( dest != pos )
    {
      long ms = micros() - lastTime;
      long d = ms / 1000 * vel / 1000;
      if( d >= total )
      {
        pos = dest;
      }
      else
      {
        if( dest > start )
          pos = start + d;
        else
          pos = start - d;
      }
      setpos( pos );
    }
    else
    {
      setIdle();
    }
  }
  
  void setpos( int oct )
  {
    oct = oct&7;  
    if( aval[oct] ) digitalWrite( a, HIGH );
    else digitalWrite( a, LOW );
    if( bval[oct] ) digitalWrite( b, HIGH );
    else digitalWrite( b, LOW );
    if( cval[oct] ) digitalWrite( c, HIGH );
    else digitalWrite( c, LOW );
    if( dval[oct] ) digitalWrite( d, HIGH );
    else digitalWrite( d, LOW );
  }
  void setIdle()
  {
    digitalWrite( a, LOW );
    digitalWrite( b, LOW );
    digitalWrite( c, LOW );
    digitalWrite( d, LOW );
  }
  
  const int a, b, c, d;
  long pos;
  long start;
  long dest;
  long vel;
  long total;
  long lastTime;
  bool inMotion;
};

Motor m1(2,3,4,5);
Motor m2(6,7,8,9);
Motor m3(10,11,12,13);

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

void setup()
{
  m1.Setup();
  m2.Setup();
  m3.Setup();
  
  Serial.begin(19200);
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
    } else if( inByte == 'y' ) {
      newYAngle = getFinalAngle();
    } else if( inByte == 'z' ) {
      newZAngle = getFinalAngle();
    } else if( inByte == 'X' ) {
      m1.vel = getFinalAngle();
    } else if( inByte == 'Y' ) {
      m3.vel = getFinalAngle();
    } else if( inByte == 'Z' ) {
      m2.vel = getFinalAngle();
    } else if( inByte == '.' ) {
      newAngleDecimal = 1;
    } else if( inByte == '-' ) {
      negative = true;
    } else if( inByte == 'g' ) {
      m1.Go(newXAngle);
      m2.Go(newZAngle);
      m3.Go(newYAngle);
    } else if( inByte == 'h' ) {
      m1.vel = 300;
      m2.vel = 300;
      m3.vel = 300;
      m1.Go(0);
      m2.Go(0);
      m3.Go(0);
      newXAngle = newYAngle = newZAngle = 0;
    } else if( inByte == 'r' ) {
      m1.Reset();
      m2.Reset();
      m3.Reset();
    } else if( inByte == 's' ) {
      if( m1.Idle() )
        Serial.write("x");
      if( m2.Idle() )
        Serial.write("z");
      if( m3.Idle() )
        Serial.write("y");
    } else {
      int dec = inByte-'0';
      newAngle *= 10;
      newAngleDecimal *= 10;
      newAngle += dec;
    }
  }

  m1.Update();
  m2.Update();
  m3.Update();
  if( m1.Arrived() )
    Serial.write("x");
  if( m2.Arrived() )
    Serial.write("z");
  if( m3.Arrived() )
    Serial.write("y");
  delayMicroseconds(200);
}

