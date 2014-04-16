#include <Timer.h>
#include "BlinkToRadio.h"
#include <stdio.h>

module BlinkToRadioC {
	uses interface Boot;
	uses interface Leds;
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

	event void Boot.booted() {
		printf("Boot: I'm the node %d\n", TOS_NODE_ID);
		call AMControl.start();
	}
   
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			printf("Started: I'm the node %d\n", TOS_NODE_ID);
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			printf("Start: I'm the node %d\n", TOS_NODE_ID);
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		printf("StopDone: I'm the node %d\n", TOS_NODE_ID);
	}

	event void Timer0.fired() {
		counter++;
		call Leds.set(counter);
		printf("Timer0.fired: I'm the node %d\n", TOS_NODE_ID);
    
		if (!busy && (TOS_NODE_ID == 0 || TOS_NODE_ID == 1)) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->counter = counter;
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
  
	event void AMSend.sendDone(message_t* msg, error_t error) {
		printf("SendDone: I'm the node %d\n", TOS_NODE_ID);
		if (&pkt == msg) {
			busy = FALSE;
		}
	}
  
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		printf("Receive: I'm the node %d\n", TOS_NODE_ID);
		
		if(TOS_NODE_ID == 0) {
			return msg;
		}
		
		if (len == sizeof(BlinkToRadioMsg)) {
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
			call Leds.set(btrpkt->counter);
			printf("receive: node_id = %d counter = %d\n", btrpkt->nodeid, btrpkt->counter);
		}
    
		return msg;
	}
}
