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
    call MilliTimer.startPeriodic(10000);
  }


	event void MilliTimer.fired() {

		uint16_t sensor;
		uint16_t id_bicho;
		uint16_t id_fspot;
		uint16_t quant;
		uint16_t last_meal;
		
		message_t packet;
		radio_msg_t* rcm;
		
		
		sensor = call FeedingSpot.sense();
		
		 if (sensor) {
			id_bicho = rand() % 10000; 
			id_fspot = rand() % 100;
			dbg("RFID", "The animal %d is near the fspot %d.\n", id_bicho, id_fspot);	
			
			food = call FeedingSpot.getFoodInfo(id_bicho);
			quant = food.quantity_ind;
			
			if(last_update+10 > food.last_meal){ //simulates that an animal can only eat if it has been more than 24h after his last meal
			
				food.last_meal = last_update;
				
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
				
				dbg("RFID", "Desired amount:%d\n", rcm->quantity);

				call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t));
			}
		}
	}
	
	  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		dbg("RFID", "Msg sent\n");
	  }
	
}
