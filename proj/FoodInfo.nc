#include "FoodInfo.h"

interface FoodInfo{
  command uint16_t sense();
  command void initFoodInfo(uint16_t val_1, uint16_t val_2);
  command food_info getFoodInfo();
  command void setBichoFood(uint16_t value);
  command void setFSpotFood(uint16_t value);
} 
