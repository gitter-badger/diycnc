import serial
import sys
from time import sleep
from math import sin
from math import cos
from math import sqrt
from vec import *

class CNCControl:
	# constants
	zlifted = 1200
	zdropped = 1800
	def __init__( self ):
		self.movespeed = 500
		self.cutspeed = 200
		self.maxspeed = 500
		self.gx,self.gy,self.gz = 0,0,0
		self.dodiag = False
		self.arduinoAvailable = False
		try:
			self.s = serial.Serial( "/dev/ttyUSB0", "9600", timeout=2.5 )
			self.arduinoAvailable = True
		except serial.SerialException:
			try:
				self.s = serial.Serial( "/dev/ttyUSB1", "19200", timeout=2.5 )
				self.arduinoAvailable = True
			except:
				pass

	def swrite( self, string ):
		if self.arduinoAvailable:
			self.s.write( string )

	def waitfor(self,x,y,z):
		if not self.arduinoAvailable:
			return
		xready = False#x == 0
		yready = False#y == 0
		zready = False#z == 0
		self.s.write( 's' )
		while not ( xready and yready and zready ):
			if self.dodiag:
				if not xready:
					print "waiting for x"
				if not yready:
					print "waiting for y"
				if not zready:
					print "waiting for z"
			r = self.s.read()
			if self.dodiag:
				print "received: "+str(r)
			if r == 'x':
				xready = True
			elif r == 'y':
				yready = True
			elif r == 'z':
				zready = True
			else:
				print "failed, getting status"
				self.s.write( 's' )
				self.dodiag = True
		if self.dodiag:
			print "finished wait"
			self.dodiag = False

	def move( self, x,y,z ):
		self.moveto( self.gx+x, self.gy+y, self.gz+z )

	def moveto( self, x,y,z ):
		dx,dy,dz = x-self.gx,y-self.gy,z-self.gz
		mx = abs(dx) != 0
		my = abs(dy) != 0
		mz = abs(dz) != 0
		self.gx,self.gy,self.gz = x,y,z
		speed = ""
		if mz:
			speed = str(self.maxspeed)+'X'+str(self.maxspeed)+'Y'+str(self.maxspeed)+'Z'
		else:
			if mx and my and abs(dx)!=abs(dy):
				if abs(dx) > abs(dy):
					subspeed = int(self.maxspeed * abs(dy) / abs(dx))
					if subspeed < 1:
						subspeed = 1
					speed = str(self.maxspeed)+'X'+str(subspeed)+'Y'
				else:
					subspeed = int(self.maxspeed * abs(dx) / abs(dy))
					if subspeed < 1:
						subspeed = 1
					speed = str(self.maxspeed)+'Y'+str(subspeed)+'X'
			else:
				speed = str(self.maxspeed)+'X'+str(self.maxspeed)+'Y'+str(self.maxspeed)+'Z'
		

		command = 'g'
		if not dz == 0:
			command = str(z)+'z'+command
		if not dy == 0:
			command = str(y)+'y'+command
		if not dx == 0:
			command = str(x)+'x'+command
		if not command == 'g':
			print "issuing command : "+speed+command
			self.swrite( speed+command )
			self.waitfor(dx,dy,dz)
			
	def startSpindle(self):
		self.swrite('C')
	
	def stopSpindle(self):
		self.swrite('c')
		
	def waitforz(self):
		self.waitfor(0,0,1)

	def prepare(self,x,y):
		self.moveto(x,y,self.zlifted)

	def go( self, x, y ):
		self.moveto(x,y,self.gz)
	
	def drop(self):
		self.moveto(self.gx,self.gy,self.zdropped)
		self.maxspeed = self.cutspeed

	def lift(self):
		self.maxspeed = self.movespeed
		self.moveto(self.gx,self.gy,self.zlifted)
	
	def home(self):
		if self.gz > self.zlifted:
			self.lift()
		self.moveto(0,0,0)

	def reset(self):
		self.gx,self.gy,self.gz = 0,0,0
		self.swrite( 'r' )

	def drawcircle( self,atx, aty, radius ):
		self.prepare( radius+atx,0+aty )
		self.drop()
		steps = radius / 10
		for a in range( steps ):
			angle = (a+1)*3.142/(steps/2)
			x = int(cos(angle)*radius)+atx
			y = int(sin(angle)*radius)+aty
			#print( 'going to '+str(x)+','+str(y) )
			self.go( x, y )
		self.lift()

	def drawlinesegment( self, atx, aty, btx, bty ):
		dx = btx-atx
		dy = bty-aty
		length = sqrt(dx*dx+dy*dy)
		steps = int(length / 100)
		for a in range( steps ):
			dist = (a+1)*1.0/steps
			x = int(atx+dx*dist)
			y = int(aty+dy*dist)
			#print( 'going to '+str(x)+','+str(y) )
			self.go( x, y )

	def drawlines(self, points ):
		self.prepare(int(points[0][0]),int(points[0][1]))
		self.drop()
		linecount = len( points ) - 1
		for i in range(linecount):
			self.drawlinesegment( points[i][0], points[i][1], points[i+1][0], points[i+1][1] )
		self.lift()
		sleep(1)

	def drawcurvesegment( self, a, b, c, d ):
		dist = ( d-a ).mag()
		if dist > 100:
			ab = 0.5*(a+b)
			bc = 0.5*(b+c)
			cd = 0.5*(c+d)
			abbc = 0.5*(ab+bc)
			bccd = 0.5*(bc+cd)
			abbcbccd = 0.5*(abbc+bccd)
			self.drawcurvesegment( a,ab,abbc,abbcbccd )
			self.drawcurvesegment( abbcbccd,bccd,cd,d )
		else:
			#print 'curve reduced to '+str(a)+' '+str(d)
			self.go( int(d.x), int(d.y) )

	def drawcurve( self, a, b, c, d ):
		self.prepare(a.x,a.y)
		self.drop()
		self.drawcurvesegment(a,b,c,d)
		self.lift()
		self.sleep(1)

	def drawheart( self, x,y, scale ):
		v0 = [x+0,y-1000*scale]
		v1 = [x-1000*scale,y-2000*scale]
		v2 = [x-2000*scale,y-1000*scale]
		v3 = [x-1750*scale,y]
		v4 = [x,y+2000*scale]
		v5 = [x+1750*scale,y]
		v6 = [x+2000*scale,y-1000*scale]
		v7 = [x+1000*scale,y-2000*scale]
		self.drawlines( [v0,v1,v2,v3,v4,v5,v6,v7,v0] )

	def drawfile( self, filename ):
		f = open( filename )
		d = f.read()
		commands = d.split( '\n' )
		self.lift()
		for c in commands:
			es = c.split(' ')
			print 'COMM: '+str(es)
			if es[0] == 'm':
				self.lift()
				v = es[1].split(',')
				self.go( int(float(v[0])),int(float(v[1])) )
			elif es[0] == 'l':
				self.drop()
				v = es[2].split(',')
				self.go( int(float(v[0])), int(float(v[1])) )
			elif es[0] == 'c':
				self.drop()
				a = S2V(es[1])
				b = S2V(es[2])
				c = S2V(es[3])
				d = S2V(es[4])
				self.drawcurvesegment(a,b,c,d)
			else:
				pass
		self.lift()			

