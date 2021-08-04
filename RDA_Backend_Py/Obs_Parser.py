'''
Created on 11/01/2013

@author: vladimir
'''

import struct, zlib, pylab
from datetime import datetime, timedelta


OLE_TIME_ZERO   = datetime(1899, 12, 30, 0, 0, 0) # win32 time
HEADER_SIZE     = 84 # Bytes
CHANNEL_SIZE    = 32 # Bytes
PPI_DESC_SIZE   = 28 # Bytes
PPI_HEADER_SIZE = 12 # Bytes

dRadar = {0:'rdNone', 1:'rdLaBajada', 2:'rdPuntaDelEste', 3:'rdCasablanca', 
          4:'rdPicoSanJuan', 5:'rdCamaguey', 6:'rdPilon', 7:'rdGranPiedra', 
          8:'rdMcGill', 9:'rdRoma', 10:'rdCP2_SCMS', 11:'rdHolguin', 
          12:'rdVenMaracaibo', 13:'rdVenJeremba', 14:'rdVenGuasdualito', 
          15:'rdVenAyacucho', 16:'rdVenCarupano', 17:'rdVenKarum', 
          18:'rdVenSantaElena', 19:'rdVenGuri', 20:'rdCamaguey1'}

dMeasure = {0:'unNone', 1:'unDB', 2:'unDBZ', 3:'unMMH', 4:'unMS', 5:'unMM', 
            6:'unM', 7:'unKM', 8:'unKGM', 9:'unZDR', 10:'unPDP', 11:'unRho', 
            12:'unKDP', 13:'unGCP', 14:'unTID', 15:'unM2S2', 16:'unSW'}
            
class Obs_Parser:
    '''
    classdocs
    '''


    def __init__(self,filename):
        '''
        Constructor
        '''
        # Loading File Header
        f = open(filename,'rb')
        self.s = f.read()
        f.close()
        self.Header = VestaFileHeader(self.s)
        
        # PPI locations in binary file
        loc_end = 4*self.Header.ppi_count+HEADER_SIZE
        self.locations = struct.unpack(str(self.Header.ppi_count) + 
                                            'I', self.s[HEADER_SIZE:loc_end])
        
        # Channels Description
        self.channels = []
        for i in range(self.Header.channel_count):
            self.channels.append(ChannelDesc(self.s[loc_end + i*CHANNEL_SIZE:]))
        
        # PPI headers and Data
        self.ppis_header = []
        self.ppis = []
        for i,location in enumerate(self.locations):
            self.ppis_header.append(Vesta_PPI_Header(self.s,location))
            
            size = self.ppis_header[i].packed_Size
            pos  = location+PPI_DESC_SIZE+PPI_HEADER_SIZE
            
            # Decompress
            if self.ppis_header[i].pack_Method == 'pmZLib':
                self.ppis.append(zlib.decompress(self.s[pos:pos+size]))
            else:
                print('Unhadled compression method')
            
            if self.ppis[i].__len__() != self.ppis_header[i].unpacked_Size:
                class CorruptFile_Exception(BaseException):
                    pass
                raise CorruptFile_Exception('Error decompressing .obs file')
            
            chan    = self.channels[self.ppis_header[i].Description.channel]
            sectors = chan.num_of_sectors
            gates   = chan.number_of_cells 
            size = sectors*gates
            self.ppis[i] = pylab.array(struct.unpack(str(size)+'B',self.ppis[i][:size]))
            
            # 2D Data array radial sectors contains range gates# print self.ppis_header[i].Description.channel, sectors, gates, self.ppis_header[i].unpacked_Size
            self.ppis[i] = self.ppis[i].reshape((sectors,gates))
            # From .obs code to value
            if self.ppis_header[i].Description.meassurement == 'unDBZ':
                self.ppis[i] -= 80
#                # 230Km correction for ORPG
#                if gates < 1000:
#                    a = -80*pylab.ones((1000,sectors))
#                    a[:gates] = self.ppis[i].swapaxes(0,1)
#                    self.ppis[i] = a.swapaxes(0,1)
                    
            if (self.ppis_header[i].Description.meassurement == 'unMS' or
                    self.ppis_header[i].Description.meassurement == 'unSW'):
                self.ppis[i] = (self.ppis[i] -128)/2.
                # if self.ppis_header[i].Description.meassurement == 'unMS':
                #     self.ppis[i] *= -1 #TODO speed sign correction
                     
        # Plot a demo ppi
#        for i in range(0,43):
#            self.plot_ppi(i)
        
    def __str__(self):
        channels_str = ""
        for chan in self.channels:
            channels_str += chan.__str__() + "\n"
        ppi_str = ""
        
        for ppi in self.ppis_header:
            ppi_str += ppi.Description.__str__() + "\n"
            
        return self.Header.__str__() + channels_str + ppi_str

    def plot_ppi(self,index):
        data = self.ppis[index]
        fig = pylab.figure()
            
        ax = pylab.axes(axisbg = 'k', polar=True)
        
        chan    = self.channels[self.ppis_header[index].Description.channel]
        start_range = chan.cell_lenght/2.
        stop_range  = start_range + chan.cell_lenght*chan.number_of_cells
        
        ranges = pylab.linspace(start_range, stop_range, chan.number_of_cells)
        
        start_ang   = self.ppis_header[index].Description.start_az
        stop_ang    = self.ppis_header[index].Description.finish_az
        
        angles = pylab.linspace(start_ang, stop_ang, 
                            self.ppis_header[index].Description.sectorCount)
        
        rad, theta = pylab.meshgrid(ranges/1000., (90-angles)*pylab.pi/180)
        X = theta
        Y = rad 

        ax.pcolormesh(X, Y, data)
        pylab.title('pulse: %s, elev: %.2f, unit: %s' % (chan.pulse, 
                        self.ppis_header[index].Description.angle,
                        self.ppis_header[index].Description.meassurement))
        pylab.savefig('../ppis/ppi_%i.png' % index)
        
    
class VestaFileHeader:
    '''
    classdocs
    '''


    def __init__(self,stream):
        '''
        Constructor
        '''
        params = struct.unpack('20s4H36s',stream[:64])
        self.stamp_Signature        = params[0].decode("utf-8").strip('\x00')
        self.stamp_Version_Minor    = params[1]
        self.stamp_Version_Major    = params[2]
        self.stamp_Version_Build    = params[3]
        self.stamp_Version_Release  = params[4]
        self.stamp_Design           = params[5].decode("utf-8").strip('\x00')
        
        params = struct.unpack('=B2?Bd2I',stream[64:HEADER_SIZE])
        self.Radar          = dRadar[params[0]]
        self.DayLight       = params[1]
        self.Variance       = params[2]
        uct_offset = {True:5, False:4}[self.DayLight]/24.0 # To local time
        self.Obs_datetime   = OLE_TIME_ZERO + timedelta(days=float(params[4]+uct_offset))
        self.ppi_count      = params[5] 
        self.channel_count  = params[6]
            
    def __str__(self):
        return  '-------  Header  ------\n'+\
                'Radar: '+ self.Radar+'\n'+\
                'Date: '+ self.Obs_datetime.__str__()+'\n'+\
                'PPIs: %i'% self.ppi_count+'\n'+\
                'Stamp Design: ' + self.stamp_Design+'\n'+\
                'Channels: %i'% self.channel_count+'\n'
        
class ChannelDesc:
    '''
    classdocs
    '''
    dWaveLength  = {0:'wl3cm', 1:'wl10cm', 2:'wl5cm'}
    dPulseLength = {0:'plLong', 1:'plShort'}

    def __init__(self,stream):
        '''
        Constructor
        '''
        params = struct.unpack('2Bh3I3fI',stream[:CHANNEL_SIZE])  
        self.wave_length        = self.dWaveLength[params[0]] 
        self.pulse              = self.dPulseLength[params[1]]
        self.number_of_cells    = params[3]
        self.cell_lenght        = params[4] # meters
        self.num_of_sectors     = params[5] # radials in 360 deg
        self.beam_width         = params[6] # deg
        self.met_potential      = params[7]
        self.delta_potential    = params[8]
        self.index              = params[9]
        
        
    def __str__(self):
        return  "-------  Channel  ------\n"+\
                'wave_length: '+ self.wave_length+'\n'+\
                'pulse: '+self.pulse+'\n'+\
                'number_of_cells: %i'%self.number_of_cells+'\n'+\
                'cell_lenght: %i'%self.cell_lenght+'\n'+\
                'num_of_sectors: %i'%self.num_of_sectors+'\n'+\
                'beam_width: %.2f'%self.beam_width+'\n'+\
                'met_potential: %.1f'%self.met_potential+'\n'+\
                'delta_potential: %.1f'%self.delta_potential+'\n'+\
                'index: %i'%self.index
        

class Vesta_PPI_Header:
    '''
    classdocs
    '''
    dVestaPackMethod = {0:'pmNone', 1:'pmDAS', 2:'pmZLib'}

    def __init__(self,stream,loc):
        '''
        Constructor
        '''
        self.Description = PPI_Desc(stream,loc)
        params = struct.unpack('BH2I',stream[loc+PPI_DESC_SIZE:loc+
                                            PPI_DESC_SIZE+PPI_HEADER_SIZE])
        self.pack_Method    = self.dVestaPackMethod[params[0]]
        self.packed_Size    = params[2]
        self.unpacked_Size  = params[3]
        

class PPI_Desc:
    '''
    classdocs
    '''
    dPlaneKind = {0:'pkHorizontal', 1:'pkVertical'}
    def __init__(self,stream,loc):
        '''
        Constructor
        '''
        test = stream[loc:loc+PPI_DESC_SIZE]
        params = struct.unpack('=BHBdI2B3HI',test)
        self.Radar          = dRadar[params[0]]
        self.speed          = params[1]
        self.time           = OLE_TIME_ZERO + timedelta(days=float(params[3]))
        self.channel        = params[4]
        self.kind           = self.dPlaneKind[params[5]]
        self.meassurement   = dMeasure[params[6]]
        self.angle          = code2angle_deg(params[7]) # deg
        self.start_az       = code2angle_deg(params[8]) # deg
        self.finish_az      = code2angle_deg(params[9]) # deg
        self.sectorCount    = params[10]
        
    def __str__(self):
        return  "-------  PPI  ------\n"+\
                'Channel: %i'%self.channel +'\n'+\
                'angle: %.2f'% self.angle +'\n'+\
                'Magnitude: '+ self.meassurement +'\n'+\
                'Sectors: %i'%self.sectorCount +'\n'       
        
def code2angle_deg(code): 
    '''
    Converts from 16bits code to angle in deg
    '''      
    return code*360/4096.
        
        