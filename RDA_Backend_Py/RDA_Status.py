'''
Created on 05/01/2013

@author vladimir
'''
import struct
from CODE_messages import * 

class RDA_Status:
    '''
    Table IV RDA Status Data (Message Type 2)
    '''
    def __init__(self):
        '''
        Constructor
        '''
        self.RDA_status                          = RDS_STANDBY
        self.operability_status                  = ROS_RDA_ONLINE
        self.control_status                      = RCS_RDA_EITHER
        self.auxiliary_power_generator_status    = APGS_UTILITY_PWR_AVAILABLE
        self.average_transmiter_power            = 0x0582
        self.reflectivity_calibration_correction = 0 
        self.data_transmision_enabled            = DTE_NONE_ENABLED
        self.vcp_number                          = 111
        self.RDA_control_authorization           = RCA_NO_ACTION
        self.RDA_build_number                    = 112 # 11.2
        self.operational_mode                    = ROM_OPERATIONAL
        self.super_resolution_status             = 0
        self.spare_1                             = (0,1) # legacy
        self.RDA_alarm_summary                   = 0
        self.command_acknowledgment              = CA_NO_ACKNOWLEDGEMENT
        self.channel_control_status              = 0
        self.spot_blanking_status                = SBS_NOT_INSTALLED        
        self.rms_control_status                  = 0
        self.alarm_codes                         = [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    
    def create_RDA_Status_Msg(self):
        result = struct.pack('>5HhHh32H',self.RDA_status,self.operability_status,
                             self.control_status,self.auxiliary_power_generator_status,
                             self.average_transmiter_power,
                             self.reflectivity_calibration_correction,
                             self.data_transmision_enabled,
                             self.vcp_number,self.RDA_control_authorization,
                             self.RDA_build_number,
                             self.operational_mode,self.super_resolution_status,
                             self.spare_1[0],self.spare_1[1],self.RDA_alarm_summary,
                             self.command_acknowledgment,self.channel_control_status,
                             self.spot_blanking_status,0,0,0,0,0,0,
                             self.rms_control_status,0,*self.alarm_codes)
        return result
