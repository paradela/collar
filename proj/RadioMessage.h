#ifndef RADIO_MESSAGE_H
#define RADIO_MESSAGE_H

typedef nx_struct radio_msg {
  nx_uint16_t msg_id;
  nx_uint16_t dest;
} radio_msg_t;

enum {
  AM_RADIO_MSG = 6,
};

#endif
