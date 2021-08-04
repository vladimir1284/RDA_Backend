'''
Created on 08/01/2013

@author: vladimir
'''
import struct
from CODE_messages import CONVERSIONS

class MSG_Header:
    '''
    classdocs
    '''


    def __init__(self,header_str = None):
        '''
        Constructor
        receive a 16 Bytes string as arg
        '''
        if header_str == None:
            self.message_size               = None
            self.RDA_Redundant_Channel      = None
            self.message_Type               = None
            self.id_sequence_number         = None
            self.julian_date                = None
            self.milliseconds_of_day        = None
            self.number_of_message_segments = None
            self.message_segment_number     = None
        else:
            params = struct.unpack('>H2B2HI2H',header_str)
            self.message_size               = params[0]
            self.RDA_Redundant_Channel      = params[1]
            self.message_Type               = params[2]
            self.id_sequence_number         = params[3]
            self.julian_date                = params[4]
            self.milliseconds_of_day        = params[5]
            self.number_of_message_segments = params[6]
            self.message_segment_number     = params[7]
            
    
    def get_Stream(self):
        result = struct.pack('>H2B2HI2H',self.message_size,
                             self.RDA_Redundant_Channel,self.message_Type,
                             self.id_sequence_number,self.julian_date,
                             self.milliseconds_of_day,
                             self.number_of_message_segments,
                             self.message_segment_number)
        return result 
    
    
    def print_Header(self):
        print( 'message_size: ',self.message_size,'\n',\
               'RDA_Redundant_Channel: ',self.RDA_Redundant_Channel,'\n',\
               'message_Type: ',self.message_Type,'\n',\
               'id_sequence_number: ',self.id_sequence_number,'\n',\
               'julian_date: ',self.julian_date,'\n',\
               'milliseconds_of_day: ',self.milliseconds_of_day,'\n',\
               'number_of_message_segments: ',\
                                    self.number_of_message_segments,'\n',\
               'message_segment_number: ',self.message_segment_number)
        
        
    def construc_Msg_Header(self,size,m_type,n_segments,segment_n,
                            fsequence_number,RDA_Redundant_Channel):
        
        jd, mo = CONVERSIONS.JulianDate_msec()
        
        self.message_size               = int(size) # halfwords
        self.RDA_Redundant_Channel      = RDA_Redundant_Channel
        self.message_Type               = m_type
        self.id_sequence_number         = fsequence_number
        self.julian_date                = jd
        self.milliseconds_of_day        = mo
        self.number_of_message_segments = n_segments
        self.message_segment_number     = segment_n
        
        return self.get_Stream()