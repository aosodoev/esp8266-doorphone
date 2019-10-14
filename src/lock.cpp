// #include<Arduino.h>
#include <wiring_private.h>



#ifdef __AVR_ATtiny13__

#define MOTOR_LEFT 0
#define MOTOR_RIGHT 1
#define BUZZER 2
#define CONTROL_PIN 3
#define DOOR_SWITCH 4

#else

#define MOTOR_LEFT 4
#define MOTOR_RIGHT 3
#define BUZZER 0
#define CONTROL_PIN 1
#define DOOR_SWITCH 2

#endif

#define LOCK_TIMEOUT 30000 // wait 30 seconds before releasing the lock
#define ACTUATOR_DELAY_PULL 250 // probably pulling load would be slower
#define ACTUATOR_DELAY_RELEASE 250
#define ACTUATOR_PULL_DUTY 96
#define ACTUATOR_RELEASE_DUTY 128
#define TONE_PERIOD 1000

unsigned long toneRepeat = 0, lockTimeout = 0, debounce = 0, doorSwitchDebounce = 0;
bool lockOpen = false, controlReading, lastControlState = false, initialDoorState, controlState, doorState, doorStateReading, lastDoorState;

void bolt_release() {
  digitalWrite(MOTOR_RIGHT, HIGH);
  analogWrite(MOTOR_LEFT, 255 - ACTUATOR_RELEASE_DUTY);
  delay(ACTUATOR_DELAY_RELEASE);
  digitalWrite(MOTOR_LEFT, LOW);
  digitalWrite(MOTOR_RIGHT, LOW);
  lockOpen = false;
}

void setup() {
  
  pinMode(CONTROL_PIN, INPUT);
  digitalWrite(CONTROL_PIN, HIGH);
  pinMode(DOOR_SWITCH, INPUT);
  digitalWrite(DOOR_SWITCH, HIGH);
  pinMode(BUZZER, OUTPUT);
  pinMode(MOTOR_LEFT, OUTPUT);
  pinMode(MOTOR_RIGHT, OUTPUT);
  // digitalWrite(MOTOR_LEFT, LOW);
  // digitalWrite(MOTOR_RIGHT, LOW);
  lastControlState = digitalRead(CONTROL_PIN);

  // three short beeps on boot
  // combine first beep and motor delay
  digitalWrite(BUZZER, HIGH);
  
  // Make sure lock bolt is released (locked) on boot
  bolt_release();

  delay(300-ACTUATOR_DELAY_RELEASE);  
  digitalWrite(BUZZER, LOW);

  // make it 3
  for (int i = 0; i<4; i++) {
    delay(300);
    if (i % 2) {
      digitalWrite(BUZZER, LOW);
    } else {
      digitalWrite(BUZZER, HIGH);
    }
  }
  
#ifndef __AVR_ATtiny13__
  
  // change timer1 PWM frequency for pin 4
  cbi(TCCR1, CS11); // CK/2048
  sbi(TCCR1, CS10); // uncomment to make it CK/4096
  // cbi(TCCR1, CS12); // CK/512
#endif
}

void loop() {

  // avoid ESP power up GPIO pulse 
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
    digitalWrite(BUZZER, LOW);
    digitalWrite(MOTOR_LEFT, LOW);
    if (t < 400) { // wait until motor stops completely after pull pulse
      delay(400 - t);
    }
    // give motor and capacitor some time to rest and recharge
    // after pulling lock bolt otherwise stall current is too high
    delay(200);
    bolt_release();
  }

  if (lockOpen && millis() - toneRepeat >= TONE_PERIOD) {
    digitalWrite(BUZZER, HIGH);
    toneRepeat = millis();
  }
  
  if (lockOpen && millis() - toneRepeat >= TONE_PERIOD >> 1) {
    digitalWrite(BUZZER, LOW);
  }
  
  
}
