#include <SPI.h>


// #define AUDIO_DEBUG

#ifndef DISABLE_STA
#include <ESP8266mDNS.h>
#include <WiFiManager.h>
#include <PubSubClient.h>
#endif

#ifdef ENABLE_WEB_GUI
#include <web-ui.h>
#include <ArduinoJSON.h>
#include <Ticker.h>
#endif

#include <ArduinoOTA.h>
#include <FS.h>

#include <Adafruit_NeoPixel.h>

#include "doorphone.h"
#include "audio.h"

#define SOFT_AP_HIDDEN true

#define CONNECT_BTN_PIN 4
#define UNLOCK_BTN_PIN 5
#define SPK_EN_PIN 16

#ifndef CONNECT_BTN_ACTIVE
#define CONNECT_BTN_ACTIVE LOW
#endif

#ifdef PT8211
#define LED_DATA_PIN 0
#else
#define LED_DATA_PIN 13
#endif

#define STATUS_LED 0
#define SPK_EN LOW

enum {MQTT_CMD_LOCK = 0, MQTT_CMD_KEYS_ADD, MQTT_CMD_KEYS_DELETE, MQTT_CMD_KEYS_LIST, MQTT_CMD_UNKNOWN};

struct {
#ifndef DISABLE_STA
  char mqtt_server[32] = "miniboxxy"; // mdns hostname in .local domain
#endif
  char ringtone[32] = "/bell.g722";
  uint8_t nkeys = 0;
  struct {
    uint8_t id[4];
    char comment[128];
    bool status;
  } keys[32];
} settings;

#ifdef DEBUG
char unknown_key[16] = "FF:FF:FF:FF";
#else
char unknown_key[16] = "";
#endif

Adafruit_NeoPixel leds = Adafruit_NeoPixel(1, LED_DATA_PIN, NEO_GRB + NEO_KHZ800);

WiFiUDP udp;

WiFiClient wlclient;

#ifndef DISABLE_STA
PubSubClient mqtt(wlclient);
#endif

IPAddress gatecontrol_ip = IPAddress(GATECONTROL_IP);
IPAddress handset_ip = IPAddress(HOUSTON_IP);

static struct {
  int retry;
  int repeat_timeout;
} outgoing_msgs[INTERCOM_MSG_NUM];


#ifdef AUDIO_DEBUG
int status = HANDSET_STATUS_IDLE;
#else
int status = HANDSET_STATUS_DISCONNECTED;
#endif

uint32_t status_color[] = {
  [HANDSET_STATUS_NONE] = 0,
  [HANDSET_STATUS_DISCONNECTED] = leds.Color(16, 0, 0),
  [HANDSET_STATUS_IDLE] = leds.Color(0, 16, 0),
  [HANDSET_STATUS_RINGING] = leds.Color(255, 0, 255),
  [HANDSET_STATUS_VOICE] = leds.Color(0, 128, 0),
  [HANDSET_STATUS_VOICE_MUTE] = leds.Color(0, 0, 128),
};

const char *mqtt_command[] =
  {
   [MQTT_CMD_LOCK] = "lock/set",
   [MQTT_CMD_KEYS_ADD] = "keys/add",
   [MQTT_CMD_KEYS_DELETE] = "keys/delete",
   [MQTT_CMD_KEYS_LIST] = "keys/list"
  };

unsigned long
  ringer_started = 0,
  ringer_repeat_timeout = 0,
  voice_started = 0,
  mqtt_unlock_published = 0;


/*
 * Load settings from settings.txt
 */
void readSettings() {
  File f;
  char *buf, *key, *value;
  
  f = SPIFFS.open("/settings.txt", "r");
  if (!f) {
    DPRINTF("Can't open settings file, module will use hardcoded fallback values.");
    return;
  }

  buf = new char[f.size() + 1];
  f.read((uint8_t *)buf, f.size());
  buf[f.size()] = '\0';
  f.close();

  DPRINTF("settings.txt:\n%s", buf);

  key = strtok(buf, "\n\r");

  settings.nkeys = 0;
  
  while (key) {
    value = strchr(key, '=');
    if (value) {
      *value = '\0'; value++;
      if (strcmp(key, "key") == 0) {
	int id_int[4];
	if (sscanf(value, "%x:%x:%x:%x;%s",
		   &id_int[0], &id_int[1], &id_int[2], &id_int[3], settings.keys[settings.nkeys].comment) == 5) {
	  for (int i=0; i<4; i++) {
	    settings.keys[settings.nkeys].id[i] = id_int[i];
	  }
	  settings.keys[settings.nkeys++].status = true;
	}
#ifndef DISABLE_STA
      } else if (strcmp(key, "mqtt_server") == 0) {
        strcpy(settings.mqtt_server, value);
#endif	
      } else if (strcmp(key, "ringtone") == 0) {
	strcpy(settings.ringtone, value);
      }
    }
    key = strtok(NULL, "\n\r");
  }

  delete [] buf;
  buf = NULL;
}

void saveSettings() {
  File f;
    
  f = SPIFFS.open("/settings.txt", "w");
  if (!f) {
    DPRINTF("Can't open settings.txt.");
    return;
  }
  
#ifndef DISABLE_STA  
  f.printf("mqtt_server=%s\n", settings.mqtt_server);
#endif
  
  f.printf("ringtone=%s\n", settings.ringtone);

  for (int i = 0; i < settings.nkeys; i++) {
    if (settings.keys[i].status) {
      f.printf("key=%X:%X:%X:%X;%s\n",
	       settings.keys[i].id[0],
	       settings.keys[i].id[1],
	       settings.keys[i].id[2],
	       settings.keys[i].id[3],
	       settings.keys[i].comment);
    }
  }
  DPRINTF("Current settings saved to settings.txt");
  
}


#ifndef DISABLE_STA
IPAddress mdns_resolve(const char hostname[], const char service[], const char protocol[]) {
  int n = MDNS.queryService(service, protocol);
  for (int i = 0; i < n; i++) {
    if (MDNS.hostname(i) == hostname) {
      return MDNS.IP(i);
    }
  }
  return IPAddress();
}

void mqtt_reconnect() {

  // Wait 5 seconds before trying again
  static unsigned long previous_attempt = 0;
  if (millis() - previous_attempt < 5000) {
    return;
  }  
  previous_attempt = millis();

  IPAddress mqtt_ip = mdns_resolve(settings.mqtt_server, "mqtt", "tcp");
  
  if (!mqtt_ip) {
    DPRINTF("\"%s.local\" not found", settings.mqtt_server);
    return;
  } else {
    DPRINTF("Found \"%s.local\": %d.%d.%d.%d", settings.mqtt_server, mqtt_ip[0], mqtt_ip[1],mqtt_ip[2],mqtt_ip[3]);
    mqtt.setServer(mqtt_ip, 1883);
  }

  if (mqtt.connect("gatescontrol")) {
    DPRINTF("Connected to MQTT broker");
    mqtt.subscribe("yard/gates/lock/set", 1); // 1 - QOS - "at least once"
    mqtt.subscribe("yard/gates/keys/+", 1);
    mqtt.publish("yard/gates/status", "ONLINE");
    mqtt.publish("yard/gates/lock/status", "LOCK", true);
  } else {
    DPRINTF("Connection to MQTT broker failed, rc=");
  }
}

void mqtt_callback(const char topic[], byte* payload, unsigned int length);

#endif


void bell_begin() {
  ringer_repeat_timeout = 0;
  ringer_started = millis();
  digitalWrite(SPK_EN_PIN, SPK_EN);
  status = HANDSET_STATUS_RINGING;
}

void bell_end() {
  audio_streaming_end();
  digitalWrite(SPK_EN_PIN, !SPK_EN);
  ringer_started = 0;
  if (status == HANDSET_STATUS_RINGING)
    status = HANDSET_STATUS_IDLE;
}

void voice_begin(bool mute = false) {
  DPRINTF("Voice communication begin.");
  bell_end();
  audio_streaming_begin(UDPSTREAM);
  // audio_streaming_begin("/success.g722");
  status = HANDSET_STATUS_VOICE_MUTE;
  if (!mute) {
    audio_sampling_begin(gatecontrol_ip);
    status = HANDSET_STATUS_VOICE;
  }
  voice_started = millis();
}

void voice_end() {
  audio_sampling_end();
  audio_streaming_end();
  // audio_streaming_begin("/hangup.g722");
  voice_started = 0;
  if (status == HANDSET_STATUS_VOICE || status == HANDSET_STATUS_VOICE_MUTE)
    status = HANDSET_STATUS_IDLE;
  
  DPRINTF("Voice communication end.");
}

int key_index(uint8_t id[4]) {
  for (int i = 0; i < settings.nkeys; i++) {
    if (memcmp(settings.keys[i].id, id, 4) == 0)
      return i;
  }
  return -1;
}

bool add_key(const char *key) {
  uint8_t id[4];
  int id_int[4];
  if (sscanf(key, "%x:%x:%x:%x;%s",
	     &id_int[0], &id_int[1], &id_int[2], &id_int[3], settings.keys[settings.nkeys].comment) == 5) {
    for (int i=0; i<4; i++) {
      id[i] = id_int[i];
    }
    DPRINTF("New key: %s, unknown key: %s, length: %d", key, unknown_key, strchr(key, ';') - key);
    if (key_index(id) != -1) {
      DPRINTF("Key already known.");
    } else {
      if (strncmp(unknown_key, key, strchr(key, ';') - key) == 0) {
	unknown_key[0] = 0;
      }
      memcpy(settings.keys[settings.nkeys].id, id, 4);
      settings.keys[settings.nkeys++].status = true;
      DPRINTF("Added key: %02X:%02X:%02X:%02X", id_int[0], id_int[1], id_int[2], id_int[3]);
      saveSettings();
      outgoing_msgs[INTERCOM_MSG_KEYRING].retry = MSG_RETRY_COUNT;
      return true;
    }
  } else {
    DPRINTF("Error parsing key.");
  }
  return false;
}

bool delete_key(const char *key) {
  int index;
  uint8_t id[4];
  int id_int[4]; 
  if (sscanf(key, "%x:%x:%x:%x",
	     &id_int[0], &id_int[1], &id_int[2], &id_int[3]) == 4) {
    for (int i=0; i<4; i++) {
      id[i] = id_int[i];
    }
    index = key_index(id);
    if (index != -1) {
      settings.keys[index].status = false;
      saveSettings();
      readSettings();
      outgoing_msgs[INTERCOM_MSG_KEYRING].retry = MSG_RETRY_COUNT;
      return true;
    } else {
      DPRINTF("Key id not found.");
    }
  } else {
    DPRINTF("Error parsing key.");
  }
  return false;
}


#ifdef ENABLE_WEB_GUI


void set_ringtone(const char *ringtone) {
  static Ticker ticker;
  strcpy(settings.ringtone + 1, ringtone);
  saveSettings();
  bell_end();
  bell_begin();
  ticker.once(5, bell_end);
  // audio_streaming_end();
  // audio_streaming_begin(settings.ringtone);
}

char* settings_json() {
  char *response;
  
  const size_t capacity = JSON_ARRAY_SIZE(32) + 32*JSON_OBJECT_SIZE(2) + JSON_OBJECT_SIZE(3);
  DynamicJsonDocument doc(capacity);

  doc["ringtone"] = settings.ringtone + 1;
  doc["unknown_key"] = unknown_key;

  JsonArray keys = doc.createNestedArray("keys");
  for (int i = 0; i < settings.nkeys; i++) {
    JsonObject key = keys.createNestedObject();
    char string_id[] = "FF:FF:FF:FF";
    uint8_t *id = settings.keys[i].id;
    sprintf(string_id, "%X:%X:%X:%X", id[0], id[1], id[2], id[3]);
    key["guid"] = string_id;
    key["comment"] = settings.keys[i].comment;
  }

  size_t outputSize = measureJson(doc) + 1;
  
  response = new char[outputSize];

  serializeJson(doc, response, outputSize);

  DPRINTF("heap: %d", ESP.getFreeHeap());
  
  return response;
}

#endif

#ifndef DISABLE_STA

void mqtt_callback(const char topic[], byte* payload, unsigned int length) {
  char
    *msg = new char[length + 1],
    *topic_suffix = (char *)topic + strlen("yard/gates/");
  strncpy(msg, (char *)payload, length);
  msg[length] = 0;
  uint8_t id[4];
  int id_int[4];
  
  DPRINTF("Topic: %s, suffix: %s, payload: %s", topic, topic_suffix, msg);
  
  int command;
  for (command = 0; command < MQTT_CMD_UNKNOWN; command++) {
    if (strcmp(topic_suffix, mqtt_command[command]) == 0) {
      break;
    }
  }

  switch (command) {
    case MQTT_CMD_LOCK:
      if (strcmp(msg, "UNLOCK") == 0) {
	if (outgoing_msgs[INTERCOM_MSG_UNLOCK].retry == 0) {
	  outgoing_msgs[INTERCOM_MSG_UNLOCK].retry = MSG_RETRY_COUNT;
	}
      }
      break;

    case MQTT_CMD_KEYS_ADD:
      add_key(msg);
      break;

    case MQTT_CMD_KEYS_DELETE:
      delete_key(msg);
      break;

    case MQTT_CMD_KEYS_LIST:
      char header[] = "### Access keys\n",
	line[50] = "";
      size_t plength = strlen(header);

      for (int i = 0; i < settings.nkeys; i++) {
	uint8_t *id = settings.keys[i].id;
	plength += sprintf(line, "%X:%X:%X:%X;%s\n", id[0], id[1], id[2], id[3], settings.keys[i].comment);
      }

      mqtt.beginPublish("yard/gates/status", plength, false);
      mqtt.print(header);
      for (int i = 0; i < settings.nkeys; i++) {
	uint8_t *id = settings.keys[i].id;
	mqtt.printf("%X:%X:%X:%X;%s\n", id[0], id[1], id[2], id[3], settings.keys[i].comment);
      }
      mqtt.endPublish();
      break;
  }

  delete [] msg;
}

#endif

void confirm_msg(IPAddress ip, int msg) {
  udp.beginPacket(ip, CONTROL_PORT);
  udp.write(INTERCOM_MSG_OK);
  udp.write(msg);
  udp.endPacket();
  delay(UDP_SEND_DELAY);
}

void udp_listen_loop() {

  static unsigned long connectionTimeout = 0;

#ifndef DISABLE_STA

  static uint32_t wifiReconnectTimeout = 0;
  
  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiReconnectTimeout > 30000) {
      DPRINTF("WiFi connection lost (status = %d), reconnecting...", WiFi.status());
      WiFi.reconnect();
      wifiReconnectTimeout = millis();
      delay(10);
    }
    status = HANDSET_STATUS_DISCONNECTED;
    return;
  }

#endif
  
  int bytes = udp.parsePacket();
  if (bytes) {
    int msg = udp.read();
    switch (msg) {
      case INTERCOM_MSG_BELL:
	bell_begin();
      	confirm_msg(udp.remoteIP(), msg);
	break;
	
      case INTERCOM_MSG_PING:
	connectionTimeout = millis();
	confirm_msg(udp.remoteIP(), msg);
	if (status == HANDSET_STATUS_DISCONNECTED) {
	  status = HANDSET_STATUS_IDLE;
	  gatecontrol_ip = udp.remoteIP();
	  DPRINTF("Gate control is now connected. IP: %s", gatecontrol_ip.toString().c_str());
	}
	break;

      case INTERCOM_MSG_UNKNOWN_KEY:
	uint8_t id[4];
	udp.read(id, 4);
#ifndef DISABLE_STA
	char status_update[64];
	sprintf(status_update, "### Unknown key\nid: %X:%X:%X:%X", id[0], id[1], id[2], id[3]);
	mqtt.publish("yard/gates/status", status_update, false);
#endif
#ifdef ENABLE_WEB_GUI
	sprintf(unknown_key, "%X:%X:%X:%X", id[0], id[1], id[2], id[3]);
	broadcastSettings();
#endif
	confirm_msg(udp.remoteIP(), msg);
	break;

      case INTERCOM_MSG_OK:
	int msg_ok = udp.read();
	switch (msg_ok) {
	case INTERCOM_MSG_PING:
	  break;
	  
	case INTERCOM_MSG_UNLOCK:
	  
#ifndef DISABLE_STA
	  mqtt.publish("yard/gates/lock/status", "UNLOCK");
	  mqtt_unlock_published = millis();
#endif
	  // TODO process unlock with some confirmation sound or whatever
	  break;
	  
	case INTERCOM_MSG_HANGUP:
	  // TODO process hangup
	  break;
	  
	case INTERCOM_MSG_CONNECT:
	  // TODO start voice
	  break;
	}
	outgoing_msgs[msg_ok].retry = 0;
	outgoing_msgs[msg_ok].repeat_timeout = 0;
	break;
    }
    connectionTimeout = millis();

  }

#ifndef AUDIO_DEBUG
  // connection timeout
  if (status != HANDSET_STATUS_DISCONNECTED && (millis() - connectionTimeout > 5000)) {
    status = HANDSET_STATUS_DISCONNECTED;
    DPRINTF("Gate control disconnected.");
  }
#endif

  for (int omsg = 0; omsg < INTERCOM_MSG_NUM; omsg++) {
    if (outgoing_msgs[omsg].retry && (outgoing_msgs[omsg].repeat_timeout == 0 || millis() - outgoing_msgs[omsg].repeat_timeout > MSG_RETRY_PERIOD)) {
      udp.beginPacket(gatecontrol_ip, CONTROL_PORT);
      udp.write(omsg);
      if (omsg == INTERCOM_MSG_CONNECT) {
	udp.write(handset_ip[0]);
	udp.write(handset_ip[1]);
	udp.write(handset_ip[2]);
	udp.write(handset_ip[3]);
      } else if (omsg == INTERCOM_MSG_KEYRING) {
	udp.write(settings.nkeys);
	for (int i = 0; i < settings.nkeys; i++) {
	  udp.write(settings.keys[i].id, 4);
	}
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

#ifdef DEBUG
  Serial.begin(115200);
  Serial.println("HOUSTON IS READY");
#endif

  if (!SPIFFS.begin()) {
    DPRINTF("SPIFFS.begin() failed");
    // return;
  } else {
    readSettings();
  }

  
#ifndef DISABLE_STA  
  WiFiManager wifiManager;
  // WifiManager.resetSettings(); // reset saved SSID and password

#ifndef DEBUG
  wifiManager.setDebugOutput(false);
#endif

  wifiManager.setTimeout(300);  
  if (!wifiManager.autoConnect(houston_ap_ssid, houston_ap_psk)) {
    DPRINTF("Failed to connect to AP...");
  }
  
  WiFi.mode(WIFI_AP_STA);
#else
  WiFi.mode(WIFI_AP);
#endif

  WiFi.setSleepMode(WIFI_NONE_SLEEP);
  WiFi.setAutoConnect(false);
  WiFi.setAutoReconnect(false);
  WiFi.softAPConfig(IPAddress(HOUSTON_IP), IPAddress(HOUSTON_IP), IPAddress(255,255,255,0));
  // WiFi.setOutputPower(20.5);
  WiFi.softAP(houston_ap_ssid, houston_ap_psk, WiFi.channel(), SOFT_AP_HIDDEN);

#ifdef DISABLE_STA
  WiFi.enableAP(true);
  DPRINTF("SSID: %s, PSK: %s", houston_ap_ssid, houston_ap_psk);
#else
  WiFi.reconnect();
  DPRINTF("SSID: %s, PSK: %s", houston_ap_ssid, houston_ap_psk);
#endif
  
  ArduinoOTA.setHostname("houston");
  ArduinoOTA.begin();

#ifndef DISABLE_STA  
  mqtt.setCallback(mqtt_callback);
#endif

#ifdef ENABLE_WEB_GUI
  setupWebUI();
#endif

  udp.begin(CONTROL_PORT);

  for (int i = 0; i < INTERCOM_MSG_NUM; i++) {
    outgoing_msgs[i].retry = 0;
    outgoing_msgs[i].repeat_timeout = 0;
  }

  SPI.begin();
  
  audio_init();

  pinMode(CONNECT_BTN_PIN, INPUT_PULLUP);
  pinMode(UNLOCK_BTN_PIN, INPUT_PULLUP);
  digitalWrite(SPK_EN_PIN, !SPK_EN);
  pinMode(SPK_EN_PIN, OUTPUT);

  pinMode(LED_DATA_PIN, OUTPUT);

  leds.begin();

  audio_streaming_begin("/success.g722");

}

void loop() {

  static unsigned long conn_btn_debounce = 0, unlock_btn_debounce;
  static bool conn_btn_state = !CONNECT_BTN_ACTIVE, last_conn_btn_state = !CONNECT_BTN_ACTIVE,
    unlock_btn_state = HIGH, last_unlock_btn_state = HIGH;

  static int btn_down_status;
  
  bool reading = digitalRead(CONNECT_BTN_PIN);
  
  if (reading != last_conn_btn_state) {
    conn_btn_debounce = millis();
    last_conn_btn_state = reading;
  }
  
  if (reading != conn_btn_state && millis() - conn_btn_debounce > 50) {
    conn_btn_state = reading;
    if (conn_btn_state == CONNECT_BTN_ACTIVE) {
      // connect/hangup button pressed
      if (status == HANDSET_STATUS_DISCONNECTED) { // no connection to gatecontrol unit
	bell_end();
	audio_streaming_begin("/error.g722");
      } else if (status != HANDSET_STATUS_VOICE && status != HANDSET_STATUS_VOICE_MUTE) { // voice already in progress
	handset_ip = WiFi.softAPIP();
	outgoing_msgs[INTERCOM_MSG_CONNECT].retry = MSG_RETRY_COUNT;
	voice_begin();
      }
    } else {
      // connect/hangup button released
      if (status == HANDSET_STATUS_VOICE || status == HANDSET_STATUS_VOICE_MUTE) { // hangup
	voice_end();
	outgoing_msgs[INTERCOM_MSG_HANGUP].retry = MSG_RETRY_COUNT;
      }
    }
  }

  reading = digitalRead(UNLOCK_BTN_PIN);
  if (reading != last_unlock_btn_state) {
    unlock_btn_debounce = millis();
    last_unlock_btn_state = reading;
  }

  if (reading != unlock_btn_state && millis() - unlock_btn_debounce > 50) {
    unlock_btn_state = reading;
    if (unlock_btn_state == LOW) {
      if (status == HANDSET_STATUS_RINGING) {
	bell_end();
      }
      if (status == HANDSET_STATUS_DISCONNECTED) {
	audio_streaming_begin("/error.g722");
      } else {
	outgoing_msgs[INTERCOM_MSG_UNLOCK].retry = MSG_RETRY_COUNT;
      }
    }
  }

  // voice communication timeout or disconnect
  if (voice_started && (status == HANDSET_STATUS_DISCONNECTED || millis() - voice_started >= VOICE_TIME_LIMIT)) {
    DPRINTF("Voice connection time out or UDP connection lost.");
    voice_end();
  }

  // ringer timeout or disconnect
  if (ringer_started && (status != HANDSET_STATUS_RINGING || millis() - ringer_started >= 30000)) {
    bell_end();
  }

  if (status == HANDSET_STATUS_RINGING && (ringer_repeat_timeout == 0 || millis() - ringer_repeat_timeout >= 5000)) {
    audio_streaming_begin(settings.ringtone);
    ringer_repeat_timeout = millis();
  }
  
  // Handle OTA if we dont do anything time critical
  if (!audio_sampling() && !audio_playing()) { 
    ArduinoOTA.handle();
  }

#ifdef ENABLE_WEB_GUI
  if (!audio_sampling()) {
    loopWebUI();
  }
#endif


#ifndef DISABLE_STA
  // poll mqtt every once in a while as it's quite slow
  static unsigned long mqttLastLoop = 0;
  if (millis() - mqttLastLoop >= 400) {
    mqttLastLoop = millis();
    if (!mqtt.loop()) {
      mqtt_reconnect();
    } else {
      if (mqtt_unlock_published && millis() - mqtt_unlock_published > 10000) {
	mqtt.publish("yard/gates/lock/status", "LOCK");
	mqtt_unlock_published = 0;
      }
    }
  }
#endif
  
  static int previous_status = HANDSET_STATUS_NONE;
  static unsigned long status_led_update_timeout = 0;
  static bool blink;
  if (status == HANDSET_STATUS_IDLE || previous_status != status || millis() - status_led_update_timeout >= 1000) {
    previous_status = status;
    status_led_update_timeout = millis();
    uint32_t ledColor;
    if (status == HANDSET_STATUS_IDLE) {
      ledColor = leds.Color(0, map(leds.sine8(millis() >> 4), 0, 255, 1, 12), 0);
    } else {
      blink = !blink;
      ledColor = (status == HANDSET_STATUS_RINGING && blink) ? 0 : status_color[status];
    }
    leds.setPixelColor(0, ledColor);
    leds.show();
  }

  udp_listen_loop();
  audio_buffer_loop();
  delay(1);
}
