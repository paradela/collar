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
  	
  
  
  event void Boot.booted() {
    call FeedingSpot.initFoodInfo();  
	call MilliTimer.startPeriodic(200);
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      //
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
	}
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
	position_t pos;
	
	dbg("RadioMsgC", "Receive\n");				   
    if (len != sizeof(radio_msg_t)) {return bufPtr;}
    else {
      radio_msg_t* rcm = (radio_msg_t*)payload;
      dbg("RadioMsgC", "Received packet. ID: %d.\n", rcm->id);
      /*call FeedingSpot.setBichoFood(rcm->id);
      food = call FeedingSpot.getFoodInfo();
      dbg("RadioMsgC", "Teste do update da comida do bicho: %d\n", food.quantity_ind); */
      
      if(rcm->id == lastMsg){
		  dbg("RadioMsgC", "Message discarded. ID: %d.\n", rcm->id);
		  return bufPtr;
	  }
	  else lastMsg = rcm->id;
      
      if(rcm->dest == TOS_NODE_ID){
		  dbg("RadioMsgC", "Message reached destination.\n");
		   pos = call gps.getPosition();
		  dbg("RadioMsgC", "Location: x=%d y=%d\n", pos.x, pos.y);
	  }
	  else {
		  if(!locked){
			  radio_msg_t* msg = (radio_msg_t*)(call Packet.getPayload(&packet, sizeof(radio_msg_t)));
			  msg->dest = rcm->dest;
			  msg->id = rcm->id;
			  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
				  dbg("RadioMsgC", "Packet broadcasted. Destination %d\n", msg->dest);	
				  locked = TRUE; 
			  }
		  }
	  }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}




