COMPONENT=CollarAppC
BUILD_EXTRA_DEPS = RadioMsg.py
CLEAN_EXTRA = RadioMsg.py RadioMsg.pyc

RadioMsg.py: RadioMsg.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioMsg RadioMsg.h radio_msg -o $@

include $(MAKERULES)

