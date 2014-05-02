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
				if(v >= rcm->quantity)
					v -= rcm->quantity;
				else v = 0;
				
				feeding_spots[rcm->spot] = v;
				
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
 
  command food_info FeedingSpot.getFoodInfo(uint16_t id){
    return animals_food[id];
  }
  
	command void FeedingSpot.warnAboutFS(){
		
		radio_msg_t* rcm;
		
		uint16_t id_fspot = rand() % 10;
		
		uint16_t fspot_quant;
		uint16_t daily_quant;
		uint16_t cons_quant;
		uint16_t order_quant;
				
		animals_food[TOS_NODE_ID] = call FeedingSpot.getFoodInfo(TOS_NODE_ID);
		daily_quant = animals_food[TOS_NODE_ID].quantity_ind; //how much food the animal can eat per day
		cons_quant = animals_food[TOS_NODE_ID].quantity_tot; //how much food the animal already ate
		order_quant = daily_quant - cons_quant; //how much food the animal can still eat
			
		fspot_quant = feeding_spots[TOS_NODE_ID]; //how much food is in the wanted fspot
		
		dbg("RadioMsgC", "Animal %d is approaching fspot %d and wants to eat %dkg.\n This fspot has %dkg left.\n", TOS_NODE_ID, id_fspot, order_quant, fspot_quant);
		
		//check if the animal already ate his portion
		if(!order_quant){
			dbg("RadioMsgC", "He already ate his allowed %kg per day.\n", daily_quant);
		}	
		
		//check if the animal still hasn't eaten his portion
		if(cons_quant < daily_quant){
			//if there is enough food, proceed has usual
			if(fspot_quant >= order_quant){ 
				animals_food[TOS_NODE_ID].quantity_tot += order_quant;
				dbg("RadioMsgC", "There is enough, he'll take %dkg!\n", order_quant);
			}
			//if there isn't enough he only asks for what is there
			else { 
				order_quant = fspot_quant;
				animals_food[TOS_NODE_ID].quantity_tot += order_quant;
				dbg("RadioMsgC", "Ok, he'll just take the %dkg available, though he still wanted %dkg more.\n", order_quant, daily_quant-order_quant);
			}

		}	
		
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
		rcm->quantity = order_quant;

		call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t));
	}

}




