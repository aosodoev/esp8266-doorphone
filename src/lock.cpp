// #include<Arduino.h>
#include <wiring_private.h>

#define MOTOR_LEFT 4
#define MOTOR_RIGHT 3
#define BUZZER 0
#define CONTROL_PIN 1
#define DOOR_SWITCH 2

#define LOCK_TIMEOUT 30000 // wait 30 seconds before releasing the lock
#define ACTUATOR_DELAY_PULL 250 // probably pulling load would be slower
#define ACTUATOR_DELAY_RELEASE 250
#define ACTUATOR_PULL_DUTY 64
#define TONE_PERIOD 1000

unsigned long toneRepeat = 0, lockTimeout = 0, debounce = 0, doorSwitchDebounce = 0;
bool lockOpen = false, controlReading, lastControlState = false, initialDoorState, controlState, doorState, doorStateReading, lastDoorState;

void setup() {
  
  pinMode(CONTROL_PIN, INPUT_PULLUP);
  pinMode(DOOR_SWITCH, INPUT_PULLUP);
  digitalWrite(DOOR_SWITCH, HIGH);
  digitalWrite(CONTROL_PIN, HIGH);
  pinMode(BUZZER, OUTPUT);
  pinMode(MOTOR_LEFT, OUTPUT);
  pinMode(MOTOR_RIGHT, OUTPUT);
  digitalWrite(MOTOR_LEFT, LOW);
  digitalWrite(MOTOR_RIGHT, LOW);
  lastControlState = digitalRead(CONTROL_PIN);

  // combine first beep and motor delays
  digitalWrite(BUZZER, HIGH);
  
  // Make sure motor is out
  digitalWrite(MOTOR_RIGHT, HIGH);
  delay(ACTUATOR_DELAY_RELEASE);
  digitalWrite(MOTOR_RIGHT, LOW);

  delay(300-ACTUATOR_DELAY_RELEASE);
  digitalWrite(BUZZER, LOW);

  for (int i = 0; i<2; i++) {
    delay(300);
    digitalWrite(BUZZER, HIGH);
    delay(300);
    digitalWrite(BUZZER, LOW);
  }
  
  // change timer1 PWM frequency for pin 4
  // cbi(TCCR1, CS11); // CK/2048
  // sbi(TCCR1, CS10); // uncomment to make it CK/4096
  // cbi(TCCR1, CS12); // CK/512
}

void loop() {

  // avoid ESP powercycle pulse 
  if (millis() < 100) {
    return;
  }

  controlReading = digitalRead(CONTROL_PIN) == LOW;
  if (controlReading != lastControlState) {
    debounce = millis();
    lastControlState = controlReading;
  }

  doorStateReading = digitalRead(DOOR_SWITCH) ==  LOW;
  if (doorStateReading != lastDoorState) {
    doorSwitchDebounce = millis();
    lastDoorState = doorStateReading;
  }

  if (doorStateReading != doorState && millis() - doorSwitchDebounce > 50) {
    doorState = doorStateReading;
  }

  if (controlReading != controlState && millis() - debounce > 50) {
    controlState = controlReading;
    if (!lockOpen && controlState) {
      initialDoorState = doorState;
      digitalWrite(MOTOR_LEFT, HIGH);
      delay(ACTUATOR_DELAY_PULL);
      digitalWrite(MOTOR_LEFT, LOW);
      analogWrite(MOTOR_LEFT, ACTUATOR_PULL_DUTY);
      lockTimeout = millis();
      lockOpen = true;
      doorState = digitalRead(DOOR_SWITCH) ==  LOW;
    }
  }

  unsigned long t = millis() - lockTimeout;

  if (lockOpen && ((doorState != initialDoorState) || (t >= LOCK_TIMEOUT))) {
    if (t < 400) { // wait until motor stops completely
      delay(400 - t);
    }
    digitalWrite(BUZZER, LOW);
    digitalWrite(MOTOR_LEFT, LOW);
    digitalWrite(MOTOR_RIGHT, HIGH);
    delay(ACTUATOR_DELAY_RELEASE);
    digitalWrite(MOTOR_RIGHT, LOW);
    lockOpen = false;
  }

  if (lockOpen && millis() - toneRepeat >= TONE_PERIOD) {
    digitalWrite(BUZZER, HIGH);
    toneRepeat = millis();
  }
  
  if (lockOpen && millis() - toneRepeat >= TONE_PERIOD >> 1) {
    digitalWrite(BUZZER, LOW);
  }
  
  
}
