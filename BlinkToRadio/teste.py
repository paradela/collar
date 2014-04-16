#! /usr/bin/python
import sys
from TOSSIM import *
from BlinkToRadioMessage import *

t = Tossim([])
m = t.mac()
r = t.radio()

#t.addChannel("BlinkToRadioC", sys.stdout)
#t.addChannel("LedsC", sys.stdout)

for i in range(3):
	m = t.getNode(i)
	m.bootAtTime((31 + t.ticksPerSecond() / 10) * i + 1)

f = open("topo.txt", "r")
for line in f:
	s = line.split()
	if s:
		r.add(int(s[0]), int(s[1]), float(s[2]))

noise = open("meyer-heavy.txt", "r")
for line in noise:
	s = line.strip()
	if s:
		val = int(s)
		for i in range(4):
			t.getNode(i).addNoiseTraceReading(val)

for i in range(4):
	t.getNode(i).createNoiseModel()

#for i in range(1000):
	#t.runNextEvent()
  
#print "Creating message now!";

#msg = BlinkToRadioMessage()
#pkt = t.newPacket()
#pkt.setData(msg.data)
#pkt.setType(msg.get_amType())
#pkt.setDestination(0)

#print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3);
#pkt.deliver(0, t.time() + 3)


for i in range(1000):
	t.runNextEvent() 
