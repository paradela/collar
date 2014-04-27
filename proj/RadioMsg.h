#ifndef RADIO_MSG_H
#define RADIO_MSG_H

#define GET_LOCATION 0
#define GET_LAST_LOCATION 1
#define UPDATE_LOCATION 2
#define GET_ANIMAL_EATEN_FOOD 0
#define GET_FOOD_LEFT 1
#define UPDATE_FOOD 2

typedef nx_struct location_msg {
	nx_uint16_t id;
	nx_uint16_t src;
	nx_uint16_t dest;
	nx_uint16_t x;
	nx_uint16_t y;
	nx_uint8_t type; 
} location_msg_t; //size 88bits

typedef nx_struct food_msg {
	nx_uint16_t id;
	nx_uint16_t dest;
	nx_uint8_t quantity;
	nx_uint8_t type;
} food_msg_t; //size 48bits

typedef nx_struct a2a_food_eaten_msg {
	nx_uint16_t src;
	nx_uint8_t msg;
	nx_uint8_t id;
	nx_uint8_t quantity;
} a2a_food_eaten_msg_t; // size 40bits

enum {
  AM_RADIO_MSG = 6,
};

typedef struct animals_pos {
	uint16_t x;
	uint16_t y;
} animals_pos_t;


#endif
