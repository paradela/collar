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
    call MilliTimer.startPeriodic(120000);
  }


	event void MilliTimer.fired() {

		uint16_t sensor;
		last_update = time(&last_update);

		sensor = call FeedingSpot.sense();
				
		if (sensor) {
			food = call FeedingSpot.getFoodInfo(TOS_NODE_ID);
			
			if(last_update+500000 > food.last_meal){ //simulates that an animal can only eat if it has been more than 24h after his last meal
				call FeedingSpot.warnAboutFS();
				food.last_meal = last_update;	
			}
			else 
				dbg("RFID", "This animal already ate what he needs for the day!\n");
		}
	}
	
}
