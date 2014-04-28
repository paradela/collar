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
    interface FoodInfo as FeedingSpot;
  }
}
implementation {

  message_t packet;
  food_info food;

  bool locked;
  uint16_t lastMsg = -1;
  	
  
  animals_pos_t animals_locations[10000]; //last known positions
  uint16_t feeding_spots[100]; //food in spots
  
  uint16_t eaten = 0;
  uint16_t can_eat = 0;
  
  
  event void Boot.booted() {
    call FeedingSpot.initFoodInfo();  
	call MilliTimer.startPeriodic(200);
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(60000); // 1 minute = 60000
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {

	uint16_t sensor;
	position_t p; 
	radio_msg_t* rcm;
    
    if (locked) {
		return;
    }
    else {
		sensor = call FeedingSpot.sense();
		
		//dbg("RadioMsgC", "Sensor: %d \n", sensor);
		
		if (sensor) {
			food = call FeedingSpot.getFoodInfo();
			dbg("RadioMsgC", "There are %dkg of food left in the FSpot.\n This animal is allowed to eat %dkg of food.\n", food.quantity_tot, food.quantity_ind);		
		}
			
		rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
		if (rcm == NULL) {
		  return;
		}
		p = call gps.getPosition();
		rcm->type = MY_LOCATION;
		rcm->id = rand();
		rcm->src = TOS_NODE_ID;
		rcm->dest = 0;
		rcm->x = p.x;
		rcm->y = p.y;
		rcm->spot = 0;
		rcm->quantity = 0;

		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
		  locked = TRUE;
		}
	  }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
	position_t pos;
	uint16_t i;
	uint16_t v;
    dbg("RadioMsgC", "Receive\n");
    
    /*call FeedingSpot.setBichoFood(rcm->id);
      food = call FeedingSpot.getFoodInfo();
      dbg("RadioMsgC", "Teste do update da comida do bicho: %d\n", food.quantity_ind); */
    
    if (len != sizeof(radio_msg_t)) {return bufPtr;}
    else {
		bool broadcast = FALSE;
		radio_msg_t* rcm = (radio_msg_t*)payload;
		
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
				if(rcm->dest == TOS_NODE_ID){ //DESTINATION
					pos = call gps.getPosition();
					dbg("RadioMsgC", "My Location is: x=%d y=%d\n", pos.x, pos.y);
				}
				else {
					animals_pos_t p = animals_locations[rcm->dest];
					if(p.x != 0 && p.y != 0) {
						dbg("RadioMsgC", "Last Location known of node %d is: x=%d y=%d\n", rcm->dest, p.x, p.y);
					}
					broadcast = TRUE;
				}
				break;
			case GET_EATEN_FOOD:
				if(rcm->dest == TOS_NODE_ID){ //DESTINATION
					dbg("RadioMsgC", "My stomach is empty :( \n");
				}
				else broadcast = TRUE;
				break;
			case GET_LEFT_FOOD:
				for(i = 0; i < 100; i++){
					if(feeding_spots[i] != 0) {
						dbg("RadioMsgC", "FS have %d Kg of food\n", feeding_spots[i]);
					}
				}
				dbg("RadioMsgC", "(Those feeding spots not listed are empty)\n");
				broadcast = TRUE;
				break;
			case UPDT_ANIMAL_FOOD:
				if(rcm->dest == TOS_NODE_ID){ //DESTINATION
					can_eat = rcm->quantity;
					dbg("RadioMsgC", "YEY! Now I can eat %d Kg everyday!\n", can_eat);
				}
				else broadcast = TRUE;
				break;
			case UPDT_SPOT_FOOD:
				feeding_spots[rcm->spot] = rcm->quantity;
				dbg("RadioMsgC", "FS %d has %d Kg of food available\n", rcm->spot, rcm->quantity);
				broadcast = TRUE;
				break;
			case MY_LOCATION:
				animals_locations[rcm->src].x = rcm->x;
				animals_locations[rcm->src].y = rcm->y;
				dbg("RadioMsgC", "Animal %d announced is location at x=%d y=%d\n", rcm->src, rcm->x, rcm->y);
				broadcast = TRUE;
				break;
			case EATEN_FROM_SPOT:
				v = feeding_spots[rcm->spot];
				v -= rcm->quantity;
				if(v >= 0){
					feeding_spots[rcm->spot] = v;
				}
				else feeding_spots[rcm->spot] = 0;
				dbg("RadioMsgC", "FS %d has %d Kg less\n", rcm->spot, v);
				broadcast = TRUE;
				break;
		}
	  
		if(!locked && broadcast){
		  radio_msg_t* msg = (radio_msg_t*)(call Packet.getPayload(&packet, sizeof(radio_msg_t)));
		  msg->type = rcm->type;
		  msg->id = rcm->id;
		  msg->src = rcm->src;
		  msg->dest = rcm->dest;
		  msg->x = rcm->x;
		  msg->y = rcm->y;
		  msg->spot = rcm->spot;
		  msg->quantity = rcm->quantity;
		  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
			  locked = TRUE;
		  }
		}
	  }
      return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}




