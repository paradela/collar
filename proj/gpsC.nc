#include "gps.h"
#include <stdlib.h>
#include <time.h>

module gpsC {
	uses interface Boot;
	provides interface gps;
}

implementation {
	
	time_t last_update;
	position_t pos;
	
	event void Boot.booted() {
		last_update = time(&last_update);
		pos.x = (rand() % 1000) + 1;
		pos.y = (rand() % 1000) + 1;
    }
	
	command	position_t gps.getPosition() {
		time_t current_time;
		double time_spent;
		uint16_t tmp_x = pos.x;
		uint16_t tmp_y = pos.y;
		int8_t dir_x = 1 - (rand() % 3); //randomly determine the direction the aninal took in x axe
		int8_t dir_y = 1 - (rand() % 3); //randomly determine the direction the aninal took in y axe
		uint16_t step_x;
		uint16_t step_y;
		
		time(&current_time);
		time_spent = difftime(current_time, last_update);
		
		step_x = (dir_x * time_spent * 0.5);
		step_y = (dir_y * time_spent * 0.5);
	
		pos.x = tmp_x + step_x;
		pos.y = tmp_y + step_y;
		
		return pos;
	}
}
