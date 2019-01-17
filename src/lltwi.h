/* 
  twi.h - Software I2C library for esp8266

  Copyright (c) 2015 Hristo Gochkov. All rights reserved.
  This file is part of the esp8266 core for Arduino environment.
 
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
#ifndef LLSI2C_h
#define LLSI2C_h
#include "Arduino.h"

#ifdef __cplusplus
extern "C" {
#endif

#define I2C_OK                      0
#define I2C_SCL_HELD_LOW            1
#define I2C_SCL_HELD_LOW_AFTER_READ 2
#define I2C_SDA_HELD_LOW            3
#define I2C_SDA_HELD_LOW_AFTER_INIT 4

void twi_init(unsigned char sda, unsigned char scl);
void twi_stop(void);
void twi_setClock(unsigned int freq);
void twi_setClockStretchLimit(uint32_t limit);
  // static inline uint8_t twi_writeTo(unsigned char address, unsigned char * buf, unsigned int len, unsigned char sendStop);

  
uint8_t twi_readFrom(unsigned char address, unsigned char * buf, unsigned int len, unsigned char sendStop);
uint8_t twi_status();

  
#ifdef __cplusplus
}
#endif

#ifndef LLTWI_SDA
#define LLTWI_SDA 4
#endif

#ifndef LLTWI_SCL
#define LLTWI_SCL 5
#endif

#define twi_dcount 0
#define twi_clockStretchLimit 10
#define SDA_LOW()   (GPES = (1 << LLTWI_SDA)) //Enable SDA (becomes output and since GPO is 0 for the pin, it will pull the line low)
#define SDA_HIGH()  (GPEC = (1 << LLTWI_SDA)) //Disable SDA (becomes input and since it has pullup it will go high)
#define SDA_READ()  ((GPI & (1 << LLTWI_SDA)) != 0)
#define SCL_LOW()   (GPES = (1 << LLTWI_SCL))
#define SCL_HIGH()  (GPEC = (1 << LLTWI_SCL))
#define SCL_READ()  ((GPI & (1 << LLTWI_SCL)) != 0)

static inline void twi_delay(unsigned char v){
  unsigned int i;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
  unsigned int reg;
  for(i=0;i<v;i++) reg = GPI;
#pragma GCC diagnostic pop
} 

static inline ICACHE_RAM_ATTR bool twi_write_start(void) {
  SCL_HIGH();
  SDA_HIGH();
  if (SDA_READ() == 0) return false;
  SDA_LOW();
  return true;
}

static inline ICACHE_RAM_ATTR bool twi_write_stop(void){
  uint32_t i = 0;
  SCL_LOW();
  SDA_LOW();
  SCL_HIGH();
  while (SCL_READ() == 0 && (i++) < twi_clockStretchLimit); // Clock stretching
  SDA_HIGH();

  return true;
}

static inline ICACHE_RAM_ATTR bool twi_write_bit(bool bit) {
  uint32_t i = 0;
  SCL_LOW();
  if (bit) SDA_HIGH();
  else SDA_LOW();
  twi_delay(twi_dcount+1);
  SCL_HIGH();
  while (SCL_READ() == 0 && (i++) < twi_clockStretchLimit);// Clock stretching
  return true;
}

static inline ICACHE_RAM_ATTR bool twi_read_bit(void) {
  uint32_t i = 0;
  SCL_LOW();
  SDA_HIGH();
  twi_delay(twi_dcount+2);
  SCL_HIGH();
  while (SCL_READ() == 0 && (i++) < twi_clockStretchLimit);// Clock stretching
  bool bit = SDA_READ();
  return bit;
}

static inline ICACHE_RAM_ATTR bool twi_write_byte(unsigned char byte) {
  unsigned char bit;
  for (bit = 0; bit < 8; bit++) {
    twi_write_bit(byte & 0x80);
    byte <<= 1;
  }
  return !twi_read_bit();//NACK/ACK
}

static inline ICACHE_RAM_ATTR unsigned char twi_read_byte(bool nack) {
  unsigned char byte = 0;
  unsigned char bit;
  for (bit = 0; bit < 8; bit++) byte = (byte << 1) | twi_read_bit();
  twi_write_bit(nack);
  return byte;
}

static inline uint8_t lltwi_writeTo(unsigned char address, unsigned char * buf, unsigned int len, unsigned char sendStop){
  unsigned int i;
  if(!twi_write_start()) return 4;//line busy
  if(!twi_write_byte(((address << 1) | 0) & 0xFF)) {
    if (sendStop) twi_write_stop();
    return 2; //received NACK on transmit of address
  }
  for(i=0; i<len; i++) {
    if(!twi_write_byte(buf[i])) {
      if (sendStop) twi_write_stop();
      return 3;//received NACK on transmit of data
    }
  }
  if(sendStop) twi_write_stop();
  i = 0;
  while(SDA_READ() == 0 && (i++) < 10){
    SCL_LOW();
    SCL_HIGH();
  }
  return 0;
}


#endif
