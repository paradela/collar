#include <Timer.h>
#include "BlinkToRadio.h"
 
configuration BlinkToRadioAppC {
}
implementation {
  components MainC;
  components BlinkToRadioC as App;
  components new TimerMilliC() as Timer0;
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
 
  App.Boot -> MainC.Boot;
  App.Timer0 -> Timer0;
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;
}
