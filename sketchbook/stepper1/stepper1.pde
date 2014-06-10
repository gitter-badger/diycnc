const int a = 9;
const int b = 10;
const int c = 11;
const int d = 12;

void setup()
{
  pinMode(a, OUTPUT);     
  pinMode(b, OUTPUT);     
  pinMode(c, OUTPUT);     
  pinMode(d, OUTPUT);     

  digitalWrite(a, LOW);
  digitalWrite(b, LOW);
  digitalWrite(c, LOW);
  digitalWrite(d, LOW);

  Serial.begin(9600);
  delay(1000);
}

void allOff()
{
  digitalWrite(a, LOW);
  digitalWrite(b, LOW);
  digitalWrite(c, LOW);
  digitalWrite(d, LOW);
}

int frame = 0;
int delayTime = 1000;
int delayChangeDir = -1;
void loop()
{
  ++frame;
 
  switch( frame & 3 )
  {
    case 0:
      digitalWrite( b, LOW );
      digitalWrite( a, HIGH );
      break;
    case 1:
      digitalWrite( d, LOW );
      digitalWrite( c, HIGH );
      break;
    case 2:
      digitalWrite( a, LOW );
      digitalWrite( b, HIGH );
      break;
    case 3:
      digitalWrite( c, LOW );
      digitalWrite( d, HIGH );
      break;
  }

  //Serial.println(position, DEC);
  //Serial.println(old_AB, DEC);
  if( delayTime < 1000 || delayTime > 3500 )
    delayChangeDir *= -1;
  delayTime += delayChangeDir;
  delayMicroseconds(delayTime);
}

