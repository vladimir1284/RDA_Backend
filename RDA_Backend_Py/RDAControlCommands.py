'''
Created on 09/01/2013

@author: vladimir
'''
import struct

from CODE_messages import RDS_STANDBY, RDS_OFFLINE_OPERATE, RDS_OPERATE,\
                          RDS_RESTART

class RDAControlCommands:
    '''
    classdocs
    '''


    def __init__(self,header_str = None):
        '''
        Constructor
        '''
        self.dRDA_Status = {32769:RDS_STANDBY,
                            32770:RDS_OFFLINE_OPERATE,
                            32772:RDS_OPERATE,
                            32776:RDS_RESTART}
        
        params = struct.unpack('>6HhHI2H4IH5H',header_str)
        self.rda_state_command                           = params[ 0]
        self.base_data_transmission_enable               = params[ 1]
        self.auxiliary_power_generator_control           = params[ 2]
        self.rda_control_commands_and_authorization      = params[ 3]
        self.restart_vcp_or_elevation_cut                = params[ 4]
        self.select_local_vcp_number_for_next_volume_scan= params[ 5]
        self.automatic_calibration_override              = params[ 6]
        self.super_resolution_control                    = params[ 7]
        self.select_operating_mode                       = params[ 9]
        self.channel_control_command                     = params[10]
        self.spot_blanking                               = params[15]
        
        
    def process_Control_Command(self,RDA_Status):
        #TODO this process sends events for each command
        if self.base_data_transmission_enable > 0:
            RDA_Status.data_transmision_enabled = (
                            self.base_data_transmission_enable - 32768)*4
                            
        if self.auxiliary_power_generator_control > 0:
            RDA_Status.auxiliary_power_generator_status = \
                                        self.auxiliary_power_generator_control
                                        
        if self.rda_control_commands_and_authorization > 0:
            RDA_Status.RDA_control_authorization = \
                                   self.rda_control_commands_and_authorization
                                   
        if self.restart_vcp_or_elevation_cut > 0:
            #TODO restart the elevation or volume
            pass
        
        if (self.select_local_vcp_number_for_next_volume_scan >= 1 and
           self.select_local_vcp_number_for_next_volume_scan <= 767):
            RDA_Status.vcp_number = \
                            self.select_local_vcp_number_for_next_volume_scan
        
        if self.automatic_calibration_override != 32767:
            #TODO
            pass
        
        if self.super_resolution_control > 0:
            RDA_Status.super_resolution_status =\
                                             self.automatic_calibration_override
        
        if self.select_operating_mode > 0:
            RDA_Status.operational_mode = self.select_operating_mode
            
        if self.channel_control_command > 0:
            RDA_Status.channel_control_status = self.channel_control_command
            
        if self.spot_blanking > 0:
            RDA_Status.spot_blanking_status = self.spot_blanking
            
        if self.rda_state_command > 0:
            RDA_Status.RDA_status = self.dRDA_Status[self.rda_state_command]
            

        
                            
        
            
    
    
    def print_Control_Command(self):
        print(  'rda_state_command :',self.rda_state_command,'\n'\
                'base_data_transmission_enable :',\
                self.base_data_transmission_enable,'\n'\
                'auxiliary_power_generator_control :',\
                self.auxiliary_power_generator_control,'\n'\
                'rda_control_commands_and_authorization :',\
                self.rda_control_commands_and_authorization,'\n'\
                'restart_vcp_or_elevation_cut :',\
                self.restart_vcp_or_elevation_cut,'\n'\
                'select_local_vcp_number_for_next_volume_scan :',\
                self.select_local_vcp_number_for_next_volume_scan,'\n'\
                'automatic_calibration_override :',\
                self.automatic_calibration_override,'\n'\
                'super_resolution_control :',\
                self.super_resolution_control,'\n'\
                'select_operating_mode :',self.select_operating_mode,'\n'\
                'channel_control_command :',self.channel_control_command,'\n'\
                'spot_blanking :',self.spot_blanking,'\n')
            
            