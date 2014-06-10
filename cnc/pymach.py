#!/usr/bin/python
import cnccontrol
import threading
import sys, time

cnc = cnccontrol.CNCControl()

stepSize = 500

def gohome():
	global cnc
	cnc.home()

def doreset():
	global cnc
	#cnc.reset()
	pass
	
def xpos():
	global cnc
	cnc.move(stepSize,0,0)

def xneg():
	global cnc
	cnc.move(-stepSize,0,0)

def ypos():
	global cnc
	cnc.move(0,stepSize,0)

def yneg():
	global cnc
	cnc.move(0,-stepSize,0)

def zpos():
	global cnc
	cnc.move(0,0,stepSize)

def zneg():
	global cnc
	cnc.move(0,0,-stepSize)
	
def start():
	global cnc
	cnc.startSpindle()

def stop():
	global cnc
	cnc.stopSpindle()

def drawfile():
	global cnc
	filename = "swirl.cnc"
	f = open( filename )
	d = f.read()
	commands = d.split( '\n' )
	cnc.lift()
	for c in commands:
		es = c.split(' ')
		print 'COMM: '+str(es)
		if es[0] == 'm':
			cnc.lift()
			v = es[1].split(',')
			cnc.go( int(float(v[0])),int(float(v[1])) )
		elif es[0] == 'l':
			cnc.drop()
			v = es[2].split(',')
			cnc.go( int(float(v[0])), int(float(v[1])) )
		elif es[0] == 'c':
			cnc.drop()
			a = S2V(es[1])
			b = S2V(es[2])
			c = S2V(es[3])
			d = S2V(es[4])
			cnc.drawcurvesegment(a,b,c,d)
		else:
			pass
	cnc.lift()

from Tkinter import *
class App:
	def __init__(self, master):
		frame = Frame(master)
		frame.pack()
		title = Frame(frame)
		title.pack(side=TOP)
		self.quit = Button(title, text="QUIT", fg="red", command=frame.quit)
		self.quit.pack(side=LEFT)
		fl = Label(title,text="file:")
		fl.pack(side=LEFT)
		self.filename = StringVar()
		self.filename.set('drawing')
		self.fnfield = Entry(title,textvariable=self.filename )
		self.fnfield.pack(side=LEFT)
		self.dofile = Button(title, text="RENDER", command=drawfile)
		self.dofile.pack(side=LEFT)
		
		mainbuttons = Frame(frame)
		mainbuttons.pack(side=TOP)
		self.home = Button(mainbuttons, text="HOME", command=gohome)
		self.home.pack(side=LEFT)
		self.reset = Button(mainbuttons, text="reset", command=doreset)
		self.reset.pack(side=LEFT)
		self.startSpindle = Button(mainbuttons, text="GO", command=start)
		self.startSpindle.pack(side=LEFT)
		self.stopSpindle = Button(mainbuttons, text="STOP", command=stop)
		self.stopSpindle.pack(side=LEFT)
	
		section = Frame(frame)
		section.pack(side=TOP)
		self.stepVar = StringVar()
		self.stepVar.set('500')
		self.stepsize = Entry(section,textvariable=self.stepVar)
		self.stepsize.pack(side=LEFT)
		self.activity = Canvas(section, width=128, height=24, bg='black' )
		self.activity.pack(side=LEFT)
		self.activity.create_line((0,24,16,22,32,24,48,16,96,24,128,8),fill='green')

		readouts = Frame(frame)
		readouts.pack(side=TOP)
		self.axisLabels = [ 'X', 'Y', 'Z' ]
		self.values = [ StringVar(), StringVar(), StringVar() ]		
		self.values[0].set( 130 )
		self.values[1].set( -300 )
		#self.controls = [ IntVar(), IntVar(), IntVar() ]
		for axis in range(3):
			legend = Label(readouts, text=self.axisLabels[axis] )
			legend.grid(row=axis, column=0)
			value =  Entry(readouts, textvariable=self.values[ axis ] )
			value.grid(row=axis, column=1)
		button = Button(readouts, text="+x", command=xpos)
		button.grid(row=0,column=2)
		button = Button(readouts, text="-x", command=xneg)
		button.grid(row=0,column=3)
		button = Button(readouts, text="+y", command=ypos)
		button.grid(row=1,column=2)
		button = Button(readouts, text="-y", command=yneg)
		button.grid(row=1,column=3)
		button = Button(readouts, text="+z", command=zpos)
		button.grid(row=2,column=2)
		button = Button(readouts, text="-z", command=zneg)
		button.grid(row=2,column=3)
	def setValues(self, x,y,z ):
		print "x,y,z = ",x,',',y,',',z
		self.values[ 0 ].set( x )
		self.values[ 1 ].set( y )
		self.values[ 2 ].set( z )
		
root = Tk()
app = App(root)
def isCNCFile( filenameVar ):
	if filenameVar:
		fn = filenameVar.get()
		if fn:
			try:
				f = open( fn+'.cnc' )
				f.close()
				return True
			except IOError:
				return False
	return False
			
def updateCNC():
	global cnc, app, stepSize
	while cnc and app:
		x,y,z = cnc.gx,cnc.gy,cnc.gz
		app.setValues( x,y,z )
		try:
			stepSize = int(app.stepVar.get())
		except:
			pass
		if isCNCFile( app.filename ):
			app.fnfield.fg='black'
		else:
			app.fnfield.fg='red'
		time.sleep(0.5)
		
t = threading.Thread(target=updateCNC)
t.daemon = True
t.start()
root.mainloop()
app = None

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
	#cncControl.drawfile( "drawing.cnc" )
	pass
except:
	pass
cnc.home()
cnc = None
