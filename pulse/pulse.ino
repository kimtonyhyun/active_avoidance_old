#define PULSE_PIN 52

#define REP_PERIOD 4000 // ms
#define PULSE_PERIOD 500 // ms

void setup() {
  // put your setup code here, to run once:
  pinMode(PULSE_PIN, OUTPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(PULSE_PIN, 0);
  delay(REP_PERIOD - PULSE_PERIOD);
  digitalWrite(PULSE_PIN, 1);
  delay(PULSE_PERIOD);
}
