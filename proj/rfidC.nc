#include "FoodInfo.h"
#include <stdlib.h>
#include <time.h>

module rfidC {
  uses {
    interface Boot;
  }
  provides interface FoodInfo as FeedingSpot;
}

implementation {

  time_t last_update;
  food_info food;	

  event void Boot.booted() {
    last_update = time(&last_update);

    dbg("RFID", "RFID Booted at:%d.", (long long)last_update);
  }

 
 command uint16_t FeedingSpot.sense() {
	uint16_t bicho_near;
	
	bicho_near = (rand() % 2); //random to determine if there's an animal nearby or not
	
	return bicho_near;
 }
 
  command void FeedingSpot.initFoodInfo() {
	uint16_t bicho_food = (rand() % 5);
	uint16_t fspot_food = (rand() % 15);
	
	food.quantity_tot = fspot_food + 1;
	food.quantity_ind = bicho_food + 1;
  }
  
  command food_info FeedingSpot.getFoodInfo(){
    return food;
  }
  
  command void FeedingSpot.setBichoFood(uint16_t value) {
	if(value < 0)
		return;
	else 	
		food.quantity_ind = value;
  }
  
  command void FeedingSpot.setFSpotFood(uint16_t value) {
	if(value < 0)
		return;
	else 	
		food.quantity_tot = value;
  }
  
}
