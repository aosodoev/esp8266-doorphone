#include <FS.h>

extern "C" {

#include <g722.h>
#include <g722_private.h>
#include <g722_decoder.h>
#include <g722_encoder.h>

}

#include <SPI.h>

#ifndef PT8211
#include "lltwi.h"
#include <Wire.h>
#endif

#include "doorphone.h"
#include "audio.h"

// #define ADC8BIT

#define SAMPLE_BUFFERS 4
#define SAMPLE_BUFFER_LEN 1024
#define ADC_SAMPLE_BUFFER_LEN 256
#define ADC_CS 15

typedef struct {
  int16_t samples[SAMPLE_BUFFER_LEN];
  size_t len;
  size_t pos;
} sample_buffer;

// #define I2S_PDM

struct {
  File f;
  WiFiUDP udp, udp_tx;
  IPAddress dest;
  sample_buffer buffer[SAMPLE_BUFFERS];
  volatile int rbuf;
  volatile int wbuf;
  volatile enum {STREAMING_NONE = 0, STREAMING_FILE, STREAMING_UDP} playing = STREAMING_NONE;
  volatile bool output = false;
  volatile bool sampling = false;
  bool eof;
  byte data[SAMPLE_BUFFER_LEN/2];
  size_t bytes = 0;


  int16_t adc_buf[2][ADC_SAMPLE_BUFFER_LEN];
  volatile size_t adc_wbuf = 0;
  volatile size_t adc_bufpos = 0;
  volatile bool adc_buf_ready = 0;

} g722stream;

static g722_decode_state *g722_dec_state;
static g722_encode_state *g722_enc_state;

void audio_buffer_write(sample_buffer *buffer, size_t bytes, byte *data) {
  int nsamples = g722_decode(g722_dec_state, data, bytes, buffer->samples);
  buffer->len = nsamples;
  buffer->pos = 0;
  g722stream.wbuf = (g722stream.wbuf + 1) % SAMPLE_BUFFERS;
  if (g722stream.wbuf == 2 && !g722stream.output) {
    g722stream.output = true;
    DPRINTF("Starting Audio Output!");
  }
}

int audio_playing() {
  return g722stream.playing;
}

void audio_streaming_end();

void audio_buffer_loop() {

  if (g722stream.playing) {  
    if (g722stream.playing == g722stream.STREAMING_UDP) {
      g722stream.bytes = g722stream.udp.parsePacket();
      if (g722stream.bytes) {
	g722stream.bytes = g722stream.udp.read(g722stream.data, sizeof(g722stream.data));
	if (g722stream.buffer[g722stream.wbuf].len != 0) { // overflow
	  g722stream.bytes = 0; // drop new data
	}
      }
    } else if (!g722stream.eof && (g722stream.buffer[g722stream.wbuf].len == 0)) {
      g722stream.bytes = g722stream.f.read(g722stream.data, sizeof(g722stream.data));
      if (g722stream.bytes < sizeof(g722stream.data)) {
	g722stream.f.close();
	g722stream.eof = true;
	DPRINTF("Reached end of file");
      }	   
    }

    if (g722stream.bytes > 0) {
      audio_buffer_write(&g722stream.buffer[g722stream.wbuf], g722stream.bytes, g722stream.data);
      g722stream.bytes = 0;
    }
  }

  if (g722stream.sampling && g722stream.adc_buf_ready) {
    byte packet[ADC_SAMPLE_BUFFER_LEN];
    size_t len = g722_encode(g722_enc_state, g722stream.adc_buf[!g722stream.adc_wbuf], ADC_SAMPLE_BUFFER_LEN, packet);
    g722stream.adc_buf_ready = 0;
    g722stream.udp_tx.beginPacket(g722stream.dest, VOICE_PORT);
    g722stream.udp_tx.write(packet, len);
    g722stream.udp_tx.endPacket();
  }
}

void audio_buffer_init() {
  g722stream.wbuf = 0;
  g722stream.rbuf = 0;

  for (int i = 0; i<SAMPLE_BUFFERS; i++) {
    g722stream.buffer[i].len = 0;
    g722stream.buffer[i].pos = 0;
  }

  g722stream.eof = false;
}

#ifndef PT8211

static inline uint8_t write_dac(uint16_t value) {
  /* value is 76543210 XXXXBA98
     per the datasheet for fast write:
     1 1 0 0 A2 A1 A0 0 <ACK> 0 0 PD1 PD0 D11 D10 D9 D8 <ACK> D7 D6 D5 D4 D3 D2 D1 D0 <ACK> 
  */

  uint8_t buf[2] = { (uint8_t)((value >> 8) & 0x0F), (uint8_t)(value & 0xFF) };
  int ret = lltwi_writeTo(0x62, buf, 2, true);
  return ret;
}

#endif

void ICACHE_RAM_ATTR audio_isr() {

  int16_t sample, sampleOutput = 0;

  static uint32_t next = ESP.getCycleCount();
  
#ifdef PT8211

  if (g722stream.output) {
    sample_buffer *buffer = &g722stream.buffer[g722stream.rbuf];

    if (buffer->len) {
      sampleOutput = buffer->samples[buffer->pos++];
      if (buffer->pos == buffer->len) {
	buffer->pos = 0;
	buffer->len = 0;
	g722stream.rbuf = (g722stream.rbuf + 1) % SAMPLE_BUFFERS;
      }
    } else if (g722stream.eof) {
      audio_streaming_end();
    }
  }

  if (g722stream.sampling || g722stream.output) {
    // while(SPI1CMD & SPIBUSY) {}
    digitalWrite(ADC_CS, HIGH);
  }
  
  // read a sample from ADC
  if (g722stream.sampling) {  
#ifdef ADC8BIT
    sample = (SPI1W0 << 8) ^ 32768;
#else
    uint16_t result = SPI1W0 & 0xFFFF;
    result = (((result >> 8) | (result << 8)) >> 1) & 0xFFF;
    sample = (result << 4) ^ 32768;
#endif
    // digitalWrite(ADC_CS, HIGH);
    // window[idx & 3] = sample;
    // sample = (window[0] + window[1] + window[2] + window[3]) / 4;
    // idx++;
    
    // If the buffer is full, signal it's ready to be sent and switch to the other one
    g722stream.adc_buf[g722stream.adc_wbuf][g722stream.adc_bufpos++] = sample;
    if (g722stream.adc_bufpos == ADC_SAMPLE_BUFFER_LEN) {
      g722stream.adc_bufpos = 0;
      g722stream.adc_wbuf = !g722stream.adc_wbuf;
      g722stream.adc_buf_ready = 1;
    }
  }

  // Initiate next SPI transfer
  if (g722stream.sampling || g722stream.output) {
    digitalWrite(ADC_CS, LOW);
    SPI1W0 = sampleOutput << 8 | sampleOutput >> 8;
    SPI1CMD |= SPIBUSY;
  }
  
#else

  if (g722stream.sampling) {  
    while(SPI1CMD & SPIBUSY) {}
    digitalWrite(ADC_CS, HIGH);
#ifdef ADC8BIT
    sample = (SPI1W0 << 8) ^ 32768;
#else
    uint16_t result = SPI1W0 & 0xFFFF;
    result = (((result >> 8) | (result << 8)) >> 1) & 0xFFF;
    sample = (result << 4) ^ 32768;
#endif
    // window[idx & 3] = sample;
    // sample = (window[0] + window[1] + window[2] + window[3]) / 4;
    // idx++;
    
    // If the buffer is full, signal it's ready to be sent and switch to the other one
    g722stream.adc_buf[g722stream.adc_wbuf][g722stream.adc_bufpos++] = sample;
    if (g722stream.adc_bufpos == ADC_SAMPLE_BUFFER_LEN) {
      g722stream.adc_bufpos = 0;
      g722stream.adc_wbuf = !g722stream.adc_wbuf;
      g722stream.adc_buf_ready = 1;
    }
  }

  if (g722stream.output) {
    sample_buffer *buffer = &g722stream.buffer[g722stream.rbuf];

    if (buffer->len) {
      sampleOutput = buffer->samples[buffer->pos++];
      write_dac(((uint16_t)sampleOutput ^ 32768) >> 4);
      if (buffer->pos == buffer->len) {
	buffer->pos = 0;
	buffer->len = 0;
	g722stream.rbuf = (g722stream.rbuf + 1) % SAMPLE_BUFFERS;
      }
    } else if (g722stream.eof) {
      audio_streaming_end();
    }
  }

  // Start reading a new sample from ADC
  if (g722stream.sampling) {
    // while(SPI1CMD & SPIBUSY) {}
    digitalWrite(ADC_CS, LOW);
    SPI1W0 = 0;
    SPI1CMD |= SPIBUSY;
  }


#endif

  next += F_CPU / 16000L;
  if (next <= ESP.getCycleCount()) {
    next = ESP.getCycleCount() + F_CPU / 16000L;
  }

  timer0_write(next);
  
}

void audio_output_begin() {
  g722stream.output = true;
}

void audio_output_end() {
  g722stream.output = false;
}

void audio_SPI_begin();
void audio_SPI_end();

// fname = "UDP" to start streaming from UDP port
void audio_streaming_begin(const char *fname) {
  
  if (g722stream.playing)
    return;

  audio_buffer_init();
  g722stream.output = false;


#ifdef PT8211
  if (!audio_sampling()) {
    audio_SPI_begin();
  }
#endif

  // if (strcmp(fname, UDPSTREAM) == 0) {
  if (fname == UDPSTREAM) {
    DPRINTF("Streaming: UDP");
    g722stream.udp.begin(VOICE_PORT);
    g722stream.playing = g722stream.STREAMING_UDP;
  } else {
    g722stream.f = SPIFFS.open(fname, "r");
    if (!g722stream.f) {
      DPRINTF("%s open failed", fname);
      return;
    } else {
      DPRINTF("Streaming: %s", fname);
      DPRINTF("heap: %d", ESP.getFreeHeap());
      g722stream.playing = g722stream.STREAMING_FILE;
    }
  }
  // audio_output_begin();
}

void audio_streaming_end() {
  if (g722stream.playing) {
    if ((g722stream.playing == g722stream.STREAMING_FILE) && !g722stream.eof) {
      g722stream.f.close();
    }
    if (g722stream.playing == g722stream.STREAMING_UDP) {
      g722stream.udp.stop();
    }
    g722stream.playing = g722stream.STREAMING_NONE;
    audio_output_end();

#ifdef PT8211
    if (!g722stream.sampling) {
      audio_SPI_end();
    }
#endif

    DPRINTF("Audio stopped");
  }
}

void audio_init() {
  // initialize g722 codec contexts
  g722_enc_state = g722_encoder_new(64000, 0);
  g722_dec_state = g722_decoder_new(64000, 0);
  // g722_decoder_init(&g722_dec_state, 64000, 0);
  
#ifndef PT8211
  Wire.begin(LLTWI_SDA, LLTWI_SCL);
#endif

  pinMode(ADC_CS, OUTPUT);
  digitalWrite(ADC_CS, HIGH);

  noInterrupts();
  timer0_isr_init();
  timer0_attachInterrupt(audio_isr);
  timer0_write(ESP.getCycleCount() + F_CPU/16000);
  interrupts();
  
  // timer1_isr_init();
  // timer1_attachInterrupt(audio_isr);
  // timer1_enable(TIM_DIV1, TIM_EDGE, TIM_LOOP);
  // timer1_write(5000); // 3628 = 22050, 5000 = 16000
}

inline void SPI_setDataBits(uint16_t bits) {
  const uint32_t mask = ~((SPIMMOSI << SPILMOSI) | (SPIMMISO << SPILMISO));
  bits--;
  SPI1U1 = ((SPI1U1 & mask) | ((bits << SPILMOSI) | (bits << SPILMISO)));
}

void audio_SPI_begin() {


#ifdef ADC8BIT
  SPI.beginTransaction(SPISettings(2000000L, MSBFIRST, SPI_MODE0));
  // SPI.setClockDivider(SPI_CLOCK_DIV8);
  // SPI.setClockDivider(SPI_CLOCK_DIV16);
  SPI.setHwCs(false);
  SPI_setDataBits(8);
#else
  SPI.beginTransaction(SPISettings(20000000L, MSBFIRST, SPI_MODE0));
  SPI.setHwCs(false);
  SPI.write16(0); // set data bits 16
#endif


  DPRINTF("Audio SPI begin!");

  return;
  
  SPI.setDataMode(SPI_MODE0);
  SPI.setBitOrder(MSBFIRST);
#ifdef ADC8BIT
  SPI.setClockDivider(SPI_CLOCK_DIV8);
  // SPI.setClockDivider(SPI_CLOCK_DIV16);
  SPI_setDataBits(8);
#else
  SPI.setClockDivider(SPI_CLOCK_DIV4);
  SPI_setDataBits(16);
#endif
  SPI.setHwCs(false);
  pinMode(ADC_CS, OUTPUT);
  digitalWrite(ADC_CS, HIGH);

}

void audio_SPI_end() {
  SPI.endTransaction();
  return;
  SPI.setClockDivider(SPI_CLOCK_DIV4);
  SPI.setHwCs(false);
}


void audio_sampling_begin(IPAddress dest) {
  if (!g722stream.sampling) {

#ifdef PT8211
    if (!audio_playing()) {
      audio_SPI_begin();
    }
#else
    audio_SPI_begin();
#endif
    
    g722stream.dest = dest;
    g722stream.sampling = true;

    DPRINTF("Streaming audio to: %s", dest.toString().c_str());
  }
}

void audio_sampling_end() {
  if (g722stream.sampling) {
    g722stream.sampling = false;
#ifdef PT8211
    if (!audio_playing()) {
      audio_SPI_end();
    }
#else
    audio_SPI_end();
#endif
  }
}

bool audio_sampling() {
  return g722stream.sampling;
}
