'''
Created on 10/01/2013

@author: vladimir
'''
from pylab import ones
import struct

from CODE_messages import CONVERSIONS

class Clutter_Filter_Map:
    '''
    classdocs
    '''


    def __init__(self):
        '''
        Constructor
        '''
        jd, mo = CONVERSIONS.JulianDate_msec()
        self.generation_date = jd
        self.generation_time = mo/60000 # from msec to min 
        self.number_of_segments = 1
        
    
    def get_dummy_Map(self):
        self.__init__()
        number_of_range_zones = 1
        op_Code = 0 # Bypass Map
        end_Range = 10 # Km
        
        header = struct.pack('>3H',self.generation_date,self.generation_time,
                             self.number_of_segments)
        azimuth_segment = struct.pack('>3H',number_of_range_zones,op_Code,
                                      end_Range)
        return header + 360*azimuth_segment # There are 360 azimuth segments

        