#ifndef __WEB_UI_H__
#define __WEB_UI_H

#include<Arduino.h>

bool add_key(const char *key);
bool delete_key(const char *key);
char* settings_json();
void set_ringtone(const char *ringtone);


void setupWebUI();
void loopWebUI();
void broadcastSettings();

#endif
