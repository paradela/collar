COMPONENT=RadioMessageAppC
BUILD_EXTRA_DEPS = RadioMessage.py
CLEAN_EXTRA = RadioMessage.py RadioMessage.pyc

RadioMessage.py: RadioMessage.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioMessage RadioMessage.h radio_msg -o $@

include $(MAKERULES)

