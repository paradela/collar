#include "Timer.h"
#include "RadioMsg.h"
#include "gps.h"

module RadioMsgC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface gps;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t lastMsg = -1;
  uint16_t lastFoodUpdate = -1;
  uint16_t lastFoodUMsg = -1;
  
  animals_pos_t animals_locations[10000];
  
  uint16_t feeding_spots[100];
  
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(250);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    /*counter++;
    
    dbg("RadioMsgC", "RadioMsgC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
      radio_msg_t* rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
      if (rcm == NULL) {
	return;
      }
      
      rcm->dest = 2;
      rcm->id = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
	dbg("RadioMsgC", "RadioMsgC: packet sent.\n", counter);	
	locked = TRUE;
      }
    }*/
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
	position_t pos;
	uint16_t p;
	uint16_t x;
	uint16_t y;
	animals_pos_t pos_a;
	
    if (len == sizeof(location_msg_t)) {
		bool broadcast = FALSE;
		
		location_msg_t* rcm = (location_msg_t*)payload;
		dbg("RadioMsgC", "Received packet. ID: %d.\n", rcm->id);
      
		if(rcm->id == lastMsg){
			return bufPtr;
		}
		else lastMsg = rcm->id;
		
		switch(rcm->type){
			case GET_LOCATION:
				if(rcm->dest == TOS_NODE_ID){ //DESTINATION
					pos = call gps.getPosition();
					dbg("RadioMsgC", "My Location is: x=%d y=%d\n", pos.x, pos.y);
				}
				else broadcast = TRUE;
				break;
			case GET_LAST_LOCATION:
				//check if knows location, and breadcast
				broadcast = TRUE;
				break;
			case UPDATE_LOCATION:
				p = rcm->src;
				x = rcm->x;
				y = rcm->y;
		
				pos_a = animals_locations[p];
		
				if(pos_a.x != x || pos_a.y != y) { //check if message was already received
					pos_a.x = x;
					pos_a.y = y;
					animals_locations[p] = pos_a;
					broadcast = TRUE;
				}
				break;
		}
		
		if(!locked && broadcast){ //BROADCAST
			location_msg_t* msg = (location_msg_t*)(call Packet.getPayload(&packet, sizeof(location_msg_t)));
			msg->dest = rcm->dest;
			msg->src = rcm->src;
			msg->id = rcm->id;
			msg->x = rcm->x;
			msg->y = rcm->y;
			msg->type = rcm->type;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(location_msg_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
		return bufPtr;
	}
	else if (len == sizeof(food_msg_t)) {
		bool broadcast = FALSE;
		
		food_msg_t * rcm = (food_msg_t*)payload;
		
		if(rcm->id == lastMsg){
			return bufPtr;
		}
		else lastMsg = rcm->id;
		
		switch(rcm->type){
			case GET_ANIMAL_EATEN_FOOD:
				if(rcm->dest == TOS_NODE_ID){
					dbg("RadioMsgC", "Ja comi isto:\n");
				}
				else broadcast = TRUE;
				break;
			case GET_FOOD_LEFT:
				dbg("RadioMsgC", "Ainda resta:\n");
				broadcast = TRUE;
				break;
			case UPDATE_FOOD:
				dbg("RadioMsgC", "Comida actualizada:\n");
				broadcast = TRUE;
				break;
		}
		
		if(!locked && broadcast){ //BROADCAST
			food_msg_t* msg = (food_msg_t*)(call Packet.getPayload(&packet, sizeof(food_msg_t)));
			msg->id = rcm->id;
			msg->dest = rcm->dest;
			msg->quantity = rcm->quantity;
			msg->type = rcm->type;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(food_msg_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
	}
	else if (len == sizeof(a2a_food_eaten_msg_t)) {
		
		a2a_food_eaten_msg_t* rcm = (a2a_food_eaten_msg_t*)payload;
		int16_t v = feeding_spots[rcm->id];
		
		if(rcm->src != lastFoodUpdate || rcm->src != lastFoodUMsg) {
			v -= rcm->quantity;
			if(v >= 0){
				feeding_spots[rcm->id] = v;
			}
			else feeding_spots[rcm->id] = 0;
			
			if(!locked){ //BROADCAST
				a2a_food_eaten_msg_t* msg = (a2a_food_eaten_msg_t*)(call Packet.getPayload(&packet, sizeof(a2a_food_eaten_msg_t)));
				msg->src = rcm->src;
				msg->msg = rcm->msg;
				msg->id = rcm->id;
				msg->quantity = rcm->quantity;
				if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(a2a_food_eaten_msg_t)) == SUCCESS) {
					locked = TRUE;
				}
			}
		}
	}
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




