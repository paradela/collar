#include "Timer.h"
#include "RadioMessage.h"

module RadioC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
	interface AMPacket;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  
  event void Boot.booted() {
	  dbg("RadioC", "Node %d booted\n", TOS_NODE_ID);
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
    //dbg("RadioC", "RadioC: timer fired\n");
    if (locked) {
      return;
    }
    else {
      radio_msg_t* rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
      if (rcm == NULL) {
	return;
      }
      
      rcm->msg_id = 0;
      rcm->dest = 1;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
		  dbg("RadioC", "Packet sent.\n");	
		  locked = TRUE;
      }
      
    }
    
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
	dbg("RadioC", "Receive\n");				   
    if (len != sizeof(radio_msg_t)) {return bufPtr;}
    else {
      radio_msg_t* rcm = (radio_msg_t*)payload;
      dbg("RadioC", "Received packet. ID: %d.\n", rcm->msg_id);
      
      if(rcm->dest == TOS_NODE_ID){
		  dbg("RadioC", "Message reached destination.\n");
	  }
	  else {
		  if(!locked){
			  //packet = *bufPtr;
			  radio_msg_t* msg = (radio_msg_t*)(call Packet.getPayload(&packet, sizeof(radio_msg_t)));
			  msg->dest = rcm->dest;
			  msg->msg_id = rcm->msg_id;
			  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
				  dbg("RadioC", "Packet broadcasted. Destination %d\n", msg->dest);	
				  locked = TRUE;
			  }
		  }
	  }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
	  radio_msg_t* msg = (radio_msg_t*) call Packet.getPayload(bufPtr, sizeof(radio_msg_t));
	  dbg("RadioC", "msg id: %d\n", msg->msg_id);
    if (&packet == bufPtr) {
		if(error == SUCCESS)
			dbg("RadioC", "Send Done Successfuly\n");
		else dbg("RadioC", "Send failed\n");
      locked = FALSE;
    }
  }

}




