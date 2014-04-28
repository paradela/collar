#! /usr/bin/python
import sys
import threading
from time import sleep
from random import randint

from TOSSIM import *
from RadioMsg import *

class ThreadEvents (threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.running = True
        
    def run(self):
		while (self.running):
			for i in range(20):
				t.runNextEvent()
			sleep(0.5)
	
def setUpNodes(tossim):
	for i in range(4):
		m = tossim.getNode(i)
		m.bootAtTime((31 + tossim.ticksPerSecond() / 10) * i + 1)

#receive a file name 
def loadTopology(name, radio):
	f = open(name, "r")
	for line in f:
	  s = line.split()
	  if s:
		radio.add(int(s[0]), int(s[1]), float(s[2]))
	
def loadNoiseModel(tossim):
	noise = open("meyer-heavy.txt", "r")
	for line in noise:
	  s = line.strip()
	  if s:
		val = int(s)
		for i in range(4):
		  tossim.getNode(i).addNoiseTraceReading(val)
	
	for i in range(4):
		tossim.getNode(i).createNoiseModel()



def sendMessage(tossim, msg):
	pkt = tossim.newPacket()
	pkt.setData(msg.data)
	pkt.setType(msg.get_amType())
	pkt.setDestination(0)
	print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3);
	pkt.deliver(0, t.time() + 3)

def getLocation(tossim):
	dest = readDest()
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_dest(dest)
	msg.set_type(0) #GET_LOCATION
	sendMessage(tossim, msg)

def getLastKnownLocation(tossim):
	dest = readDest()
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_dest(dest)
	msg.set_type(1) #GET_LAST_LOCATION
	sendMessage(tossim, msg)

def getAnimalEatenFood(tossim):
	dest = readDest()
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_dest(dest)
	msg.set_type(2) #GET_EATEN_FOOD
	sendMessage(tossim, msg)
	
def getLeftFoodInSpots(tossim):
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_type(3) #GET_LEFT_FOOD
	sendMessage(tossim, msg)
	
def setAnimalFood(tossim):
	dest = readDest()
	quantity = readQuantity()
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_dest(dest)
	msg.set_type(4) #UPDT_ANIMAL_FOOD
	msg.set_quantity(quantity)
	sendMessage(tossim, msg)

def setSpotFood(tossim):
	spot = readDest()
	quantity = readQuantity()
	msg = RadioMsg()
	msg.set_id(randint(1, 65000))
	msg.set_type(5) #UPDT_SPOT_FOOD
	msg.set_spot(spot)
	msg.set_quantity(quantity)
	sendMessage(tossim, msg)
	
def printOptions():
	print "[1]Get animal location"
	print "[2]Get last known animal location"
	print "[3]Get how much an animal has eaten"
	print "[4]Get how much food is left in spots"
	print "[5]Update how much an animal can eat"
	print "[6]Update the food in spot"
	print "[7]Choose animal to connect"
	print "[0]Exit"

def readDest():
	a = raw_input("What is the target? ")
	return int(a)

def readQuantity():
	a = raw_input("What is the quantity? ")
	return int(a)

def readInput(tossim):
	while(1):
		i = raw_input("Chose an option[0-7]: ")
		a = int(i)
	
		if(a < 0  and a > 6):
			print "Error!!!! invalid input"
			continue
		break
		
	if(a == 0):
		thread.running = False
		thread.join()
		exit()
	options = {
		1 : getLocation,
		2 : getLastKnownLocation,
		3 : getAnimalEatenFood,
		4 : getLeftFoodInSpots,
		5 : setAnimalFood,
		6 : setSpotFood,
	}
	options[a](tossim)

if __name__ == "__main__":
	t = Tossim([])
	m = t.mac()
	r = t.radio()
	t.addChannel("RadioMsgC", sys.stdout)
	t.addChannel("GPS", sys.stdout)
	t.addChannel("RFID", sys.stdout)
	setUpNodes(t)
	loadTopology("topo.txt", r)
	loadNoiseModel(t)
	
	thread = ThreadEvents()
	thread.start()
	
	while (1):
		printOptions()
		readInput(t)
		
		
