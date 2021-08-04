'''
Created on 10/01/2013

@author: vladimir
'''
from pylab import ones, ushort
import struct

from CODE_messages import CONVERSIONS

class Clutter_Filter_Bypass_Map:
    '''
    classdocs
    '''


    def __init__(self):
        '''
        Constructor
        '''
        jd, mo = CONVERSIONS.JulianDate_msec()
        self.generation_date = jd
        self.generation_time = int(mo/60000) # from msec to min 
        self.number_of_segments = 1
        
    
    def get_dummy_Map(self):
        self.__init__()
        segment_number = 1
        segment = 0xFFFF*ones(11520, dtype = ushort)
        return struct.pack('>11524H',self.generation_date, self.generation_time,
                           self.number_of_segments, segment_number, *segment)
        