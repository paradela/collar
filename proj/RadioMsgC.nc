#include "Timer.h"
#include "RadioMsg.h"

module RadioMsgC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  
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
    counter++;
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
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("RadioMsgC", "Received packet of length %hhu.\n", len);
    if (len != sizeof(radio_msg_t)) {return bufPtr;}
    else {
      radio_msg_t* rcm = (radio_msg_t*)payload;
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




