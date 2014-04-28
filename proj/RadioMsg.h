
#ifndef RADIO_MSG_H
#define RADIO_MSG_H

typedef nx_struct radio_msg {
  nx_uint16_t dest;
  nx_uint16_t id;
} radio_msg_t;

enum {
  AM_RADIO_MSG = 6,
};

#endif
