#include "FoodInfo.h"
#include "RadioMsg.h"
#include <stdlib.h>
#include <time.h>

module rfidC {
  uses {
    interface Boot;
    interface AMSend;
    interface Packet;
    interface FoodInfo as FeedingSpot;
    interface Timer<TMilli> as MilliTimer;
  }
}

implementation {

	time_t last_update;
	food_info food;

	event void Boot.booted() {
    last_update = time(&last_update);
    call MilliTimer.startPeriodic(15000);
  }


	event void MilliTimer.fired() {

		uint16_t sensor;
		uint16_t id_bicho;
		uint16_t id_fspot;
		uint16_t quant;
		
		message_t packet;
		radio_msg_t* rcm;
		
		
		sensor = call FeedingSpot.sense();
		
		 if (sensor) {
			id_bicho = rand() % 900; 
			id_fspot = rand() % 100;
			dbg("RFID", "The animal %d is near the fspot %d.\n", id_bicho, id_fspot);	
			
			food = call FeedingSpot.getFoodInfo(id_bicho);
			quant = food.quantity_ind;
			
			/*rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
			
			if (rcm == NULL) {
			  return;
			}
			rcm->type = UPDT_SPOT_FOOD;
			rcm->id = rand();
			rcm->src = id_bicho;
			rcm->dest = 0;
			rcm->x = 0;
			rcm->y = 0;
			rcm->spot = id_fspot;
			rcm->quantity = quant;

			call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t));	*/
		}
	}
	
	  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		//do nothing
	  }
	
}
