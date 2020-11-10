'''
Created on 06/01/2013

@author: vladimir
'''
import struct

CTM_HEADER_SIZE = 6 # HalfWords

class CTM_Header:
    '''
    classdocs
    '''


    def __init__(self,header_str = None):
        '''
        Constructor
        receive a 12 Bytes string as arg
        '''
        if header_str == None:
            # overloaded for dummy CTM object
            self.Typ = 0
            self.par = 0
            self.Len = 0
        else:
            params = struct.unpack('>3I',header_str)
            self.Typ = params[0]
            self.par = params[1]
            self.Len = params[2]
    
    def get_Stream(self):
        result = struct.pack('>3I',self.Typ,self.par,self.Len)
        return result 
    
        
        