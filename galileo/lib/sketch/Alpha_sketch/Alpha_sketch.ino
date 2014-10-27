#include "touch_mapping_lib.h"

const int PIN = 1;
const int BASE_THRESHOLD = 0;
const int MAX_THRESHOLD = 1023;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
}

void notify(int pin, double vol)
{
  int i_vol = floor(vol * 100.0);
  Serial.println(pin);
  Serial.println(i_vol);
}

int a_read(int pin)
{
  return analogRead(unsigned (pin));
}

Touch_map tm(PIN, notify, a_read, BASE_THRESHOLD, MAX_THRESHOLD);

void loop() {
  // put your main code here, to run repeatedly: 
  tm.update();
  delay(1000);
}
