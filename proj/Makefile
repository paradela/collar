COMPONENT=CollarAppC
BUILD_EXTRA_DEPS = LocationMsg.py CheckFoodMsg.py UpdateAnimalFoodMsg.py UpdateFeedingSpotMsg.py
CLEAN_EXTRA = LocationMsg.py CheckFoodMsg.py UpdateAnimalFoodMsg.py UpdateFeedingSpotMsg.py LocationMsg.pyc CheckFoodMsg.pyc UpdateAnimalFoodMsg.pyc UpdateFeedingSpotMsg.pyc

LocationMsg.py: RadioMsg.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=LocationMsg RadioMsg.h location_msg -o $@
	
FoodMsg.py: RadioMsg.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=FoodMsg RadioMsg.h food_msg -o $@
	
include $(MAKERULES)

