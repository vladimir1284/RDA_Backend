from Obs_Parser import Obs_Parser
from Digital_Radar_Data import DM_VEL
obs_file = "/home/vladimir/Dicso/Salvas-LAP-ene2017/Documents/Meteorologia/RDA_Backend/RDA_Backend_Py/c10y1030.obs"
a = Obs_Parser(obs_file)

# Export obs info
ofile_name = obs_file+".txt"
ofile = file(ofile_name, "w")
ofile.write(a.__str__())
ofile.close()

