#ifndef G722STREAM_H

#define G722STREAM_H

#include <WiFiUdp.h>

static const char *UDPSTREAM = "UDP";

void audio_buffer_loop();
void audio_streaming_begin(const char *fname);
void audio_streaming_end();
void audio_sampling_begin(IPAddress);
void audio_sampling_end();
int audio_playing();
bool audio_sampling();
void audio_init();

#ifdef I2S_PDM
void audio_output_loop();
#endif


#endif
