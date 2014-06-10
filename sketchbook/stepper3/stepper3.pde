const int a = 0;//8;
const int b = 1;//9;
const int c = 2;//10;
const int d = 3;//11;

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

  //Serial.begin(9600);
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
  int aval[] = { 1,1,1,0,0,0,0,0 };
  int bval[] = { 0,0,0,0,1,1,1,0 };
  int cval[] = { 0,0,1,1,1,0,0,0 };
  int dval[] = { 1,0,0,0,0,0,1,1 };

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
int delayTime = 5;
int dir = 1;
int lastButton1 = 0;
int lastButton2 = 0;
int lastButton3 = 0;
void loop()
{
  frame+=dir+8;
  setpos(frame);

  //Serial.println(position, DEC);
  //Serial.println(old_AB, DEC);
  delay(delayTime);
}

