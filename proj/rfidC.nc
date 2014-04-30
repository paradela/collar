#include "FoodInfo.h"
#include <stdlib.h>
#include <time.h>

module rfidC {
  uses {
    interface Boot;
    interface FoodInfo as FeedingSpot;
    interface Timer<TMilli> as MilliTimer;
  }
}

implementation {

	time_t last_update;
	food_info food;	

	event void Boot.booted() {
    last_update = time(&last_update);
    dbg("RFID", "RFID Booted at:%d.\n", (long long)last_update);
    call MilliTimer.startPeriodic(200);
	}

	event void MilliTimer.fired() {

		uint16_t sensor;
		dbg("RFID", "Sensor\n");
		
		sensor = call FeedingSpot.sense();
			
		dbg("RFID", "Sensor: %d \n", sensor);
			
		if (sensor) {
				food = call FeedingSpot.getFoodInfo();
				dbg("RFID", "There are %dkg of food left in the FSpot.\n This animal is allowed to eat %dkg of food.\n", food.quantity_tot, food.quantity_ind);		
		}
	 /*call FeedingSpot.setBichoFood(rcm->id);
      food = call FeedingSpot.getFoodInfo();
      dbg("RadioMsgC", "Teste do update da comida do bicho: %d\n", food.quantity_ind); */
	}
	
}
