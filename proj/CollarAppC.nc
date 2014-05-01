 #include "RadioMsg.h"

configuration CollarAppC {}
implementation {
  components MainC, RadioMsgC as App;
  components new AMSenderC(AM_RADIO_MSG) as AMSender1;
  components new AMSenderC(AM_RADIO_MSG) as AMSender2;
  components new AMReceiverC(AM_RADIO_MSG);
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components ActiveMessageC;
  components gpsC as GPS;
  components rfidC as RFID;
  
  App.Boot -> MainC.Boot;
  GPS.Boot -> MainC.Boot;
  RFID.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSender1;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> Timer1;
  App.Packet -> AMSender1;
  App.gps -> GPS;
  
  
  RFID.MilliTimer-> Timer2;
  RFID.FeedingSpot -> App;
  RFID.AMSend -> AMSender2;
  RFID.Packet -> AMSender2;
}


