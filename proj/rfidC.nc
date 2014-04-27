#include "FoodInfo.h"
#include "BichoInfo.h"
#include <stdlib.h>
#include <time.h>

module rfidC {
  uses {
    interface Boot;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface BichoInfo;
    interface FoodInfo;
  }
}

implementation {

  time_t last_update;

  event void Boot.booted() {
    last_update = time(&last_update);
    dbg("RFID", "Booted.");
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(300);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {

  food_i food_control;
  bicho_i bicho_control;
    
  dbg("rfidC", "rfidC: timer fired.\n");
    
  food_control = call FoodInfo.getLeftOvers();
  dbg("rfidC", "There are %d kg left.\n", food_control.quantity);
  
  bicho_control = call BichoInfo.getInfo();
  dbg("rfidC", "This animal can eat %d kg of food.\n", bicho_control.ind_quantity);
  
  }
  
}