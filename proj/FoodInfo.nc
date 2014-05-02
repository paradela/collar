#include "FoodInfo.h"

interface FoodInfo{
  command food_info getFoodInfo(uint16_t id);
  command void warnAboutFS(uint16_t qt);
} 
