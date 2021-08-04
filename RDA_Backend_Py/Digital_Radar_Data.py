'''
Created on 11/01/2013

@author: vladimir
'''
import struct
import numpy as np

from CODE_messages import CONVERSIONS, START_OF_ELEVATION, \
                        PROCESSING_RADIAL_DATA, END_OF_ELEVATION, \
                        RDASIM_START_OF_VOLUME_SCAN, END_OF_VOLUME_SCAN

AZ_SECTOR_WIDTH     = 1.0 # deg
DATA_HEADER_SIZE    = 68 # Bytes
DATA_BLOCK_SIZE     = 28 # Bytes
MAX_AZ_INDEX        = 359
RADAR_LAT           = 21.3836
RADAR_LONG          = -77.8451
RADAR_HEIGHT        = 150 # -100m

class Data_Moment:
    '''
    Data Moment Characteristics and Conversion for Data Names.
    Accuracy, precision, and range of each data moment is officially specified in the System
    Specification Document.
    RDA-RPG-ICD-2620002G page 100 Table XVII-I
    '''
    def __init__(self,name,description,offset,scale,units,Range,ldm):
        '''
        Constructor
        '''
        self.Data_Word_Size = 8 # Bits
        self.name           = name
        self.DM_description = description
        self.offset         = offset
        self.scale          = scale
        self.units          = units
        self.range          = Range # Km
        self.ldm            = ldm
    
    
    def data2code(self,data):
        '''
        converts data from its value to a code (byte)
        data is a numpy array
        '''
        data[data < -self.offset] = -self.offset/self.scale
#        # No zero vel or sw
#        if self.units == 'm/s':
#            data[data == 0]  = -self.offset/self.scale
            
        data = np.ubyte(data*self.scale + self.offset)
        data[data < 2]      = np.ubyte(0) # No range folded data
        data[data > 255]    = np.ubyte(0) # No overflow
        return data
        
        
DM_REF = Data_Moment(b'REF','Reflectivity (Z)',66.0,2.0,'dBZ',460,1840)
# DM_VEL = Data_Moment('VEL','Velocity (V)',129.0,2.0,'m/s',460,1840)
# DM_SW  = Data_Moment('SW','Spectrum Width',129.0,2.0,'m/s',460,1840)
DM_VEL = Data_Moment(b'VEL','Velocity (V)',129.0,2.0,'m/s',300,1200)
DM_SW  = Data_Moment(b'SW','Spectrum Width',129.0,2.0,'m/s',300,1200)


class Data_Header_Block:
    '''
    Data Header Block
    RDA-RPG-ICD-2620002G page 92 Table XVII-A
    '''
    def __init__(self, radar, jd, mo, AZ_index,CSN,EL_index,Last_EL,Elevation_Angle,nMoments,
                 nREF_gates,nVEL_gates,nSW_gates):
        '''
        Constructor
        '''
        self.Last_EL    = Last_EL 
        self.nMoments   = nMoments      
        self.nREF_gates = nREF_gates
        self.nVEL_gates = nVEL_gates
        self.nSW_gates  = nSW_gates
        
        self.RDA_Id                         = radar
        self.collection_Time                = mo
        self.Modified_Julian_Date           = jd
        self.azimuth_Number                 = AZ_index + 1 # Starts at 1
        self.azimuth_Angle                  = AZ_SECTOR_WIDTH*AZ_index
        self.compression_Indicator          = 0 # Uncompressed        
        self.azimuth_Resolution_Spacing     = 2 # 1deg
        self.radial_Status                  = self.get_Radial_Status(AZ_index,
                                                                     EL_index)
        self.elevation_Number               = EL_index + 1 # Starts at 1
        self.cut_Sector_Number              = CSN        
        self.elevation_Angle                = Elevation_Angle
        self.radial_Spot_Blanking_Status    = 0 # None
        self.aszimuth_Indexing_Mode         = 0 # no indexing 
        self.data_Block_Count               = 3 + nMoments #TODO check this value
        self.data_Block_pointers            = self.get_DB_pointers()
        
        # Length in bytes including header
        self.radial_Length                  = 160 + nREF_gates
        if nVEL_gates > 0:
            self.radial_Length += 28 + nVEL_gates
        if nSW_gates > 0:
            self.radial_Length += 28 + nSW_gates


    def get_Stream(self):
        return struct.pack('>4sI2Hf2BH4Bf2BH6I',
                           self.RDA_Id,self.collection_Time,
                           self.Modified_Julian_Date,self.azimuth_Number,
                           self.azimuth_Angle,self.compression_Indicator,
                           0,self.radial_Length,self.azimuth_Resolution_Spacing,
                           self.radial_Status,self.elevation_Number,
                           self.cut_Sector_Number,self.elevation_Angle,
                           self.radial_Spot_Blanking_Status,
                           self.aszimuth_Indexing_Mode,self.data_Block_Count,
                           *self.data_Block_pointers)
    
    def print_HB(self):
        print( 'RDA_Id: ',self.RDA_Id,'\n',\
               'collection_Time: ',self.collection_Time,'\n',\
               'Modified_Julian_Date: ',self.Modified_Julian_Date,'\n',\
               'azimuth_Number: ',self.azimuth_Number,'\n',\
               'azimuth_Angle: ',self.azimuth_Angle,'\n',\
               'compression_Indicator: ',self.compression_Indicator,'\n',\
               'radial_Length: ',self.radial_Length,'\n',\
               'azimuth_Resolution_Spacing: ',self.azimuth_Resolution_Spacing,'\n',\
               'radial_Status: ',self.radial_Status,'\n',\
               'elevation_Number: ',self.elevation_Number,'\n',\
               'cut_Sector_Number: ',self.cut_Sector_Number,'\n',\
               'elevation_Angle: ',self.elevation_Angle,'\n',\
               'radial_Spot_Blanking_Status: ',self.radial_Spot_Blanking_Status,'\n',\
               'aszimuth_Indexing_Mode: ',self.aszimuth_Indexing_Mode,'\n',\
               'data_Block_Count: ',self.data_Block_Count)


    def get_DB_pointers(self):
        pointer_DB_VOL = 56
        pointer_DB_ELV = 100
        pointer_DB_RAD = 112
        pointer_DB_REF = 132 # VEL pointer if nMoments == 2
        pointer_DB_SW = 0
        pointer_DB_VEL = 0
        
        if self.nMoments == 2: # Assuming VEL + SW
            pointer_DB_VEL = pointer_DB_REF + 28 + self.nVEL_gates #SW pointer
            
        if self.nMoments == 3:
            pointer_DB_VEL = pointer_DB_REF + 28 + self.nREF_gates
            pointer_DB_SW  = pointer_DB_VEL + 28 + self.nVEL_gates
        
        return (pointer_DB_VOL, pointer_DB_ELV, pointer_DB_RAD, pointer_DB_REF,
                pointer_DB_VEL, pointer_DB_SW)
        

    def get_Radial_Status(self, AZ_index, EL_index):
        if (AZ_index == 0) and (EL_index == 0):
            result = RDASIM_START_OF_VOLUME_SCAN
        elif (self.Last_EL == EL_index) and (AZ_index == MAX_AZ_INDEX):
            result = END_OF_VOLUME_SCAN
        elif AZ_index == 0:
            result = START_OF_ELEVATION
        elif AZ_index == MAX_AZ_INDEX:
            result = END_OF_ELEVATION
        else:
            result = PROCESSING_RADIAL_DATA
        
        print('Radial Status: ',result)
        return result
                

class DM_Data_Block:
    '''
    Data Block (Descriptor of Generic Data Moment Type)
    RDA-RPG-ICD-2620002G page 104 Table XVII-B
    '''
    def __init__(self,DM,ngates):
        '''
        Constructor
        DM : Data_Moment
        '''
        self.data_Block_Type        = b'D' 
        self.data_Moment_Name       = DM.name
        self.Reserved               = 0
        self.number_of_DM_Gates     = ngates
        self.data_Moment_Range      = 0   # Range to center of first range gate
        self.DM_Range_Interval      = 250 # Meters
        self.tover                  = 1 
        self.snr_Threshold          = 12  # 1/8 dB
        self.control_Flags          = 0
        self.data_Word_Size         = DM.Data_Word_Size
        self.scale                  = DM.scale
        self.offset                 = DM.offset
           
 
    def get_Stream(self):
        return struct.pack('>1s3sI5H2B2f',
                           self.data_Block_Type,self.data_Moment_Name,
                           self.Reserved,self.number_of_DM_Gates,
                           self.data_Moment_Range,self.DM_Range_Interval,
                           self.tover,self.snr_Threshold,self.control_Flags,
                           self.data_Word_Size,self.scale,self.offset)


class DB_Volume_Data:
    '''
    Data Block (Volume Data Constant Type)
    RDA-RPG-ICD-2620002G page 97 Table XVII-E
    '''
    def __init__(self,VCP_number):
        '''
        Constructor
        '''
        self.data_Block_Type        = b'R'
        self.data_Name              = b'VOL'
        self.size_of_data_block     = 44 # Bytes
        self.major_version_number   = 1
        self.minor_version_number   = 0
        self.lat                    = RADAR_LAT
        self.long                   = RADAR_LONG
        self.site_Height            = RADAR_HEIGHT
        self.feedhorn_height        = 3
        self.calibration_constant   = -54.0 #TODO from rda_simulator
        self.horizontal_shv_tx_power= 500.0 # Kw
        self.vertical_shv_tx_power  = 0.0
        self.system_diferential_Z   = 0.0
        self.initial_sys_diff_phase = 0.0
        self.vcp_number             = VCP_number
        
        
    def get_Stream(self):
        return struct.pack('>1s3sH2B2f2H5f2H',self.data_Block_Type,
                               self.data_Name,self.size_of_data_block,
                               self.major_version_number,
                               self.minor_version_number,self.lat,self.long,
                               self.site_Height,self.feedhorn_height,
                               self.calibration_constant,
                               self.horizontal_shv_tx_power,
                               self.vertical_shv_tx_power,
                               self.system_diferential_Z,
                               self.initial_sys_diff_phase,self.vcp_number,0)
                           

class DB_Elevation_Data:
    '''
    Data Block (Elevation Data Constant Type)
    RDA-RPG-ICD-2620002G page 107 Table XVII-F
    '''
    def __init__(self,volume):
        '''
        Constructor
        volume : DB_Volume_Data
        '''
        self.data_Block_Type        = b'R'
        self.data_Name              = b'ELV'
        self.size_of_data_block     = 12 # Bytes
        self.ATMOS                  = -11 # 1/1000 dB/Km
        self.calibration_constant   = volume.calibration_constant
        
        
    def get_Stream(self):
        return struct.pack('>1s3sHhf',self.data_Block_Type,self.data_Name,
                           self.size_of_data_block,self.ATMOS,
                           self.calibration_constant)
    
        
class DB_Radial_Data:
    '''
    Data Block (Radial Data Constant Type)
    RDA-RPG-ICD-2620002G page 99 Table XVII-H
    '''
    def __init__(self):   
        '''
        Constructor
        '''      
        self.data_Block_Type                = b'R'
        self.data_Name                      = b'RAD'
        self.size_of_data_block             = 20 # Bytes
        #TODO must be calculated !!
        self.unambiguous_range              = 115 * 10 # scaled/10
        self.horizontal_channel_noise_level = -100.0
        self.vertical_channel_noise_level   = -100.0
        self.nyquist_velocity               = 621 # scaled/100
        
        
    def get_Stream(self):
        return struct.pack('>1s3s2H2f2H',self.data_Block_Type,self.data_Name,
                           self.size_of_data_block,self.unambiguous_range,
                           self.horizontal_channel_noise_level,
                           self.vertical_channel_noise_level,
                           self.nyquist_velocity,0)
        