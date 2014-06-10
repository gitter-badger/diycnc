


int8_t enc_states[] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
uint8_t old_AB = 0;

int8_t read_encoder()
{
  int sensor1Value = digitalRead(2);
  int sensor2Value = digitalRead(3);
  uint8_t new_AB = (sensor1Value<<1)|sensor2Value;
  //uint8_t new_AB = ENC_PORT;

  old_AB <<= 2; //shift the values of pins 2 and 3 down to 0 and 1
  //so the rest of the logic works
  
  old_AB |= ( new_AB & 0x03 ); //add current state
  return ( enc_states[( old_AB & 0x0f )]);
}

int position = 0;
int lastPosition = 0;
int destination = 0;

void doEncoder()
{
  int8_t tmpdata;
  tmpdata = read_encoder();
  if( tmpdata )
  {
    position += tmpdata;
  }
}

void setup()
{
  pinMode(2, INPUT);     
  pinMode(5, OUTPUT);     
  pinMode(3, INPUT);     
  pinMode(7, OUTPUT);     
  pinMode(10, OUTPUT);     
  pinMode(11, OUTPUT);     

  //digitalWrite(4, HIGH);
  digitalWrite(5, HIGH);
  //digitalWrite(6, HIGH);
  digitalWrite(7, LOW);
  digitalWrite(10, LOW);
  digitalWrite(11, LOW);

  Serial.begin(9600);
  delay(1000);

  // encoder pin on interrupt 0 (pin 2)
  attachInterrupt(0, doEncoder, CHANGE);
  // encoder pin on interrupt 1 (pin 3)
  attachInterrupt(1, doEncoder, CHANGE);
}

static int state = 0;

void left()
{
  digitalWrite( 10, HIGH );
  digitalWrite( 11, LOW );
}
void right()
{
  digitalWrite( 10, LOW );
  digitalWrite( 11, HIGH );
}
void move( int dir )
{
  switch( dir )
  {
    case 0: stop(); return;
    case 1: left(); return;
    case -1: right(); return;
  }
}
void stop()
{
  digitalWrite( 10, LOW );
  digitalWrite( 11, LOW );
}

int newAngle = 0;
int frame = 0;
void loop()
{
  byte inByte, zero = 0;
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
    Serial.print("rec:");
    Serial.println(inByte, DEC);
    if( inByte != 46 )
    {
      int dec = inByte-'0';
      newAngle *= 10;
      newAngle += dec;
    }
    else
    {
      destination = newAngle;
      newAngle = 0;
    }
  }

  int speed = 0;
  int dir = 0;
  int dist = 0;
    
  if( destination > position )
  {
    dir = 1;
    dist = destination - position;
    speed = position - lastPosition;
  }
  
  if( destination < position )
  {
    dir = -1;
    dist = position - destination;
    speed = lastPosition - position;
  }
  
  if( dist > 90 )
  {
    move(dir);
  }
  else
  {
    if( speed == 0 )
    {
      move(dir);
    }
    else
    {
      stop();
    }
  }

  
  lastPosition = position;
  ++frame;
  if( ( frame & 31 ) == 0 )
  {
    char buffer[ 24 ];
    sprintf( buffer, "%5i %4i  -> %5i", position, speed, destination );
    Serial.println(buffer);
    sprintf( buffer, "%5i %2i", dist, dir );
    Serial.println(buffer);
    //Serial.print(position, DEC);
    //Serial.print(" ");
    //Serial.println(speed, DEC);
    //Serial.print(" ");
    //Serial.println(destination, DEC);
  }
  //Serial.println(old_AB, DEC);
  delay(5);
}

