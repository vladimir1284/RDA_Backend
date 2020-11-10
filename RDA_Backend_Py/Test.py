from RDA_TCPServer import RDA_TCPServer
from VCP_Data import VCP_Data
from xml.dom import minidom

#a = VCP_Data(111, minidom.parse('RDA_Backend.vcp.xml'))
#a.create_VCP_Msg()

servidor = RDA_TCPServer()

servidor.doExecute()