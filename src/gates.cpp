#include <Arduino.h>

#include <SPI.h>

#define MFRC522_SPICLOCK SPI_CLOCK_DIV32
#include <MFRC522.h>

#include <WiFiManager.h>
#include <ArduinoOTA.h>
#include <FS.h>

#include "doorphone.h"
#include "audio.h"

WiFiUDP udp;

#define ADC_CS 15
#define MFRC_RST_PIN      4  // Configurable, see typical pin layout above
#define MFRC_SS_PIN       16 // Configurable, see typical pin layout above
#define LOCK_CONTROL_PIN  5

#define MFRC_MAX_GAIN

unsigned long voice_started = 0,
  unlockPulseTimeout = 0;

bool connected = false;

IPAddress houston_ip = IPAddress(HOUSTON_IP);

uint8_t keys[32][4];
uint8_t nkeys = 0;
uint8_t unknown_key[4];

static struct {
  int retry;
  int repeat_timeout;
} outgoing_msgs[INTERCOM_MSG_NUM];

MFRC522 mfrc522(MFRC_SS_PIN, MFRC_RST_PIN);  // Create MFRC522 instance

void card_reader_init() {
  //SPI.setClockDivider(SPI_CLOCK_DIV8);
  SPI.setHwCs(false);
  pinMode(ADC_CS, OUTPUT);
  digitalWrite(ADC_CS, HIGH);

  DPRINTF("MFRC522_SPICLOCK = %d, SPI_CLOCK_DIV16 = %d", MFRC522_SPICLOCK, SPI_CLOCK_DIV16);

  mfrc522.PCD_Init();

#ifdef MFRC_MAX_GAIN
  mfrc522.PCD_AntennaOff();
  mfrc522.PCD_SetAntennaGain(MFRC522::RxGain_max); // RxGain_38dB RxGain_43dB RxGain_max
  mfrc522.PCD_AntennaOn();
#endif

  pinMode(MFRC_RST_PIN, INPUT_PULLUP);
}

int key_index(uint8_t id[4]) {
  for (int i = 0; i < nkeys; i++) {
    if (memcmp(keys[i], id, 4) == 0)
      return i;
  }
  return -1;
}

void load_keys() {
  File f = SPIFFS.open("keyring.dat", "r");
  if (!f) {
    DPRINTF("Can't open keyring file.");
    return;
  }

  nkeys = f.read();
  f.read(keys[0], nkeys*4);
  f.close();

  DPRINTF("Keys in keyring: %d", nkeys);
  for (int i = 0; i<nkeys; i++) {
    DPRINTF("Key #%d: %X:%X:%X:%X", i, keys[i][0], keys[i][1], keys[i][2], keys[i][3]);
  }
}

void save_keys() {
  File f = SPIFFS.open("keyring.dat", "w");
  if (!f) {
    DPRINTF("Can't open keyring file.");
    return;
  }

  f.write(nkeys);
  f.write(keys[0], nkeys*4);
  f.close();

  DPRINTF("Keys saved.");
}


void doorUnlock() {

  digitalWrite(LOCK_CONTROL_PIN, LOW);
  unlockPulseTimeout = millis();

  audio_streaming_begin("/success.low.g722");
}

void voice_begin(IPAddress handset_ip) {

  pinMode(MFRC_RST_PIN, OUTPUT);
  digitalWrite(MFRC_RST_PIN, LOW); // turn off RFID reader, it messes up MISO
  audio_streaming_end(); // in case bell sound is still playing
  audio_streaming_begin(UDPSTREAM);
  audio_sampling_begin(handset_ip);
  voice_started = millis();

  DPRINTF("Starting voice communication to %s", handset_ip.toString().c_str());
  
}


void voice_end() {
  audio_sampling_end();
  audio_streaming_end();
  card_reader_init();
  voice_started = 0;
  DPRINTF("Voice communication ended.");
}

void confirm_msg(IPAddress ip, int msg) {
  udp.beginPacket(ip, CONTROL_PORT);
  udp.write(INTERCOM_MSG_OK);
  udp.write(msg);
  udp.endPacket();
  delay(UDP_SEND_DELAY);
}

void card_scan_loop() {

  // make sure we don't touch SPI while sampling audio with SPI ADC  
  if (audio_sampling() || audio_playing()) {
    return;
  }

  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }

#ifdef DEBUG
  // Dump debug info about the card; PICC_HaltA() is automatically called
  mfrc522.PICC_DumpToSerial(&(mfrc522.uid));
#endif
  
  uint8_t readCard[4];

  DPRINTF("Card serial bytes:");
  for ( uint8_t i = 0; i < mfrc522.uid.size; i++) {
    DPRINTF("%X", mfrc522.uid.uidByte[i]);
    readCard[i] = mfrc522.uid.uidByte[i];
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();

  if (key_index(readCard) != -1) { // check if known card 
    doorUnlock();
    // a little hack to trigger mqtt lock status via handset unit
    confirm_msg(houston_ip, INTERCOM_MSG_UNLOCK);
  } else {
    // queue unknown key message
    memcpy(unknown_key, readCard, 4);
    outgoing_msgs[INTERCOM_MSG_UNKNOWN_KEY].retry = MSG_RETRY_COUNT;
    audio_streaming_begin("/error.low.g722");
  }
}

void udp_listen_loop() {

  static unsigned long connectionTimeout = 0;
  static unsigned long doorbellRepeatTimeout = 0;
  static unsigned long wifiReconnectTimeout = 0;
  static unsigned long ping_timeout = 0;
  
  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiReconnectTimeout > 5000) {
      DPRINTF("WiFi connection lost (status = %d), reconnecting...", WiFi.status());
      // WiFi.disconnect();
      // WiFi.begin(houston_ap_ssid, houston_ap_psk);
      // // WiFi.reconnect();
      wifiReconnectTimeout = millis();
      // delay(10);
    }
    connected = false;
    return;
  } else {
    houston_ip = WiFi.gatewayIP();
  }
  
  int bytes = udp.parsePacket();
  if (bytes) {
    int msg = udp.read();
    switch (msg) {
      case INTERCOM_MSG_UNLOCK:
	doorUnlock();
	confirm_msg(udp.remoteIP(), msg);
	break;
	
      case INTERCOM_MSG_CONNECT:
	uint8_t address[4];
	if (udp.read(address, 4) == 4) {
	  voice_begin(IPAddress(address));
	  confirm_msg(udp.remoteIP(), msg);
	}
	break;
	
      case INTERCOM_MSG_HANGUP:
	voice_end();
	confirm_msg(udp.remoteIP(), msg);
	break;

      case INTERCOM_MSG_KEYRING:
	nkeys = udp.read();
	if (nkeys <= 32) {
	  udp.read(keys[0], nkeys*4);
	  save_keys();
	} else {
	  DPRINTF("Error saving keyring: too many keys received.");
	}
	confirm_msg(udp.remoteIP(), msg);
	break;

      case INTERCOM_MSG_OK:
	int msg_ok = udp.read();
	if (msg_ok == INTERCOM_MSG_PING) {
	  connectionTimeout = millis();
	  if (!connected) {
	    connected = true;
	    DPRINTF("UDP connection established.");
	  }
	}
	outgoing_msgs[msg_ok].retry = 0;
	outgoing_msgs[msg_ok].repeat_timeout = 0;
	break;
    }
    connectionTimeout = millis();
    if (!connected) {
      connected = true;
      DPRINTF("UDP connection established.");
    }
  }

  // connection timeout
  if (connected && (millis() - connectionTimeout > 5000)) {
    connected = false;
    DPRINTF("UDP connection lost.");
  }

  // ping houston module every second
  if (millis() - ping_timeout >= 1000) {
    udp.beginPacket(houston_ip, CONTROL_PORT);
    udp.write(INTERCOM_MSG_PING);
    if (!udp.endPacket()) {
      DPRINTF("udp.endPacket() error.");
    }
    delay(UDP_SEND_DELAY);
    ping_timeout = millis();
  }

  for (int omsg = 0; omsg < INTERCOM_MSG_NUM; omsg++) {
    if (outgoing_msgs[omsg].retry && (outgoing_msgs[omsg].repeat_timeout == 0 || millis() - outgoing_msgs[omsg].repeat_timeout > MSG_RETRY_PERIOD)) {
      udp.beginPacket(houston_ip, CONTROL_PORT);
      udp.write(omsg);
      if (omsg == INTERCOM_MSG_UNKNOWN_KEY) {
	udp.write(unknown_key, 4);
      }
      udp.endPacket();
      delay(UDP_SEND_DELAY);
      if (--outgoing_msgs[omsg].retry == 0) {
	outgoing_msgs[omsg].repeat_timeout = 0;
      } else {
	outgoing_msgs[omsg].repeat_timeout = millis();
      }
    }
  }
  
}


void setup() {


  digitalWrite(LOCK_CONTROL_PIN, HIGH);
  pinMode(LOCK_CONTROL_PIN, OUTPUT_OPEN_DRAIN);

#ifdef DEBUG
  Serial.begin(115200);
  DPRINTF("THE GATE KEEPAH GREETING YOU!");
#endif

  // ESP.eraseConfig();
  WiFi.mode(WIFI_STA);
  // WiFi.hostname("gatecontrol");
  WiFi.setAutoConnect(true);
  WiFi.setAutoReconnect(true);
  // WiFi.setPhyMode(WIFI_PHY_MODE_11B);
  WiFi.setOutputPower(20.5);
  WiFi.begin(houston_ap_ssid, houston_ap_psk);
  WiFi.setSleepMode(WIFI_NONE_SLEEP);

  // delay(500);
  
  if (!SPIFFS.begin()) {
    DPRINTF("SPIFFS.begin() failed");
  } else {
    load_keys();
  }

  ArduinoOTA.setHostname("gatecontrol");
  ArduinoOTA.begin();

  SPI.begin();
  card_reader_init();

  udp.begin(CONTROL_PORT);
  for (int i = 0; i < INTERCOM_MSG_NUM; i++) {
    outgoing_msgs[i].retry = 0;
    outgoing_msgs[i].repeat_timeout = 0;
  }

  audio_init();

}

void loop() {

  static unsigned long debounce = 0;
  static bool buttonState = HIGH, lastButtonState = HIGH;

  // handle lock pulse timeout
  if (digitalRead(LOCK_CONTROL_PIN) == LOW && (millis() - unlockPulseTimeout > 100)) {
    digitalWrite(LOCK_CONTROL_PIN, HIGH);
  }

  // Door bell button status
  bool reading;

  // only when we are not talking (coz shared pin)
  if (!audio_sampling()) {
    reading = digitalRead(MFRC_RST_PIN);
  } else {
    reading = lastButtonState;
  }

  if (reading != lastButtonState) {
    debounce = millis();
    lastButtonState = reading;
  }

  if (reading != buttonState && millis() - debounce > 50) {
    buttonState = reading;
    if (buttonState == LOW) {
      // doorbell button pressed, send signal
      if (connected) {
	outgoing_msgs[INTERCOM_MSG_BELL].retry = MSG_RETRY_COUNT;
	audio_streaming_begin("/bell.low.g722");
      } else {
	audio_streaming_begin("/error.low.g722");
      }
    } else {
      // doorbell button released, reinit card reader
      card_reader_init();
    }
  }

  // stop if connection lost or on timeout
  if (voice_started && (!connected || millis() - voice_started >= VOICE_TIME_LIMIT)) {
    voice_end();
  }

  // handle OTA if we aren't doing anything time critical
  if (!audio_sampling() && !audio_playing()) { 
    ArduinoOTA.handle();
  }

  udp_listen_loop();
  audio_buffer_loop(); // both udp and file playback
  card_scan_loop();
  delay(1);
}
