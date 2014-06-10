import math

class Vec:
	def __init__( self, x, y ):
		self.x,self.y = float(x),float(y)
	def __add__(self, other ):
		return Vec( self.x+other.x, self.y+other.y )
	def __sub__(self, other ):
		return Vec( self.x-other.x, self.y-other.y )
	def __mul__(self, other ):
		return Vec( self.x*other, self.y*other )
	def __rmul__(self, other ):
		return Vec( self.x*other, self.y*other )
	def __str__(self):
		return str(self.x)+','+str(self.y)
	def dot(self, other):
		return self.x * other.x + self.y * other.y
	def mag(self):
		return math.sqrt( self.dot(self) )

def S2V( s ):
	v = s.split(',')
	return Vec(v[0],v[1])

def isVector( element ):
	try:
		nums = element.split(',')
		x,y = float(nums[0]),float(nums[1])
		return True
	except:
		pass
	return False

