#!/usr/bin/python

comspeed = "19200"

import serial
import sys
from time import sleep
from math import sin
from math import cos
from math import sqrt
from vec import *
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-s", dest="scale",
	help="scale the work",
	default=1.0)
parser.add_option("-D", dest="simOnly",
	help="send to Arduino",
	action="store_false",
	default=True)
parser.add_option("-r", dest="resolution",
	metavar="RES",
	help="maximum length of curve 'line'",
	default=4.0)
(options, args) = parser.parse_args()

sim_only = options.simOnly
maxCurveSegmentLength = float(options.resolution)
workscale = float(options.scale)
truemm2units = 720.0
mm2units = truemm2units * workscale

movespeed = 2000
cutspeed = 1200
maxspeed = 2000
16.8/3.4
4.941176

resourceName = "drawing"
if len(sys.argv) > 1:
	resourceName = sys.argv[-1]

# constants
zlifted = -5 * truemm2units
zdropped = -10 * truemm2units

gx,gy,gz = 0,0,0
dodiag = False
spindleSpeed = 0

import pygame
pygame.init()
width,height = 512,512
size = (width,height)
screen = pygame.display.set_mode(size)
screen.fill((100,100,100))
clock = pygame.time.Clock()

spindle = False
draw = False
oldx,oldy,oldz = 0,0,0

import glob
def scanserial():
# scan for available ports. return a list of tuples (num, name)
	available = []
	for i in range(256):
		try:
			s = serial.Serial(i)
			available.append( s.portstr )
			s.close()
		except serial.SerialException:
			pass
	try:
		for entry in glob.glob('/dev/ttyS*') + glob.glob('/dev/ttyUSB*'):
			available.append( entry )
	except:
		pass
	return available

#port = "/dev/ttyUSB0"

arduinoAvailable = False
if not sim_only:
	available = scanserial()
	while not arduinoAvailable and len( available ) > 0:
		try:
			port = available[0]
			available = available[1:]
			s = serial.Serial( port, comspeed, timeout=0.5 )
			arduinoAvailable = True
			print "using port "+port
		except serial.SerialException:
			pass

if not arduinoAvailable:
	print "No Arduino available."
else:
	print "Arduino is available."
		
def swrite( string ):
	#print ">> ",string
	if arduinoAvailable:
		s.write( string )
def sread():
	if arduinoAvailable:
		string = s.read()
		#print "<< ",string
		return string
	else:
		return ""

def spindleOn():
	global spindleSpeed
	if spindleSpeed == 0:
		spindleSpeed = 1
		swrite('C')
		if not sim_only:
			sleep(1)

def spindleOff():
	global spindleSpeed
	if spindleSpeed == 1:
		spindleSpeed = 0
		swrite('c')

move_col = (0,196,0,127)
cut_cols= ((196,0,0),(196,196,0))
last_cut_col = 0
vertical_col = (0,0,255)
sx,sy = (width/10,height/10)

def waitfor(x,y,z):
	global oldx,oldy,oldz
	global gx,gy,gz
	scale=1
	col = move_col
	thick = 1
	if gz != oldz:
		col = vertical_col
		thick = 1
	if oldz > zdropped-2:
		col = cut_cols[last_cut_col]
		thick = 1
	linestart = (sx+oldx/scale,sy+oldy/scale)
	lineend = (sx+gx/scale,sy+gy/scale)
	pygame.draw.line( screen, col, linestart, lineend, thick )
	oldx = gx
	oldy = gy
	oldz = gz
	clock.tick(60)
	for event in pygame.event.get():
		if event.type == pygame.KEYDOWN:
			if event.key == pygame.K_ESCAPE:
				raise 13
	pygame.display.flip()
	# now, if arduino available, wait for it to get there
	if arduinoAvailable:
		global dodiag
		xready = False#x == 0
		yready = False#y == 0
		zready = False#z == 0
		swrite( 's' )
		while not ( xready and yready and zready ):
			if dodiag:
				if not xready:
					print "waiting for x"
				if not yready:
					print "waiting for y"
				if not zready:
					print "waiting for z"
			r = sread()
			if dodiag:
				print "received: "+str(r)
			if r == 'x':
				xready = True
			elif r == 'y':
				yready = True
			elif r == 'z':
				zready = True
			else:
				print "failed, getting status"
				swrite( 's' )
				dodiag = True
		if dodiag:
			print "finished wait"
			dodiag = False

def waitforz():
	print "Waiting for z"
	waitfor(0,0,1)
	print "Waited for z"

def moveto( x,y,z ):
	global gx,gy,gz
	dx,dy,dz = x-gx,y-gy,z-gz
	mx = abs(dx) != 0
	my = abs(dy) != 0
	mz = abs(dz) != 0
	gx,gy,gz = x,y,z
	speed = ""
	if mz:
		speed = str(maxspeed)+'X'+str(maxspeed)+'Y'+str(maxspeed)+'Z'
	else:
		if mx and my and abs(dx)!=abs(dy):
			if abs(dx) > abs(dy):
				subspeed = int(maxspeed * abs(dy) / abs(dx))
				if subspeed < 1:
					subspeed = 1
				speed = str(maxspeed)+'X'+str(subspeed)+'Y'
			else:
				subspeed = int(maxspeed * abs(dx) / abs(dy))
				if subspeed < 1:
					subspeed = 1
				speed = str(maxspeed)+'Y'+str(subspeed)+'X'
		else:
			speed = str(maxspeed)+'X'+str(maxspeed)+'Y'+str(maxspeed)+'Z'
	command = 'g'
	if not dz == 0:
		command = str(z)+'z'+command
	if not dy == 0:
		command = str(mm2units*y)+'y'+command
	if not dx == 0:
		command = str(mm2units*x)+'x'+command
	if not command == 'g':
		print( "issuing command : "+speed+command )
		swrite( speed+command )
		waitfor(dx,dy,dz)
		
def prepare(x,y):
	moveto(x,y,zlifted)

def go( x, y ):
	global gz
	moveto(x,y,gz)
	
def drop():
	print "in drop"
	global gx,gy
	if gz != zdropped:
		global maxspeed
		maxspeed = cutspeed
		spindleOn()
		moveto(gx,gy,zdropped)
		print "done drop"

def lift():
	global maxspeed
	global gx,gy
	if gz != zlifted:
		maxspeed = movespeed
		moveto(gx,gy,zlifted)
		spindleOff()
		sleep(1)
		print "done lift"
	
def home():
	lift()
	moveto(0,0,0)

def drawcircle( atx, aty, radius ):
	prepare( radius+atx,0+aty )
	drop()

	steps = radius / 10
	for a in range( steps ):
		angle = (a+1)*3.142/(steps/2)
		x = int(cos(angle)*radius)+atx
		y = int(sin(angle)*radius)+aty
		#print( 'going to '+str(x)+','+str(y) )
		go( x, y )

	lift()

def drawlinesegment( atx, aty, btx, bty ):
	dx = btx-atx
	dy = bty-aty
	length = sqrt(dx*dx+dy*dy)
	steps = int(length / 100)
	for a in range( steps ):
		dist = (a+1)*1.0/steps
		x = int(atx+dx*dist)
		y = int(aty+dy*dist)
		#print( 'going to '+str(x)+','+str(y) )
		go( x, y )

def drawlines( points ):
	prepare(int(points[0][0]),int(points[0][1]))
	drop()

	linecount = len( points ) - 1
	for i in range(linecount):
		drawlinesegment( points[i][0], points[i][1], points[i+1][0], points[i+1][1] )

	lift()
	#sleep(1)

def drawcurvesegment( a, b, c, d ):
	dist = ( d-a ).mag()
	if dist > maxCurveSegmentLength:
		ab = 0.5*(a+b)
		bc = 0.5*(b+c)
		cd = 0.5*(c+d)
		abbc = 0.5*(ab+bc)
		bccd = 0.5*(bc+cd)
		abbcbccd = 0.5*(abbc+bccd)
		drawcurvesegment( a,ab,abbc,abbcbccd )
		drawcurvesegment( abbcbccd,bccd,cd,d )
	else:
		#print 'curve reduced to '+str(a)+' '+str(d)
		go( int(d.x), int(d.y) )

def drawcurve( a, b, c, d ):
	prepare(a.x,a.y)
	drop()
	drawcurvesegment(a,b,c,d)
	lift()
	#sleep(1)

def drawheart( x,y, scale ):
	v0 = [x+0,y-1000*scale]
	v1 = [x-1000*scale,y-2000*scale]
	v2 = [x-2000*scale,y-1000*scale]
	v3 = [x-1750*scale,y]
	v4 = [x,y+2000*scale]
	v5 = [x+1750*scale,y]
	v6 = [x+2000*scale,y-1000*scale]
	v7 = [x+1000*scale,y-2000*scale]
	drawlines( [v0,v1,v2,v3,v4,v5,v6,v7,v0] )

def drawfile( filename ):
	global last_cut_col
	print( "Drawing "+filename )
	f = open( filename )
	d = f.read()
	commands = d.split( '\n' )
	print( "lifting..." )
	lift()
	print( "doing commands:" )
	for c in commands:
		es = c.split(' ')
		print( 'COMM: '+str(es) )
		if es[0] == 'm':
			lift()
			v = es[1].split(',')
			go( int(float(v[0])),int(float(v[1])) )
		elif es[0] == 'l':
			last_cut_col = 1 - last_cut_col
			drop()
			v = es[2].split(',')
			go( int(float(v[0])), int(float(v[1])) )
		elif es[0] == 'c':
			last_cut_col = 1 - last_cut_col
			drop()
			a = S2V(es[1])
			b = S2V(es[2])
			c = S2V(es[3])
			d = S2V(es[4])
			drawcurvesegment(a,b,c,d)
		else:
			pass
	print "done: now lifting..."
	lift()			

try:
	#drawheart( 0,0, 1.0 )
	#drawheart( 4000,1000, 0.8 )
	#drawheart( 5000,-2500, 0.7 )
	#drawheart( -3500,2000, 0.6 )
	#drawheart( -4200,-1800, 0.9 )
	
	#drawcircle(0,0, 1000)
	#drawcircle(2000,0, 1000)
	#drawcircle(0,2000, 1000)
	#drawcircle(-2000,0, 1000)
	#drawcircle(0,-2000, 1000)
	
	#drawcircle(0,0, 1000)
	#drawcircle(0,0, 2000)
	#drawcircle(0,0, 3000)
	#drawcircle(0,0, 4000)
	#drawcircle(0,0, 5000)
	
	#def backlashtest( x, y ):
	#	v0 = [x+0,y+0]
	#	v1 = [x+0,y-1000]
	#	v2 = [x+0,y+0]
	#	v3 = [x+0,y+1000]
	#	go( x-1000,y )
	#	drawlines( [v0,v1] )
	#	go( x+1000,y )
	#	drawlines( [v2,v3] )
	#	a0 = [x-500,y+1000]
	#	a1 = [x-500,y-1000]
	#	a2 = [x+500,y-1000]
	#	a3 = [x+500,y+1000]
	#	drawlines( [a0,a1,a2,a3,a0] )
	#	
	#backlashtest(0,0)

	#drawcircle(-1000,-1000)
	#drawcircle(1000,-1000)
	#drawcircle(-1000,1000)
	#drawcircle(1000,1000)
	#drawline( -1000,1000, -500,0 )
	#drawline( -500,0, 0,1000 )
	#drawline( -750,500, -250,500 )
	#drawcurve( Vec(0,0), Vec( 1000,0 ), Vec(1000,1000), Vec(2000,1000) )
	drawfile( resourceName+".cnc" )
	pass

except 13:
	print "Exception, going home"
	home()
	sys.exit()
except:
	pass
print "All done. Going home."
home()

while 1:
	clock.tick(30)
	for event in pygame.event.get():
		if event.type == pygame.KEYDOWN:
			sys.exit()

