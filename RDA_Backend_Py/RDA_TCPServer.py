'''
Created on 04/01/2013

@author: vladimir
'''
import struct, socket, time
from xml.dom import minidom
import subprocess


from CODE_messages import *
from RDA_Status import RDA_Status
from VCP_Data import VCP_Data
from Loopback_Test import Loopback_Test
from CTM_Header import *
from MSG_Header import MSG_Header
from RDAControlCommands import RDAControlCommands
from Clutter_Filter_Map import Clutter_Filter_Map
from Clutter_Filter_Bypass_Map import Clutter_Filter_Bypass_Map
from Obs_Parser import Obs_Parser
from Digital_Radar_Data import *


# My constants
FSEQUENCE_NUMBER_SIZE   = 65535
MSG_HEADER_SIZE         = 8 # HalfWords
WAIT_BEFORE_CONNECTING  = 10e-3 # sec
WAIT_FOR_ORPG           = 0
WAIT_FOR_NEXT_DATA      = 0#.042 # sec
MAX_REF_CELLS           = 1840 # 460km at 250m
MAX_VEL_CELLS           = 1200 # 300km at 250m
MAX_SW_CELLS            = 1200 # 300km at 250m

DEBUG = False 
VERBOSE = True
RADAR_TABLE = {'rdLaBajada': b'CLBJ', 'rdPuntaDelEste': b'CPDE', 'rdCasablanca': b'CCSB', 
          'rdPicoSanJuan': b'CPSJ', 'rdCamaguey': b'CCMW', 'rdPilon': b'CPLN', 
          'rdGranPiedra': b'CGPD', 'rdHolguin': b'CHLG', 'rdCamaguey1': b'CCMW'}
VCP_TABLE = {"VCP_31": 72, "VCP_111_Merged":71,  "VCP_111": 71}
BASE_DIR = '/home/vladimir/Dicso/Salvas-LAP-ene2017/Documents/Meteorologia/RDA_Backend/'
VCP_DESCRIPTOR_XML = BASE_DIR + 'RDA_Backend_Py/RDA_Backend_4.vcp.xml'

class RDA_TCPServer:
    '''
    classdocs
    '''
    def __init__(self):
        '''
        Constructor
        '''
        self.dMessageName ={1:'Digital Radar Data',
                            2:'RDA Status Data',
                            3:'Performance/Maintenance Data',
                            4:'Console Mensaje',
                            10:'Console Mensaje',                        
                            11:'Loopback Test',
                            12:'Loopback Test',
                            13:'Clutter Filter Bypass Map',
                             6:'RDA Control Commands',
                             5:'Volume Coverage Pattern',
                             7:'Volume Coverage Pattern',
                             8:'Clutter Sensor Zones',
                             9:'Request for Data',
                            15:'Clutter Filter Map',
                            18:'RDA Adaptation Data',
                            31:'Digital Radar Data Generic Format Blocks'}
        
        self.dRequest_Data = {129:  2, # Request Sumary RDA Status
                              130:  3, # Request RDA Performance/
                                       # Maintenance Data
                              132: 13, # Request Clutter Filter Bypass Map
                              136: 15, # Request Clutter Filter Map
                              144: 18, # Request RDA Adaptation Data
                              160:  5  # Request Volume Coverage Pattern Data
                              }
        
        self.fsequence_number = 0
        
        
        self.set_RDA_Channel(0)
        
        self.fRDA_Status = RDA_Status()
        self.fLBT = Loopback_Test()
        self.fCFM = Clutter_Filter_Map()
        self.fCFBM = Clutter_Filter_Bypass_Map()
        
        # Messages Streams (generation functions) Dictionary
        self.fMsg_function = {2:self.fRDA_Status.create_RDA_Status_Msg}  
        self.fMsg_function.setdefault(11,self.fLBT.create_LBT_Msg)
        
        # The initial VCP
        VCP_NUMBER = 72
        fVCP_Table = minidom.parse(VCP_DESCRIPTOR_XML)
        self.fVCP_Data = VCP_Data(VCP_NUMBER,fVCP_Table)          
        self.fMsg_function.setdefault(5,self.fVCP_Data.get_Stream)
        
        # Received
        self.fMsg_string ={18:b"orda_adapt_data_msg.dat",
                              3:b"orda_perf_maint_msg.dat",
                             13:self.fCFBM.get_dummy_Map(),
                             15:self.fCFM.get_dummy_Map()}
        
        # Connections
        self.fConnected = False
        self.s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        host = ''
        port = 10010
        self.password="passwd"
        self.s.bind((host,port))
        # accept "call" from client
        self.s.listen(1)
        
        #self.send_Data()

    def send_Data(self,obs_name):
        # Getting Operate state and sending it
        self.fRDA_Status.RDA_status = RDS_OPERATE
        self.sendMessage(2)
        self.sendMessage(3)
        self.sendMessage(5)        
        
        observation = Obs_Parser(BASE_DIR + 'obs/'+obs_name)       
        radar = RADAR_TABLE[observation.Header.Radar] 
        
        # Use OBS time
        delta = datetime.datetime.now() - observation.Header.Obs_datetime
        
        # The actual VCP depends on the OBS data
        VCP_NUMBER = VCP_TABLE[observation.Header.stamp_Design]
        fVCP_Table = minidom.parse(VCP_DESCRIPTOR_XML)
        self.fVCP_Data = VCP_Data(VCP_NUMBER,fVCP_Table)          
        self.fMsg_function[5] = self.fVCP_Data.get_Stream
        
        VCP = VCP_NUMBER
        obs_index = 0
        Radial = [None,None,None]
        N_elev = self.fVCP_Data.number_of_elevation_cuts
        
        for elev_index in range(N_elev):
            chan    = observation.channels[
                        observation.ppis_header[obs_index].Description.channel]
            elevation = observation.ppis_header[obs_index].Description.angle
            gates   = chan.number_of_cells
            waveform_type = self.fVCP_Data.elevations[elev_index].waveform_type
            
            # Looking for a split cut
            previous_CS = False
            next_CS     = False
            if (elev_index > 0):
                if (self.fVCP_Data.elevations[elev_index - 1].waveform_type 
                    == 1) and (self.fVCP_Data.elevations[elev_index - 1].elevation_angle
                    == self.fVCP_Data.elevations[elev_index].elevation_angle):
                    previous_CS = True
            if (elev_index < N_elev-1):
                if (self.fVCP_Data.elevations[elev_index + 1].waveform_type 
                    == 1) and (self.fVCP_Data.elevations[elev_index + 1].elevation_angle
                    == self.fVCP_Data.elevations[elev_index].elevation_angle):
                    next_CS = True
                    
            if waveform_type == 1: # CS
                nMoments    = 1
                nREF_gates  = min(gates, MAX_REF_CELLS)
                nVEL_gates  = 0
                nSW_gates   = 0
                Radial[1]   = None
                Radial[2]   = None
                for Azim in range(360):
                    Radial[0] = observation.ppis[obs_index][Azim][:nREF_gates]
                    CSN = 0
                    self.create_Msg_31(radar, delta, Radial,VCP,Azim,CSN,elev_index,
                                       N_elev - 1,elevation,nMoments,nREF_gates,
                                       nVEL_gates,nSW_gates)
                    self.sendMessage(31)
                    time.sleep(WAIT_FOR_NEXT_DATA)
                #obs_index += nMoments
            elif(previous_CS or next_CS): # CD split cut
                nMoments    = 2
                nREF_gates  = 0
                nVEL_gates  = min(gates, MAX_VEL_CELLS)
                nSW_gates   = min(gates, MAX_SW_CELLS)
                Radial[0]   = None
                for Azim in range(360):
                    Radial[1] = observation.ppis[obs_index][Azim][:nVEL_gates]
                    Radial[2] = observation.ppis[obs_index+1][Azim][:nSW_gates]
                    CSN = self.fVCP_Data.elevations[elev_index].\
                        get_Cut_Sector_Number(Azim) # TODO assumed 1deg width
                    self.create_Msg_31(radar, delta, Radial,VCP,Azim,CSN,elev_index,
                                       N_elev - 1,elevation,nMoments,nREF_gates,
                                       nVEL_gates,nSW_gates)
                    self.sendMessage(31)
                    time.sleep(WAIT_FOR_NEXT_DATA)
                #obs_index += nMoments
            else: # CD or CDX, no split cut
                nMoments    = 3
                nREF_gates  = min(gates, MAX_REF_CELLS)#1000 #TODO ORPG 230km
                nVEL_gates  = min(gates,  MAX_VEL_CELLS)
                nSW_gates   = min(gates, MAX_SW_CELLS)                
                for Azim in range(360):
                    Radial[0] = observation.ppis[obs_index][Azim][:nREF_gates]
                    Radial[1] = observation.ppis[obs_index+1][Azim][:nVEL_gates]
                    Radial[2] = observation.ppis[obs_index+2][Azim][:nSW_gates]
                    CSN = self.fVCP_Data.elevations[elev_index].\
                         get_Cut_Sector_Number(Azim) # TODO assumed 1deg width
                    self.create_Msg_31(radar, delta, Radial,VCP,Azim,CSN,elev_index,
                                       N_elev - 1,elevation,nMoments,nREF_gates,
                                       nVEL_gates,nSW_gates)
                    self.sendMessage(31)
                    time.sleep(WAIT_FOR_NEXT_DATA)
                    
            obs_index += nMoments
                
                
            

    def create_Msg_31(self, radar, delta, radial,VCP,AZ_index,CSN,EL_index,Last_EL,
                      Elevation_Angle,nMoments, nREF_gates, nVEL_gates,
                      nSW_gates):
        dhb = Data_Header_Block(radar, delta, AZ_index,CSN,EL_index,Last_EL,Elevation_Angle, 
                                nMoments, nREF_gates, nVEL_gates, nSW_gates)
        #dhb.print_HB()
        db1 = DB_Volume_Data(VCP)
        db2 = DB_Elevation_Data(db1)        
        db3 = DB_Radial_Data()
        
        if nMoments == 1:
            db4 = DM_Data_Block(DM_REF, nREF_gates)        
            radial0 = DM_REF.data2code(radial[0])
            data_stream = db4.get_Stream() + \
                            struct.pack(str(nREF_gates)+'B',*radial0)
                            
        if nMoments == 2:
            db4 = DM_Data_Block(DM_VEL, nVEL_gates)
            radial1 = DM_VEL.data2code(radial[1])
            data_stream = db4.get_Stream() + \
                            struct.pack(str(nVEL_gates)+'B',*radial1)  
                                      
            db5 = DM_Data_Block(DM_SW, nSW_gates)
            radial2 = DM_SW.data2code(radial[2])
            data_stream += db5.get_Stream() + \
                            struct.pack(str(nSW_gates)+'B',*radial2)
                            
        if nMoments == 3:
            db4 = DM_Data_Block(DM_REF, nREF_gates)        
            radial0 = DM_REF.data2code(radial[0])
            data_stream = db4.get_Stream() + \
                            struct.pack(str(nREF_gates)+'B',*radial0)
                            
            db5 = DM_Data_Block(DM_VEL, nVEL_gates)
            radial1 = DM_VEL.data2code(radial[1])
            data_stream += db5.get_Stream() + \
                            struct.pack(str(nVEL_gates)+'B',*radial1)  
                                      
            db6 = DM_Data_Block(DM_SW, nSW_gates)
            radial2 = DM_SW.data2code(radial[2])
            data_stream += db6.get_Stream() + \
                            struct.pack(str(nSW_gates)+'B',*radial2)                       
        
        Msg = dhb.get_Stream() + db1.get_Stream() +\
              db2.get_Stream() + db3.get_Stream() +\
              data_stream
        
        if 31 in self.fMsg_string:
            self.fMsg_string[31] = Msg
        else:
            self.fMsg_string.setdefault(31,Msg)
        
        
        
    def doExecute(self):
#        try:
        self.conn, addr = self.s.accept()
        if DEBUG: print('ORPG on:', addr)
        # create "file-like object" flo
        flo = self.conn.makefile('rb',0) # read-only, unbuffered
        
        while 1:
            # Get and process request from ORPG
            self.process_Requests(flo);
            # Process digital data
            self.process_Digital_Data(flo);
                    
        
    def process_Requests(self,flo):
        self.fTimeOfLastMess = time.localtime()
        
        s = self.blocked_read(flo, 2*CTM_HEADER_SIZE)
            
        CTM = CTM_Header(s)
        if DEBUG: print('Session Message type:', CTM.Typ)
        
        if CTM.Typ == 0: # login request
            self.process_Login(CTM, flo)
            
        if CTM.Typ == 2: # data
            if self.fConnected:
                self.process_Data(CTM,flo)
                
        if CTM.Typ == 4: # kepp alive
            if self.fConnected:
                self.process_KeppAlive(CTM)
                self.processObsDir()
                
                
    def process_Login(self,CTM,flo):
        stream = flo.read(CTM.Len).decode("utf-8")
        words = stream.split()
        if DEBUG: print('Password :', words[-1].strip('\x00'))
        
        if self.password == words[-1].strip('\x00'): # Checking pass
            # Send acknowledgement            
            CTM.Typ = 1 # login acknowledgement
            s = words[0] + ' ' + words[1] + ' connected\0'
            CTM.Len = s.__len__()
            
            time.sleep(WAIT_BEFORE_CONNECTING)
            self.conn.sendall(CTM.get_Stream() + s.encode("utf-8"))
            
            self.fConnected = True
            self.fRDA_Status.RDA_status = RDS_STANDBY
            
            self.sendMessage(11) # make LoopBackTest
            self.fSendMetadata = True
            
        if self.fConnected and VERBOSE:
            print('RDA === RPG sucessfull connected.')

            
            
    def sendMessage(self,Msg_number,Ack = False):
        #sleep(1e-3)
        if Msg_number in self.fMsg_function:
            Msg = self.fMsg_function[Msg_number]() # always updated
        else:            
            Msg = self.fMsg_string[Msg_number]      
            
        # ''''For all message numbers as described in Table II (Message Header 
        # Data RDA-RPG-ICD-2620002G page 16), Data Message Types, the maximum 
        # segment size is 1208 halfwords except for Message Type 31, Digital 
        # Radar Data Generic Format, which can have a segment as large as 65535H.'''

            M_Count = 1
            i = 0
            transf = Msg
            
            # Message Header
            fMSG_Header = MSG_Header()
            MH = fMSG_Header.construc_Msg_Header(MSG_HEADER_SIZE +
                                                 transf.__len__()/2, 
                                                 Msg_number, M_Count, i+1, 
                                                 self.fsequence_number,
                                                 self.fRDA_Channel)
            
            # Message CTM Header
            CTM = CTM_Header()
            CTM.Typ = 2 # DATA
            if Ack:
                CTM.par = self.fsequence_number
            else:
                CTM.par = 0
            CTM.Len = 2*MSG_HEADER_SIZE + transf.__len__()
            
            # Send Message
            self.conn.sendall(CTM.get_Stream() + MH + transf)
            
        if Msg_number == 11:
            time.sleep(WAIT_FOR_ORPG) # wait for ORPG loopback response
        if VERBOSE:
            print('Message send: ', Msg_number, ' -> ', \
                self.getMessageName(Msg_number) , ' ', time.asctime())
        
        #sleep(1e-3)
            
   
    def process_Data(self,CTM,flo):
        MH = MSG_Header(self.blocked_read(flo, 2*MSG_HEADER_SIZE))
#        if DEBUG:
#            MH.print_Header()
        
        s = self.blocked_read(flo, 2*(MH.message_size - 
                              MSG_HEADER_SIZE))
        
        self.fMsg_string.setdefault(MH.message_Type,s)
        
        # Send data Acknowledgement
        if CTM.par != 0:
            CTM.Typ = 3
            CTM.Len = 0
            self.conn.sendall(CTM.get_Stream())
        
        if VERBOSE:
            print('Message recv: ',MH.message_Type, ' <- ', \
                self.getMessageName(MH.message_Type) , ' ', time.asctime())
                
        if MH.message_Type == 12: # send to ORPG loopback response
            self.sendMessage(12)
            
        if MH.message_Type == 11: # check ORPG loopback response
            self.fLBT.process_LoopBack_Test(s)
            self.sendMessage(2)
            self.sendMessage(3)
            self.sendMessage(5)
            self.sendMessage(13)
            self.sendMessage(15)
            self.sendMessage(18)
            self.fSendMetadata = False
            
            
        if MH.message_Type == 9: # check ORPG loopback response
            self.process_Request_Data(s)
            
        if MH.message_Type == 7: # ORPG ask for changing VCP
            self.process_VCP(s)
            
        if MH.message_Type == 6: # ORPG control command
            rda_ControlCmd = RDAControlCommands(s)
            rda_ControlCmd.process_Control_Command(self.fRDA_Status)
            if DEBUG: rda_ControlCmd.print_Control_Command()
            self.processObsDir()
            # obs_file = subprocess.getoutput('ls ../obs').split('\n')       
            # print(obs_file)
            # for obs in obs_file:
            #     if obs != '':
            #         self.send_Data(obs)
            #         subprocess.getoutput('mv ../obs/'+obs+' ../old')
    
    def process_Digital_Data(self,flo):
        pass
    
    def processObsDir(self):
        obs_files = subprocess.getoutput('ls ' + BASE_DIR + 'obs').split('\n')       
        for obs in obs_files:
            if obs != '':
                self.send_Data(obs)
                subprocess.getoutput('mv '+BASE_DIR+'obs/'+obs+' '+BASE_DIR+'old')    
    
    def process_Request_Data(self,stream):
        Data_Request_Type = struct.unpack('>H',stream)[0]
        if DEBUG: print('Data_Request_Type :', Data_Request_Type)
        
        self.sendMessage(self.dRequest_Data[Data_Request_Type])

    
    
    def getMessageName(self, msg):
        if msg in self.dMessageName:
            result = self.dMessageName[msg]
        else:
            result = 'Unknow message'
        return result
    

    def get_sequence_number(self):
        self.fsequence_number += 1
        self.fsequence_number %= FSEQUENCE_NUMBER_SIZE
        return self.fsequence_number
    
    
    def set_RDA_Channel(self,Channel):
        self.fRDA_Channel = Channel
        self.fIsOpenRDA = (Channel & 0x8) > 0
        
        
    def blocked_read(self,flo,size):
        # Blocked until read the specified amount of bytes 
        came = 0
        s = b''
        
        while came < size:
            s += flo.read(size - came)
            came = s.__len__()
            
        return s
        
        
    def process_KeppAlive(self,CTM):
        self.conn.sendall(CTM.get_Stream())
        
    
    def process_VCP(self,stream):
        #TODO send an event for changing VCP  
        pass    
    
    
    def dummy_Message_from_File(self, filename):
        f = open(filename,'rb')  
        result = f.read()
        f.close()
        return result
