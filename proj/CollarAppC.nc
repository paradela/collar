 #include "RadioMsg.h"

configuration CollarAppC {}
implementation {
  components MainC, RadioMsgC as App;
  components new AMSenderC(AM_RADIO_MSG);
  components new AMReceiverC(AM_RADIO_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components gpsC as GPS;
  components rfidC as RFID;
  
  App.Boot -> MainC.Boot;
  GPS.Boot -> MainC.Boot;
  RFID.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.gps -> GPS;
  App.FeedingSpot -> RFID;
}


