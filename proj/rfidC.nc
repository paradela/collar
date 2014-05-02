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
		uint16_t quant;
		last_update = time(&last_update);

		sensor = (rand() % 2); //random to determine if there's an animal nearby or not
		food = call FeedingSpot.getFoodInfo(TOS_NODE_ID);
		quant = food.quantity_ind;

		if (sensor) {
			food = call FeedingSpot.getFoodInfo(TOS_NODE_ID);
			quant = food.quantity_ind;
			
			if(last_update+500000 > food.last_meal){ //simulates that an animal can only eat if it has been more than 24h after his last meal
				call FeedingSpot.warnAboutFS(quant);
				food.last_meal = last_update;	
			}
			else 
				dbg("RFID", "This animal already ate what he needs for the day!\n");
		}
	}
	
}
