#! /usr/bin/python
import sys
import threading
from time import sleep
from random import randint

from TOSSIM import *
from RadioMsg import *

class ThreadEvents (threading.Thread):
    def __init__(self, tossim):
        threading.Thread.__init__(self)
        self.running = True
        self.toss = tossim
        
    def run(self):
		while (self.running):
			for i in range(20):
				self.toss.runNextEvent()
			sleep(0.5)

class Server():
	
	def setUpNodes(self, tossim):
		for i in range(4):
			m = tossim.getNode(i)
			m.bootAtTime((31 + tossim.ticksPerSecond() / 10) * i + 1)

	#receive a file name 
	def loadTopology(self, name, radio):
		self.topo = name
		f = open(name, "r")
		for line in f:
		  s = line.split()
		  if s:
			radio.add(int(s[0]), int(s[1]), float(s[2]))
			
	def removeTopology(self):
		f = open(self.topo, "r")
		for line in f:
		  s = line.split()
		  if s:
			self.r.remove(int(s[0]), int(s[1]))
		
	def loadNoiseModel(self, tossim):
		noise = open("meyer-heavy.txt", "r")
		for line in noise:
		  s = line.strip()
		  if s:
			val = int(s)
			for i in range(4):
			  tossim.getNode(i).addNoiseTraceReading(val)
		
		for i in range(4):
			tossim.getNode(i).createNoiseModel()



	def sendMessage(self, tossim, msg):
		pkt = tossim.newPacket()
		pkt.setData(msg.data)
		pkt.setType(msg.get_amType())
		pkt.setDestination(self.animal)
		print "Delivering " + str(msg) + " to " + str(self.animal) + " at " + str(self.t.time() + 3);
		pkt.deliver(self.animal, self.t.time() + 3)

	def getLocation(self, tossim):
		dest = self.readDest()
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_dest(dest)
		msg.set_type(0) #GET_LOCATION
		self.sendMessage(tossim, msg)

	def getLastKnownLocation(self, tossim):
		dest = self.readDest()
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_dest(dest)
		msg.set_type(1) #GET_LAST_LOCATION
		self.sendMessage(tossim, msg)

	def getAnimalEatenFood(self, tossim):
		dest = self.readDest()
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_dest(dest)
		msg.set_type(2) #GET_EATEN_FOOD
		self.sendMessage(tossim, msg)
		
	def getLeftFoodInSpots(self, tossim):
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_type(3) #GET_LEFT_FOOD
		self.sendMessage(tossim, msg)
		
	def setAnimalFood(self, tossim):
		dest = self.readDest()
		quantity = self.readQuantity()
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_dest(dest)
		msg.set_type(4) #UPDT_ANIMAL_FOOD
		msg.set_quantity(quantity)
		self.sendMessage(tossim, msg)

	def setSpotFood(self, tossim):
		spot = self.readDest()
		quantity = self.readQuantity()
		msg = RadioMsg()
		msg.set_id(randint(1, 65000))
		msg.set_type(5) #UPDT_SPOT_FOOD
		msg.set_spot(spot)
		msg.set_quantity(quantity)
		self.sendMessage(tossim, msg)

	def changeAnimalToConnect(self, notused):
		a = self.readDest()
		self.animal = a
		
	def printOptions(self):
		print "[1]Get animal location"
		print "[2]Get last known animal location"
		print "[3]Get how much an animal has eaten"
		print "[4]Get how much food is left in spots"
		print "[5]Update how much an animal can eat"
		print "[6]Update the food in spot"
		print "[7]Choose animal to connect"
		print "[0]Exit"

	def readDest(self):
		while(1):
			a = raw_input("What is the target? ")
			try:
				i = int(a)
				return i
			except ValueError:
				print "Invalid value"

	def readQuantity(self):
		while(1):
			a = raw_input("What is the quantity? ")
			try:
				i = int(a)
				return i
			except ValueError:
				print "Invalid value"

	def readInput(self, tossim):
		while(1):
			i = raw_input("Choose an option[0-7]: ")
			try:
				a = int(i)
			except ValueError:
				print "Error!!!! invalid input"
				continue
				
			if a == 20:
				self.readTopoName()
				return
		
			if(a < 0  or a > 7):
				print "Error!!!! invalid input"
				continue
			break
			
		if(a == 0):
			self.thread.running = False
			self.thread.join()
			exit()
		
		
		options = {
			1 : self.getLocation,
			2 : self.getLastKnownLocation,
			3 : self.getAnimalEatenFood,
			4 : self.getLeftFoodInSpots,
			5 : self.setAnimalFood,
			6 : self.setSpotFood,
			7 : self.changeAnimalToConnect,
		}
		options[a](tossim)
	
	def readTopoName(self):
		while (1):
			a = raw_input("Type the topology filename: ")
			try:
				self.removeTopology()
				self.loadTopology(a, self.r)
				break
			except IOError:
				print "File not found!"
	
	def runServer(self):
		self.topo = "topo.txt"
		self.animal = 0
		self.t = Tossim([])
		self.m = self.t.mac()
		self.r = self.t.radio()
		self.t.addChannel("RadioMsgC", sys.stdout)
		self.t.addChannel("GPS", sys.stdout)
		self.t.addChannel("RFID", sys.stdout)
		self.setUpNodes(self.t)
		try:
			self.loadTopology("topo.txt", self.r)
		except IOError:
			print "Topology topo.txt not found"
			exit()
		
		self.loadNoiseModel(self.t)
		
		self.thread = ThreadEvents(self.t)
		self.thread.start()
		
		while (1):
			self.printOptions()
			self.readInput(self.t)
		

if __name__ == "__main__":
	server = Server()
	server.runServer()
		
		
