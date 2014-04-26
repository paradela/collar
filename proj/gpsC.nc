#include "gps.h"

module gpsC {
	provides interface gps;
}

implementation {
	
	position_t pos;
	
	command	position_t gps.getPosition() {
		pos.x = 0;
		pos.y = 1;
		
		return pos;
	}
}
