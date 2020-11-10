'''
Created on 05/01/2013

@author: vladimir
'''
import struct

class Loopback_Test:
    '''
    classdocs
    '''


    def __init__(self):
        '''
        Constructor
        '''
        self.message_size = 52
        self.bit_pattern = range(self.message_size - 1)
        
    
    def create_LBT_Msg(self):
        result = struct.pack('>%iH' % self.message_size,self.message_size,
                             *self.bit_pattern)
        return result
    
    
    def process_LoopBack_Test(self,stream):
        result = self.create_LBT_Msg() == stream
        if not result:
            print 'LoopBack Test not passed'
        else:
            print 'LoopBack Test passed'
        return result
        