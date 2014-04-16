COMPONENT=BlinkToRadioAppC

BUILD_EXTRA_DEPS = BlinkToRadioMessage.py BlinkToRadioMessage.class
CLEAN_EXTRA = BlinkToRadioMessage.py BlinkToRadioMessage.class BlinkToRadioMessage.java

BlinkToRadioMessage.py: BlinkToRadio.h 
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=BlinkToRadioMessage BlinkToRadio.h BlinkToRadioMsg -o $@

BlinkToRadioMessage.class: BlinkToRadioMessage.java
	javac BlinkToRadioMessage.java

BlinkToRadioMessage.java: BlinkToRadio.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=BlinkToRadioMessage BlinkToRadio.h BlinkToRadioMsg -o $@


include $(MAKERULES)