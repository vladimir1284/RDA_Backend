'''
Created on 05/01/2013

@author: vladimir
'''
from CODE_messages import *

import struct

# Some Sizes
TM_VCP_HEADER_SIZE = 11 # HalfWords
TM_VCP_ELEVATION_SIZE = 23 # HalfWords

class VCP_Data:
    '''
    Volume Coverage Pattern Data (Message Types 5 & 7)
    RDA-RPG-ICD-2620002G page 52 Table XI
    '''
    def __init__(self,pattern_number,VCP_Table):
        '''
        Constructor
        '''
        self.pattern_number = pattern_number
        self.fVCP_Table = VCP_Table
        
    #def create_VCP_Msg(self):
        VCP_Node = self.get_VCP_Node()
        
        self.number_of_elevation_cuts = \
                    int(VCP_Node.attributes['number_of_elevation_cuts'].value)
        self.message_size = TM_VCP_HEADER_SIZE + \
                        self.number_of_elevation_cuts*TM_VCP_ELEVATION_SIZE
        self.pattern_type = int(VCP_Node.attributes['pattern_type'].value)
        self.pattern_number = int(VCP_Node.attributes['pattern_number'].value)
        self.clutter_map_group_number = \
                    int(VCP_Node.attributes['clutter_map_group_number'].value)
        self.doppler_velocity_resolution = \
                    int(VCP_Node.attributes['doppler_velocity_resolution'].value)
        self.pulse_width = int(VCP_Node.attributes['pulse_width'].value)
        
        self.TM_VCP_Header = struct.pack('>5H2B',self.message_size,self.pattern_type,self.pattern_number,
                                   self.number_of_elevation_cuts, self.clutter_map_group_number,
                                   self.doppler_velocity_resolution,self.pulse_width)
        
        self.TM_VCP_Elevations = ''
        Elevations = VCP_Node.getElementsByTagName('elevation')
        self.elevations = []
        for elevation_Node in Elevations:
            elev = VCP_Elevation(elevation_Node)
            self.elevations.append(elev)            
            self.TM_VCP_Elevations += elev.get_Stream()
            

    def get_Stream(self):
        return self.TM_VCP_Header + self.TM_VCP_Elevations
    
    
    def get_VCP_Node(self):
        result = None
        Nodes = self.fVCP_Table.getElementsByTagName('vcp')
        for node in Nodes:
            if int(node.attributes['pattern_number'].value) == self.pattern_number:
                result = node
        if result == None:
            class NoVCP_Exception(BaseException):
                pass
            raise NoVCP_Exception('No vcp %i definition on XML file.' % self.pattern_number)
        return result


class  VCP_Elevation:
    def __init__(self,elevation_Node):
        self.elevation_angle = CONVERSIONS.Convert_data_out(
                                float(elevation_Node.attributes['angle'].value), 
                                ANGULAR_ELEV_DATA)
        
        self.channel_configuration = \
                int(elevation_Node.attributes['channel_configuration'].value)
                
        self.waveform_type = int(elevation_Node.attributes['waveform_type'].value)
        
        self.super_resolution_control = \
            int(elevation_Node.attributes['super_resolution_control'].value)
            
        self.surveillance_prf_number = \
             int(elevation_Node.attributes['surveillance_prf_number'].value)
             
        self.surveillance_prf_pulse_count_by_radial= \
             int(elevation_Node.attributes\
                 ['surveillance_prf_pulse_count_by_radial'].value)
             
        self.azimuth_rate = CONVERSIONS.Convert_data_out(
                        float(elevation_Node.attributes['azimuth_rate'].value),
                        VELOCITY_DATA)
        
        self.reflectivity_threshold = CONVERSIONS.Convert_data_out(
             int(elevation_Node.attributes['reflectivity_threshold'].value),
             SCALED_SINT_2)
        
        self.velocity_threshold = CONVERSIONS.Convert_data_out(
                    int(elevation_Node.attributes['velocity_threshold'].value),
                    SCALED_SINT_2)
        
        self.spectrum_width_threshold = CONVERSIONS.Convert_data_out(
            int(elevation_Node.attributes['spectrum_width_threshold'].value),
            SCALED_SINT_2)
            
                    
        self.sector1_edge_angle = CONVERSIONS.Convert_data_out(
                            float(elevation_Node.attributes['sector1_edge_angle'].value), 
                            ANGULAR_AZM_DATA)
        
        self.sector1_doppler_prf_number = \
            int(elevation_Node.attributes['sector1_doppler_prf_number'].value)
            
        self.sector1_doppler_prf_count_by_radial= \
                                    int(elevation_Node.attributes\
                                        ['sector1_doppler_prf_count_by_radial'].value)
                                    
        self.sector2_edge_angle = CONVERSIONS.Convert_data_out(
                            float(elevation_Node.attributes['sector2_edge_angle'].value), 
                            ANGULAR_AZM_DATA)
        
        self.sector2_doppler_prf_number = \
            int(elevation_Node.attributes['sector2_doppler_prf_number'].value)
            
        self.sector2_doppler_prf_count_by_radial= \
                                    int(elevation_Node.attributes\
                                        ['sector2_doppler_prf_count_by_radial'].value)
                                    
        self.sector3_edge_angle = CONVERSIONS.Convert_data_out(
                            float(elevation_Node.attributes['sector3_edge_angle'].value), 
                            ANGULAR_AZM_DATA)
        
        self.sector3_doppler_prf_number = \
            int(elevation_Node.attributes['sector3_doppler_prf_number'].value)
            
        self.sector3_doppler_prf_count_by_radial= \
                                    int(elevation_Node.attributes\
                                        ['sector3_doppler_prf_count_by_radial'].value)
                                    
                                    
    def get_Cut_Sector_Number(self,angle):
        '''
        Retunrs the sector number for a radial with a given angle
        '''
        code = CONVERSIONS.Convert_data_out(angle, ANGULAR_AZM_DATA)
                
        if code < self.sector1_edge_angle:
            result  = 1
        elif(code < self.sector2_edge_angle):
            result  = 2
        else:
            result  = 3
            
        return result


    def get_Stream(self):      
        stream = struct.pack('>H4B2H3h3H',self.elevation_angle,self.channel_configuration,\
                             self.waveform_type,self.super_resolution_control,
                             self.surveillance_prf_number,
                             self.surveillance_prf_pulse_count_by_radial,
                             self.azimuth_rate,self.reflectivity_threshold,
                             self.velocity_threshold,self.spectrum_width_threshold,0,0,0)      
        stream += struct.pack('>12H',self.sector1_edge_angle,self.sector1_doppler_prf_number,
                              self.sector1_doppler_prf_count_by_radial,0,
                              self.sector2_edge_angle,self.sector2_doppler_prf_number,
                              self.sector2_doppler_prf_count_by_radial,0,
                              self.sector3_edge_angle,self.sector3_doppler_prf_number,
                              self.sector3_doppler_prf_count_by_radial,0)
        return stream