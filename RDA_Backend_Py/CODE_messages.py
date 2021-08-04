'''
Created on 09/01/2013

@author: vladimir
'''
'''
// Definition reference from:
//
// Interface Control Document for the RDA/RPG (ICD 2620002F)
//
// Open Build 10; 25 March 2008
// WSR-88D Radar Operations Center (ROC).
'''

cMessageFullSize = 1216; # "Message full size"

RDA_ADAPTATION_DATA = 18
RDA_VCP_MSG         =  5

CCS_CONTROLLING     = 0x0000 # RDA-RPG ICD Setting for this channel controlling 
CCS_NON_CONTROLLING = 0x0001 # RDA-RPG ICD Setting for this channel not controlling 

ALIGNMENT_SIZE = 4 ## of bytes for alignment 

cFALSE = 0
cTRUE  = 1

ZERO = 0
ONE  = 1

REQUEST_FOR_STATUS_DATA         = 129
REQUEST_FOR_PERFORMANCE_DATA    = 130
REQUEST_FOR_BYPASS_MAP_DATA     = 132
REQUEST_FOR_NOTCHWIDTH_MAP_DATA = 136

#Maximum sizes of data fields
BASEDATA_REF_SIZE     = 460
BASEDATA_VEL_SIZE     = 920
MAX_BASEDATA_REF_SIZE = 1840
BASEDATA_DOP_SIZE     = 1200
BASEDATA_RHO_SIZE     = 1200
BASEDATA_PHI_SIZE     = 1200
BASEDATA_SNR_SIZE     = 1840
BASEDATA_ZDR_SIZE     = 1200
BASEDATA_RFR_SIZE     = 240

MAX_MESSAGE_SIZE     = 2416
MAX_MESSAGE_31_SIZE  = 65535
MAX_BUFFER_SIZE      = 6600
MAX_NAME_SIZE        = 128
MAX_NUM_SURV_BINS    = 460  #max # of surveillance bins
MAX_SR_NUM_SURV_BINS = 1840 #max # of surveillance bins (super resolution)
MAX_NUM_VEL_BINS     = 920  #max # of velocity & spec width bins
MAX_SR_NUM_VEL_BINS  = 1200 #max # of velocity & spec width bins (super resolution)
MAX_NUM_ZDR_BINS     = BASEDATA_ZDR_SIZE
MAX_NUM_PHI_BINS     = BASEDATA_PHI_SIZE
MAX_NUM_RHO_BINS     = BASEDATA_RHO_SIZE
HALF_DEG_RADIALS     = 0.5
ONE_DEG_RADIALS      = 1.0
MAX_NUM_RADIALS      = 360 #max # of radials
MAX_SR_NUM_RADIALS   = 720 #max # of radials (super resolution)

NO_COMMAND_PENDING = -1 # state where a new command has not been received and
                        # a command to execute is not pending

# define the command states and processing states
START_OF_ELEVATION          = 0 #processing at begining of elevation
PROCESSING_RADIAL_DATA      = 1 #digital radar data being processed
END_OF_ELEVATION            = 2 #processing at the end of elevation cut
RDASIM_START_OF_VOLUME_SCAN = 3 #processing at the begining of vol scan
END_OF_VOLUME_SCAN          = 4 #processing at the end of vol scan
NO_PENDING_COMMAND          = 5 #a command is not pending
START_UP                    = 6
STANDBY                     = 7
RDA_RESTART                 = 8
OPERATE                     = 9
OFFLINE_OPERATE             = 10
PLAYBACK                    = 11
VCP_ELEVATION_RESTART       = 12

# RDA Status
RDS_STARTUP         = 0x0002
RDS_STANDBY         = 0x0004
RDS_RESTART         = 0x0008
RDS_OPERATE         = 0x0010
RDS_PLAYBACK        = 0x0020
RDS_OFFLINE_OPERATE = 0x0040

# RDA Operability Status
ROS_RDA_ONLINE                         = 0x0002
ROS_RDA_MAINTENANCE_REQUIRED           = 0x0004
ROS_RDA_MAINTENANCE_MANDATORY          = 0x0008
ROS_RDA_COMMANDED_SHUTDOWN             = 0x0010
ROS_RDA_INOPERABLE                     = 0x0020
ROS_RDA_AUTOMATIC_CALIBRATION_DISABLED = 0x0001

# RDA Control Status
RCS_RDA_LOCAL_ONLY  = 0x0002
RCS_RDA_REMOTE_ONLY = 0x0004
RCS_RDA_EITHER      = 0x0008

# Aux Power Generator State
APGS_AUXILIARY_POWER       = 0x0001
APGS_UTILITY_PWR_AVAILABLE = 0x0002
APGS_GENERATOR_ON          = 0x0004
APGS_XFER_SWITCH_IN_MANUAL = 0x0008
APGS_COMMANDED_SWITCHOVER  = 0x0010

# Data Transmision Enabled
DTE_NONE_ENABLED           = 0x0002
DTE_REFLECTIVITY_ENABLED   = 0x0004
DTE_VELOCITY_ENABLED       = 0x0008
DTE_SPECTRUM_WIDTH_ENABLED = 0x0010

# RDA Control Authorization
RCA_NO_ACTION              = 0x0000
RCA_LOCAL_CONTROL_REQUEST  = 0x0002
RCA_REMOTE_CONTROL_ENABLED = 0x0004

# RDA Operational Mode
ROM_MAINTENANCE = 0x0002
ROM_OPERATIONAL = 0x0004

# Super Resolution Status
SRS_ENABLED  = 0x0002
SRS_DISABLED = 0x0004

# Archive II Status
A2S_NOT_INSTALLED      = 0x0000
A2S_INSTALLED          = 0x0001
A2S_LOADED             = 0x0002
A2S_WRITE_PROTECTED    = 0x0004
A2S_RESERVED           = 0x0008
A2S_RECORD             = 0x0010
A2S_PLAYBACK_AVAILABLE = 0x0020
A2S_GENERATE_DIRECTORY = 0x0040
A2S_POSITION           = 0x0080

# RDA Alarm Summary
RAS_NO_ALARMS                 = 0x0000
RAS_TOWER_UTILITIES           = 0x0002
RAS_PEDESTAL                  = 0x0004
RAS_TRANSMITTER               = 0x0008
RAS_RECEIVER_SIGNAL_PROCESSOR = 0x0010
RAS_RECEIVER                  = 0x0010 # ORDA only
RAS_RDA_CONTROL               = 0x0020
RAS_RPG_COMMUNICATIONS        = 0x0040
RAS_USER_COMMUNICATION        = 0x0080
RAS_SIGNAL_PROCESSOR          = 0x0080 # ORDA only
RAS_ARCHIVE_II                = 0x0100

# Command Acknowledgement
CA_NO_ACKNOWLEDGEMENT                     = 0x0000
CA_REMOTE_VCP_RECEIVED                    = 0x0001
CA_CLUTTER_BYPASS_MAP_RECEIVED            = 0x0002
CA_CLUTTER_CENSOR_ZONES_RECEIVED          = 0x0003
CA_REDUNDANT_CHANNEL_STANDBY_CMD_ACCEPTED = 0x0004

# Spot Blanking Status
SBS_NOT_INSTALLED = 0x0000
SBS_ENABLED       = 0x0002
SBS_DISABLED      = 0x0004

#
RDASIM_VOL_DATA = -3
RDASIM_ELV_DATA = -2
RDASIM_RAD_DATA = -1

RDASIM_REF_DATA = 1
RDASIM_VEL_DATA = 2
RDASIM_WID_DATA = 3
RDASIM_ZDR_DATA = 4
RDASIM_PHI_DATA = 5
RDASIM_RHO_DATA = 6

MAX_DATA_BLOCKS = 9

# Processing state in TReq_struct or TResp_struct
CM_NEW  = 0 #new and unprocessed
CM_DONE = 1 #processing finished and response sent

# Values for link_state
LINK_DISCONNECTED = 0
LINK_CONNECTED    = 1

# Values for conn_activity
NO_ACTIVITY   = 0 #No connect/disconnect request is being processed
CONNECTING    = 1 #a connect request is being processed
DISCONNECTING = 2 #a disconnect request is being processed

#ICD Defined message types
DIGITAL_RADAR_DATA           = 1
RDA_STATUS_DATA              = 2
PERFORMANCE_MAINTENANCE_DATA = 3
CONSOLE_MESSAGE_A2G          = 4
RDA_RPG_VCP                  = 5
RDA_CONTROL_COMMANDS         = 6
RPG_RDA_VCP                  = 7
CLUTTER_SENSOR_ZONES         = 8
REQUEST_FOR_DATA             = 9
CONSOLE_MESSAGE_G2A          = 10
LOOPBACK_TEST_RDA_RPG        = 11
LOOPBACK_TEST_RPG_RDA        = 12
CLUTTER_FILTER_BYPASS_MAP    = 13
EDITED_CLUTTER_FILTER_MAP    = 14
NOTCHWIDTH_MAP_DATA          = 15 #Legacy RDA
CLUTTER_MAP_DATA             = 15 #ORDA
ADAPTATION_DATA              = 18
GENERIC_DIGITAL_RADAR_DATA   = 31

#Super resolution
SR_NOCHANGE = 0
SR_ENABLED  = 2
SR_DISABLED = 4

#comm_manager
MAX_N_LINKS    = 48                 #maximum number of links this comm_manager can manage
MAX_N_STATIONS = 3                  #max number of PVCs per link
MAX_N_REQS     = 5 + MAX_N_STATIONS #number of pending request per link

#comm_manager request types ("type" in TCM_req_struct or TCM_resp_struct)
CM_CONNECT    = 0 # make a connection on link "link_ind" 
CM_DIAL_OUT   = 1 # dail out and make a connection on link "link_ind" 
CM_DISCONNECT = 2 # terminate the connection on link "link_ind" 
CM_WRITE      = 3 # write a message of size "data_size" on link "link_ind" with priority "parm"
                  # The data is in message of id "data_id"
                  # The prority level can be between 0 -  MAX_N_STATIONS - 1
                  # 0 indicaets the highest 
CM_STATUS     = 4 # request a status response on link "link_ind" 
CM_CANCEL     = 5 # cancel the previous req of number "parm" 
CM_DATA       = 6 # a incoming data message from the user 
CM_EVENT      = 7 # a event notification from the comm_manager 
CM_SET_PARAMS = 8 # sets/resets link parameters 

# comm_manager return codes in the response messages ("ret_code" in TCM_resp_struct)
CM_SUCCESS             = 0     # requested action completed successfully 
CM_TIMED_OUT           = 1     # transaction time-out 
CM_NOT_CONFIGURED      = 2     # failed because the link is not configured for the requested task 
CM_DISCONNECTED        = 3     # the connection is not built or lost 
CM_CONNECTED           = 4     # the link is connected  
CM_BAD_LINK_NUMBER     = 5     # the specified link is not configured 
CM_INVALID_PARAMETER   = 6     # a parameter is illegal in the request 
CM_TOO_MANY_REQUESTS   = 7     # too many pending and unfinished requests 
CM_IN_PROCESSING       = 8     # a previous request of the same type is being processed 
CM_TERMINATED          = 9     # requested failed because a new conflicting request started 
CM_FAILED              = 10 # requested action failed 
CM_REJECTED            = 11 # requested action is rejected by the other side of the link 
CM_LOST_CONN           = 12 # connection lost due to remote action 
CM_CONN_RESTORED       = 13 # connection restored due to remote action 
CM_LINK_ERROR          = 14 # a link error is detected and the link is disconnected 
CM_START               = 15 # this comm_manager instance is just started 
CM_TERMINATE           = 16 # this comm_manager instance is going to terminates 
CM_STATISTICS          = 17 # a statistics reporting event 
CM_EXCEPTION           = 18 # line exception (hardware or software errors detected) 
CM_NORMAL              = 19 # returned to normal from exception state 
CM_PORT_IN_USE         = 20 # Dial port is in use  by another client
CM_DIAL_ABORTED        = 21 # reset was pressed at the modem front panel during dilaing or modem did not detect a dial tone
CM_INCOMING_CALL       = 22 # modem detected an incoming ring after dialing command was entered
CM_BUSY_TONE           = 23 # Modem detected a busy tone after dialing
CM_PHONENO_FORBIDDEN   = 24 # The no. is on the forbidden numbers list 
CM_PHONENO_NOT_STORED  = 25 # phone no. not strored in modem memory
CM_NO_DIALTONE         = 26 # No answer-back tone or ring-back tone was detected in the remote modem
CM_MODEM_TIMEDOUT      = 27 # Ringback is detected, but the call is not completed due to  timeout, i.e modem did not send any response with in the timeout value
CM_INVALID_COMMAND     = 28 # Invalid dialout command or a command that the modem cannot execute 
CM_TRY_LATER           = 29 # Try the request at a later time
CM_MODEM_PROBLEMS      = 30 # General catch all modem dial-out problems 
CM_MODEMRETRY_PROBLEMS = 31 # General catch all modem retry-able dial-out problems 
CM_RTR_PROBLEMS        = 32 # General catch all router dial-out problems 
CM_RTRRETRY_PROBLEMS   = 33 # General catch all router retry-able dial-out problems 
CM_DIAL_TIMEOUT        = 35 # After about 25 seconds modem still didn't go offhook  
CM_STATUS_MSG          = 36 # 35 # A status message from cm_tcp 
CM_BUFFER_OVERFLOW     = 37 # To-be-packed messages expired in the request buffer. 
CM_WRITE_PENDING       = 38 # response for CM_STATUS request 

#rda_rpg_clutter_map.h
MAX_BYPASS_MAP_SEGMENTS         = 2   #Max num elev segs
ORDA_MAX_BYPASS_MAP_SEGMENTS    = 5   #Max num elev segs
BYPASS_MAP_RADIALS              = 256 #Num radials (legacy)
ORDA_BYPASS_MAP_RADIALS         = 360 #Num radials (orda)
BYPASS_MAP_BINS                 = 512 #Num range bins
HW_PER_RADIAL                   = 32  #Num halfwords per radial

#orda_clutter_map.h
MAX_RANGE_ZONES_ORDA      = 25
NUM_AZIMUTH_SEGS_ORDA      = 360
MAX_ELEVATION_SEGS_ORDA    = 5

#used for converting azimuth/elevation rate data to BAMS and viceversa
ORPGVCP_RATE_BAMS2DEG = 22.5/16384.0
ORPGVCP_RATE_DEG2BAMS = 16384.0/22.5
ORPGVCP_RATE_HALF_BAM = 0.010986328125/2.0

#used for converting azimuth/elevation angles to BAMS and viceversa
ORPGVCP_AZIMUTH_RATE_FACTOR  = 45.0/32768.0
ORPGVCP_ELVAZM_BAMS2DEG      = 180.0/32768.0
ORPGVCP_ELVAZM_DEG2BAMS      = 32768.0/180.0
ORPGVCP_HALF_BAM             = 0.043945/2.0
ORPGVCP_ELEVATION_ANGLE      = 0x0001
ORPGVCP_AZIMUTH_ANGLE        = 0x0002
ORPGVCP_ANGLE_FULL_PRECISION = 0x0008

DEFAULT_VELOCITY_RESOLUTION =   2 # ICD defined 0.5 m/s Doppler velocity resolution 
FAT_RADIAL_SIZE             = 2.1 # size of a fat radial in degrees 
LOCAL_VCP                   =   1 # vcp data is a local vcp 
REMOTE_VCP                  =   2 # vcp data is a remote vcp 
VELOCITY_DATA               =   1 # specifies the data is velocity data 
ANGULAR_ELEV_DATA           =   2 # specifies the data is an elevation angle 
ANGULAR_AZM_DATA            =   3 # specifies the data is an azimuth angle 
NUMBER_LOCAL_VCPS           =   6 # # local/RDA VCPs defined 
NUMBER_PRFS_DEFINED         =   8 # # PRFs defined for PRI #3 
MAX_NUMBER_LOCAL_ELEV_CUTS  =  16 # max number local/RDA elevation cuts for the local VCPs defined 
MAX_ELEV_CUTS               = 100 # max number of elevation cuts allowed (this number was arbitrarily selected)

# Data conversion type
SCALED_SINT_2 = 111 

#################################################################################
###################### value conversion routines ################################
#################################################################################
from matplotlib import dates
import datetime, time

class Conversions:
    def __init__(self):
        pass
    
    
    def JulianDate_msec(self, dt = None):
            if (dt == None):
                dt = datetime.datetime.now()
            t = dt.time() # Now
                        
            sec_day  = t.hour * 3600 + t.minute * 60 + t.second
            mo = sec_day*1000 # Miliseconds of day
            jd = int(dt.timestamp()/dates.SEC_PER_DAY) + 1 # sec to days
            
            return jd, mo
        
        
    def Convert_data_out(self,number,type):
        result = None
        
        if (type == ANGULAR_ELEV_DATA) or (type == ANGULAR_AZM_DATA):
            if number < 0:
                number += 360
            while number > 360:
                number -= 360
            result = int(number/180.*4096)*8 # Table III-A Angle Data Format
            
        if type == VELOCITY_DATA:
            if number < 0:
                result = int(number/22.5*2048 + 2**12)*8 # Table XI-D Azimuth and Elevation Rate Data
            else:
                result = int(number/22.5*2048)*8
                
        if type == SCALED_SINT_2:
            result = int(number*8) # Data Formats (Scaled SInteger*2)

            
        if result == None:
            class WrongType_Exception(BaseException):
                pass
            raise WrongType_Exception('Unknown conversion type: %i' % type)
        return result


CONVERSIONS = Conversions()