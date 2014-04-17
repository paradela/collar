#include <Timer.h>
#include "BlinkToRadio.h"
#include <stdio.h>

module BlinkToRadioC {
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
}
implementation {
	
	uint16_t counter = 0;
	bool busy = FALSE;
	message_t pkt;
	uint16_t lastMsg = -1;

	event void Boot.booted() {
		call AMControl.start();
	}
   
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event void Timer0.fired() {
		
		/*if(TOS_NODE_ID == counter){
    
			if (!busy && (TOS_NODE_ID == 0 || TOS_NODE_ID == 1)) {
				BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
				btrpkt->nodeid = 2;
				btrpkt->counter = counter;
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
					busy = TRUE;
					dbg("BlinkC", "Message send on fired\n");
				}
			}
		}
		else counter++;
		*/
		
	}
  
	event void AMSend.sendDone(message_t* msg, error_t error) {
		dbg("BlinkC","SendDone\n");
		if (&pkt == msg) {
			busy = FALSE;
		}
	}
  
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		dbg("BlinkC","received message\n");
		
		
		
		if (len == sizeof(BlinkToRadioMsg)) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
			
			if(btrpkt->counter == lastMsg)
				return msg;
			else lastMsg = btrpkt->counter;
			
			if(btrpkt->nodeid == TOS_NODE_ID){
				dbg("BlinkC","receive: node_id = %d counter = %d\n", btrpkt->nodeid, btrpkt->counter);	
			}
			else {
				BlinkToRadioMsg* btr = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
				btr->nodeid = btrpkt->nodeid;
				btr->counter = btrpkt->counter;
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
					busy = TRUE;
					dbg("BlinkC", "Message sent\n");
				}
			}
			
		
		}
    
		return msg;
	}
}
