#include <Wire.h>

#define ADXL345_ADDRESS 0x53
#define DATA_REGISTER 0x32

const int finger0 = A0;
const int finger1 = A1;
const int finger2 = A2;

float filterx = 0;
float xOffset = 90;

float triggerThreshold = 60;   // must exceed this to fire
int strumState = 0;  // 0=neutral, 1=in DOWN, -1=in UP

unsigned long lastUpTime = 0;
unsigned long lastDownTime = 0;

int minTimeBetweenTriggers = 300;

void writeTo(int device, byte address, byte val) {
  Wire.beginTransmission(device);
  Wire.write(address);
  Wire.write(val);
  Wire.endTransmission();
}

void setup() {
  Wire.begin();
  Serial.begin(9600);
  writeTo(ADXL345_ADDRESS, 0x2D, 0x08);
  pinMode(finger0, INPUT);
  pinMode(finger1, INPUT);
  pinMode(finger2, INPUT);
  delay(10);
}

void loop() {
  Wire.beginTransmission(ADXL345_ADDRESS);
  Wire.write(DATA_REGISTER);
  Wire.endTransmission();
  Wire.requestFrom(ADXL345_ADDRESS, 6);

  int16_t rawX = (int16_t) Wire.read() | (Wire.read() << 8);
  Wire.read(); Wire.read(); // reads y - not needed but don't want to disturb x-axis
  Wire.read(); Wire.read(); // reads z

  float finger0read = analogRead(finger0);
  float finger1read = analogRead(finger1);
  float finger2read = analogRead(finger2);


  filterx = 0.5 * filterx + 0.5 * (rawX - xOffset);

  unsigned long now = millis();

// upward movement
  if (filterx > triggerThreshold) {
    // Entered UP zone
    if (strumState != -1 && (now - lastUpTime > minTimeBetweenTriggers)) { // Last strum !up & enough time has gone
      strumState = -1; // set strum state to "UP"
      lastUpTime = now; // takes time from last up strum
      Serial.print(finger0read);
      Serial.print(",");
      Serial.print(finger1read);
      Serial.print(",");
      Serial.print(finger2read);
      Serial.print(",");
      Serial.println("-1");
    }

  } else if (filterx < -triggerThreshold) {
    // Entered DOWN zone
    if (strumState != 1 && (now - lastDownTime > minTimeBetweenTriggers)) {
      strumState = 1;
      lastDownTime = now;
      Serial.print(finger0read);
      Serial.print(",");
      Serial.print(finger1read);
      Serial.print(",");
      Serial.print(finger2read);
      Serial.print(",");
      Serial.println("1");
    }
  }

}