#ifndef RADIO_MSG_H
#define RADIO_MSG_H

#define GET_LOCATION 0
#define GET_LAST_LOCATION 1
#define GET_EATEN_FOOD 2
#define GET_LEFT_FOOD 3
#define UPDT_ANIMAL_FOOD 4
#define UPDT_SPOT_FOOD 5

#define MY_LOCATION 6
#define EATEN_FROM_SPOT 7

typedef nx_struct radio_msg {
	/*  HEADER     */
	nx_uint8_t type; 
  	nx_uint16_t id;	 
	nx_uint16_t src; 
	nx_uint16_t dest;
	/*  END_HEADER */
	
	/*	LOCATION	*/
	nx_uint16_t x;
	nx_uint16_t y;
	/*END_LOCATION*/
	
	/*	FOOD		*/
	nx_uint8_t spot;
	nx_uint8_t quantity;
	/*	END_FOOD	*/
	 
} radio_msg_t;

enum {
  AM_RADIO_MSG = 20,
};

typedef struct animals_pos {
uint16_t x;
uint16_t y;
} animals_pos_t;

#endif
