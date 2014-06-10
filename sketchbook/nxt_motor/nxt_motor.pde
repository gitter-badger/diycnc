
void setup()
{
  pinMode(2, OUTPUT);     
  pinMode(3, OUTPUT);     
  pinMode(4, OUTPUT);     
  pinMode(5, OUTPUT);     

  digitalWrite(2, LOW);
  digitalWrite(3, LOW);
  digitalWrite(4, LOW);
  digitalWrite(5, LOW);

  Serial.begin(9600);
  delay(1000);
}

int frame = 0;
void loop()
{
  ++frame;
 
  digitalWrite(2, LOW);
  digitalWrite(3, LOW);
  digitalWrite(4, LOW);
  digitalWrite(5, LOW);

  switch( frame & 3 )
  {
    case 0: digitalWrite( 2, HIGH ); break;
    case 1: digitalWrite( 4, HIGH ); break;
    case 2: digitalWrite( 3, HIGH ); break;
    case 3: digitalWrite( 5, HIGH ); break;
  }

  //Serial.println(position, DEC);
  //Serial.println(old_AB, DEC);
  delay(100);
}

