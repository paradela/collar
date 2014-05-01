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
   provides interface FoodInfo as FeedingSpot;
}
implementation {

  message_t packet;

  bool locked;
  uint16_t lastMsg = -1;
  	
  
  animals_pos_t animals_locations[10000]; //last known positions
  uint16_t feeding_spots[100]; //food in spots
  food_info animals_food[10000];
  
  uint16_t eaten = 0;
  uint16_t can_eat = 0;
  
 
  event void Boot.booted() {
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

	position_t p; 
	radio_msg_t* rcm;
    
    if (locked) {
		return;
    }
    else {
			
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
					animals_food[rcm->dest] = call FeedingSpot.getFoodInfo(rcm->dest);
					if(!animals_food[rcm->dest].quantity_tot)
						dbg("RadioMsgC", "My stomach is empty :( \n");
					else 
						dbg("RadioMsgC", "Today I ate %dkg of food! \n", animals_food[rcm->dest].quantity_tot);
				}
				else broadcast = TRUE;
				break;
			case GET_LEFT_FOOD:
				for(i = 0; i < 100; i++){
					if(feeding_spots[i] != 0) {
						dbg("RadioMsgC", "FS %d has %d Kg of food\n", i, feeding_spots[i]);
					}
				}
				dbg("RadioMsgC", "(Those feeding spots not listed are empty)\n");
				broadcast = TRUE;
				break;
			case UPDT_ANIMAL_FOOD:
				if(rcm->dest == TOS_NODE_ID){ //DESTINATION
					animals_food[rcm->dest] = call FeedingSpot.getFoodInfo(rcm->dest);
					animals_food[rcm->dest].quantity_ind = rcm->quantity;
					dbg("RadioMsgC", "YEY! Now I can eat %d Kg everyday!\n", animals_food[rcm->dest].quantity_ind);
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
				broadcast = TRUE;
				break;
			case EATEN_FROM_SPOT:
				v = feeding_spots[rcm->spot];
				v -= rcm->quantity;
				if(v >= 0){
					feeding_spots[rcm->spot] = v;
					if (v >= animals_food[rcm->dest].quantity_ind)
						animals_food[rcm->dest].quantity_tot = rcm->quantity; 
					else 
						animals_food[rcm->dest].quantity_tot += v;
				}
				else feeding_spots[rcm->spot] = 0;
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
  
  command uint16_t FeedingSpot.sense() {
	uint16_t bicho_near;
	
	bicho_near = (rand() % 2); //random to determine if there's an animal nearby or not
	
	return bicho_near;
 }
 

  command food_info FeedingSpot.getFoodInfo(uint16_t id){
    return animals_food[id];
  }
  
	command void FeedingSpot.warnAboutFS(uint16_t quant){
		
		radio_msg_t* rcm;
		uint16_t id_fspot = rand() % 20;
		
		dbg("RadioMsgC", "Animal %d is approxing fspot %d.\n", TOS_NODE_ID, id_fspot);	
					
		rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
					
		if (rcm == NULL) {
			return;
		}
		rcm->type = EATEN_FROM_SPOT;
		rcm->id = rand();
		rcm->src = 0;
		rcm->dest = 0;
		rcm->x = 0;
		rcm->y = 0;
		rcm->spot = id_fspot;
		rcm->quantity = quant;

		call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t));
	}

}




