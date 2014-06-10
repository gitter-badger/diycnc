#!/usr/bin/python
import xml.parsers.expat
import sys
from vec import *

resourceName = "drawing"
if len(sys.argv) > 1:
	resourceName = sys.argv[-1]
	splitname = resourceName.split(".")
	if len( splitname ) > 1 and splitname[-1] == "svg":
		resourceName = ".".join(splitname[:-1])

root = Vec(0,0)
totalContent = ""
# 3 handler functions
def addToLists( content ):
	global totalContent
	totalContent = totalContent + content
	
def start_element(name, attrs):
	global root
	print 'Start element:', name
	if name == 'g':
		if 'transform' in attrs:
			transform = attrs['transform'].split( '(' )
			if transform[0] == 'translate':
				root = S2V(transform[1][:-1])
				addToLists( 'R '+str(root)+' ' )
	if name == 'path':
		addToLists( 'M '+str(Vec(0,0))+' ' )
		addToLists( attrs['d']+' ' )
def end_element(name):
	print 'End element:', name
def char_data(data):
	#print 'Character data:', repr(data)
	pass

p = xml.parsers.expat.ParserCreate()

p.StartElementHandler = start_element
p.EndElementHandler = end_element
p.CharacterDataHandler = char_data

file = open( resourceName+".svg", "rt" )
data = file.read()
file.close()

p.Parse(data)

elements = totalContent.split( ' ' )

lines = []

vc = Vec(0,0)

scale = 1.0

while len( elements ) > 0:
	e = elements[0]
	if e == 'R':
		elements = elements[1:]
		root = S2V( elements[0] )
		elements = elements[1:]
	elif e == 'M':
		elements = elements[1:]
		v1 = S2V( elements[0] ) + root
		lines.append( 'm '+str(v1*scale) )
		elements = elements[1:]
		vc = v1
		while len( elements ) >= 1 and isVector( elements[0] ):
			v1 = S2V( elements[0] )
			lines.append( 'l '+str(vc*scale)+' '+str(v1*scale) )
			vc = v1
			elements = elements[1:]
	elif e == 'm':
		elements = elements[1:]
		v1 = vc + S2V( elements[0] )
		lines.append( 'm '+str(v1*scale) )
		elements = elements[1:]
		vc = v1
		while len( elements ) >= 1 and isVector( elements[0] ):
			v1 = vc + S2V( elements[0] )
			lines.append( 'l '+str(vc*scale)+' '+str(v1*scale) )
			vc = v1
			elements = elements[1:]
	elif e == 'L':
		elements = elements[1:]
		while len( elements ) >= 1 and isVector( elements[0] ):
			v1 = S2V( elements[0] ) + root
			lines.append( 'l '+str(vc*scale)+' '+str(v1*scale) )
			vc = v1
			elements = elements[1:]
	elif e == 'l':
		elements = elements[1:]
		while len( elements ) >= 1 and isVector( elements[0] ):
			v1 = vc + S2V( elements[0] )
			lines.append( 'l '+str(vc*scale)+' '+str(v1*scale) )
			vc = v1
			elements = elements[1:]
	elif e == 'C':
		elements = elements[1:]
		while len( elements ) >= 3 and isVector( elements[0] ):
			v1 = S2V( elements[0] ) + root
			v2 = S2V( elements[1] ) + root
			v3 = S2V( elements[2] ) + root
			lines.append( 'c '+ str(vc*scale)+' '+str(v1*scale)+' '+str(v2*scale)+' '+str(v3*scale) )
			vc = v3
			elements = elements[3:]
	elif e == 'c':
		elements = elements[1:]
		while len( elements ) >= 3 and isVector( elements[0] ):
			v1 = vc+S2V( elements[0] )
			v2 = vc+S2V( elements[1] )
			v3 = vc+S2V( elements[2] )
			lines.append( 'c '+ str(vc*scale)+' '+str(v1*scale)+' '+str(v2*scale)+' '+str(v3*scale) )
			vc = v3
			elements = elements[3:]
	else:
		elements = elements[1:]

newlines = []
for line in lines:
	if line[0] == 'm':
		if len(newlines) > 0 and newlines[-1][0] == 'm':
			newlines = newlines[:-1]
	newlines.append(line)
lines = newlines

print "after cleanup"
print '\n'.join(lines)

file = open( resourceName+".cnc", "w" )
file.write( '\n'.join(lines) )
file.close()

