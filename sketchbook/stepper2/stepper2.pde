const int a = 8;
const int b = 9;
const int c = 10;
const int d = 11;

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

  pinMode(2, INPUT);     
  pinMode(3, INPUT);     
  pinMode(4, INPUT);     
  digitalWrite(2, LOW);
  digitalWrite(3, LOW);
  digitalWrite(4, LOW);

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
void setpos( int oct )
{
  oct = oct&7;
  //int aval[] = { 1,1,1,0,0,0,0,0 };
  //int bval[] = { 0,0,0,0,1,1,1,0 };
  //int cval[] = { 0,0,1,1,1,0,0,0 };
  //int dval[] = { 1,0,0,0,0,0,1,1 };
  int aval[] = { 1,1,0,0,1,1,0,0 };
  int bval[] = { 0,1,1,0,0,1,1,0 };
  int cval[] = { 0,0,1,1,0,0,1,1 };
  int dval[] = { 1,0,0,1,1,0,0,1 };

  if( aval[oct] )
    digitalWrite( a, HIGH );
  else
    digitalWrite( a, LOW );
  if( bval[oct] )
    digitalWrite( b, HIGH );
  else
    digitalWrite( b, LOW );
  if( cval[oct] )
    digitalWrite( c, HIGH );
  else
    digitalWrite( c, LOW );
  if( dval[oct] )
    digitalWrite( d, HIGH );
  else
    digitalWrite( d, LOW );  
}

int frame = 0;
int delayTime = 600;
int dir = 1;
int lastButton1 = 0;
int lastButton2 = 0;
int lastButton3 = 0;
void loop()
{
  frame+=8+dir;
  
  int button1 = digitalRead(2);
  if( button1 != lastButton1 )
  {
    if( button1 )
    {
      delayTime -= 10;
    }
    lastButton1 = button1;
  }
  int button2 = digitalRead(3);
  if( button2 != lastButton2 )
  {
    if( button2 )
    {
      delayTime += 10;
    }
    lastButton2 = button2;
  }
  int button3 = digitalRead(4);
  if( button3 != lastButton3 )
  {
    if( button3 )
    {
      dir+=1;
      if( dir==2 )
        dir = -1;
    }
    lastButton3 = button3;
  }
 
 setpos(frame);

  //Serial.println(position, DEC);
  //Serial.println(old_AB, DEC);
  delayMicroseconds(delayTime);
}

