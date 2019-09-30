#ifndef __INTERCOM_H__
#define __INTERCOM_H__

#ifdef DEBUG
#define DPRINTF(format_literal, ...) Serial.printf("%s(%d): " format_literal "\n", __FILE__, __LINE__, ##__VA_ARGS__)
#else
#define DPRINTF(format_literal, ...)
#endif

// UDP ports
#define CONTROL_PORT 45992
#define VOICE_PORT 45990

#include "AP_credentials.h"

/* 

  AP_credentials.h:

// Credentials for soft AP created by handset unit
// Gates unit connects to this AP

static const char houston_ap_ssid[] = "houston";
static  const char houston_ap_psk[] = "***"; // replace with real password

*/ 

/// default IP addresses, supposed to be replaced by
// actual IP addresses assigned by Soft AP
#define HOUSTON_IP     192,168,4,1
#define GATECONTROL_IP 192,168,4,100

// UDP message params
#define MSG_RETRY_PERIOD 500
#define MSG_RETRY_COUNT 5
#define UDP_SEND_DELAY 1

// 10 minutes limit for voice comm
#define VOICE_TIME_LIMIT 600000L

enum {
      INTERCOM_MSG_OK,
      INTERCOM_MSG_PING, 
      INTERCOM_MSG_BELL, 
      INTERCOM_MSG_UNLOCK,
      INTERCOM_MSG_CONNECT,
      INTERCOM_MSG_HANGUP,
      INTERCOM_MSG_UNKNOWN_KEY,
      INTERCOM_MSG_KEYRING,
      INTERCOM_MSG_NUM
};

enum {
      HANDSET_STATUS_NONE = 0,
      HANDSET_STATUS_DISCONNECTED,
      HANDSET_STATUS_IDLE,
      HANDSET_STATUS_RINGING,
      HANDSET_STATUS_VOICE,
      HANDSET_STATUS_VOICE_MUTE
};


#endif
