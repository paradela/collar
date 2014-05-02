#include "FoodInfo.h"

interface FoodInfo{
  command uint16_t sense();
  command food_info getFoodInfo(uint16_t id);
  command void warnAboutFS();
} 
