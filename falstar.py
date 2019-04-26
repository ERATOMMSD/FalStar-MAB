#!/usr/bin/env python2.7
import os
from datetime import datetime

spec_dict = {\
	'AT1':'alw_[0,30]((gear[t] == 3 => speed[t] > #))',
	'AT2':'alw_[0,30]((gear[t] == 4 => speed[t] > #))',
	'AT3':'alw_[0,30]((not (gear[t] == 4)) or RPM[t]> #)',
	'AT4':'alw_[0,30-#](RPM[t+10]-RPM[t]>2000 => gear[t+#]-gear[t]>0)',
	'AT5':'alw_[0,30](speed[t]<# and RPM[t] < 4780)',
	'AT6':'alw_[0,26](speed[t+4]-speed[t]># => gear[t+4]-gear[t]>0)',
	'AT7':'alw_[0,30-#](speed[t+2]-speed[t]>30 => gear[t+#]-gear[t]>0)',
	'AFC1':'alw_[11,50]((controller_mode[t] == 0) => (mu[t]<#))',
	'AFC2':'alw_[11,50]((controller_mode[t] == 1) => (mu[t]<#))',
	'NN1':'alw_[0, 18]((not (abs(Pos[t] - Ref[t]) <= #+ 0.04*abs(Ref[t])))=> ev_[0, 2] (alw_[0, 1] (abs(Pos[t] - Ref[t]) <= #+ 0.04*abs(Ref[t]))))',
	'NN2':'alw_[0, 18]((not (abs(Pos[t] - Ref[t]) <= #+ 0.03*abs(Ref[t])))=> ev_[0, 2] (alw_[0, 1] (abs(Pos[t] - Ref[t]) <= #+ 0.03*abs(Ref[t]))))'}
model_dict = {'AT':'Autotrans_shift', 'AFC':'fuel_control', 'NN':'narmamaglev_v1'}
cp_dict = {'AT':'5','AFC':'5','NN':'3'}
input_range_dict = {'AT':'0 100\n0 325','AFC':'8.8 90\n900 1100','NN':'1 3'}
input_name_dict = {'AT':'throttle\nbrake','AFC':'Pedal_Angle\nEngine_Speed','NN':'Ref'}
input_num_dict = {'AT':'2', 'AFC':'2', 'NN':'1'}
phi_type_dict={'AT1':'or','AT2':'or','AT3':'or','AT4':'or','AT5':'and','AT6':'or','AT7':'or','AFC1':'or','AFC2':'or','NN1':'or','NN2':'or'}
tspan_dict = {'AT':'0:.01:30','AFC':'0:.01:50','NN':'0:.01:20'}
#scalar = 0.2
#budget = [60 3]
parameter_dict = {\
	'AT':'',
	'AFC':'fuel_inj_tol=1.0;\nMAF_sensor_tol=1.0;\nAF_sensor_tol=1.0;\npump_tol=1;\nkappa_tol=1;\ntau_ww_tol=1;\nfault_time=50;\nkp=0.04;\nki=0.14;',
	'NN':'u_ts=0.001;'}
param_num_dict = {'AT':0, 'AFC':9, 'NN':1}
algo_dict = {'MAB_e':'Epsi','MAB_u':'UCB1'}

scale_dict = {'0':'', '1':'10', '2':'100', '3':'1000', '-2':'001'}
AT1_argset = ['20.6', '20.4', '20.2', '20', '19.8']
AT2_argset = ['43','41','39','37','35']
AT3_argset = ['700', '800', '900', '1000', '1100']
AT4_argset = ['15', '16', '17', '18', '19']
AT5_argset = ['130', '131', '132', '133', '134', '135', '136', '137']
AT6_argset = ['20','25','30','35','40']
AT7_argset = ['2','3','4','5','6','7','8']
AFC1_argset = ['0.16', '0.17', '0.18', '0.19', '0.2']
AFC2_argset = ['0.222', '0.224', '0.226', '0.228', '0.23']
NN1_argset = ['0.001', '0.002', '0.003', '0.004', '0.005']
NN2_argset = ['0.001', '0.002', '0.003', '0.004', '0.005']


print ('-----------------------------------------Welcome-----------------------------------------------')
print ('*                                                                                             *')
print ('*                                                    Z. Zhang, I. Hasuo, P. Arcaini           *')
print ('*                                                                        April 2019           *')
print ('-----------------------------------------------------------------------------------------------')


speclist = raw_input('Please input the specification ID, use \';\' if more than 1 spec.\nSee examples below. \nAT1_1\nAT1_1^-2\nAT1_1;AT1_2\n---------------------------------\n')

_speclist = speclist.strip().split(';')
__speclist = [_s.strip() for _s in _speclist]

#check_speclist()

algorithm = raw_input('Please input the algorithm;use \';\' if more than 1 algorithm.\nThere are 3 algorithms in total, namely,\nBreach\nMAB_e\nMAB_u\n---------------------------------\n')


_algorithm = algorithm.strip().split(';')
__algorithm = [_a.strip() for _a in _algorithm]
#check_algorithm()

repeating = raw_input('Please input repeating times; default value is 30\n---------------------------------\n')


config_path = 'test/config/'+datetime.now().strftime("%Y%m%d%H%M%S")
os.mkdir(config_path)
for sp in __speclist:
	for al in __algorithm:
#mkdir, name is like just system time, and generate one config file for each configuration.

		conf_name = config_path + '/' + sp  + '-' + al + '-' + repeating + '.config'
		_sp = sp.split('_') #e.g., ['AT1','2']; ['AT1','2^10']
		

		sp_id = _sp[0] #e.g., 'AT1'
		sp_suf = _sp[1] #e.g., '2' or '2^10'
		mdl_abbr = _sp[0][0:-1] #e.g., 'AT'
		mdl = model_dict[mdl_abbr] #e.g., 'Autotrans_shift'

		sp_suf_arg = sp_suf.split('^') #e.g., ['2'] or ['2','10']
		sp_id_arg = sp_suf_arg[0] #e.g., '2'
		

		phi_temp = spec_dict[sp_id]
		spec_set = eval(sp_id + '_argset')
		_phi_arg = spec_set[int(sp_id_arg)-1]
		phi_str = phi_temp.replace('#', _phi_arg)
		
		scale = ''
		if len(sp_suf_arg) == 2:
			scale = sp_suf_arg[1] #e.g., 10 if there is.
			mdl = mdl + '_' + scale_dict[scale]
			phi_str = phi_temp.replace('#', str(float(_phi_arg)*(10**(int(scale)))))
		
		with open(conf_name, 'w') as conf_w:
			if al == 'Breach':	
				conf_w.write('model 1\n')
				conf_w.write(mdl + '\n')
				conf_w.write('input_name '+input_num_dict[mdl_abbr]+'\n')
				conf_w.write(input_name_dict[mdl_abbr]+'\n')
				conf_w.write('input_range '+input_num_dict[mdl_abbr]+'\n')
				conf_w.write(input_range_dict[mdl_abbr]+'\n')
				conf_w.write('optimization 1\n')
				conf_w.write('cmaes\n')
				conf_w.write('phi 1\n')
				conf_w.write(sp + ' ' + phi_str+'\n')
				conf_w.write('controlpoints 1\n')
				conf_w.write(cp_dict[mdl_abbr] + '\n')
				conf_w.write('timespan 1\n')
				conf_w.write(tspan_dict[mdl_abbr]+ '\n')
				conf_w.write('timeout 1\n')
				conf_w.write('600\n') #breach timeout
				conf_w.write('trials 1\n')
				conf_w.write(repeating+'\n')
				if not (param_num_dict[mdl_abbr] == 0):
					conf_w.write('parameters ' + str(param_num_dict[mdl_abbr]) + '\n')
					conf_w.write(parameter_dict[mdl_abbr])
			else:
				conf_w.write('model 1\n')
				conf_w.write(mdl + '\n')
				conf_w.write('algorithm 1\n')
				conf_w.write(algo_dict[al] + '\n')
				conf_w.write('input_name '+input_num_dict[mdl_abbr] + '\n')
				conf_w.write(input_name_dict[mdl_abbr]+ '\n')
				conf_w.write('input_range ' + input_num_dict[mdl_abbr] + '\n')
				conf_w.write(input_range_dict[mdl_abbr] + '\n')
				conf_w.write('phi_type 1\n')
				conf_w.write(phi_type_dict[sp_id] + '\n')
				conf_w.write('phi 1\n')
				conf_w.write(sp + ' ' + phi_str + '\n')
				conf_w.write('controlpoints 1\n')
				conf_w.write(cp_dict[mdl_abbr] + '\n')
				conf_w.write('scalar 1\n')
				conf_w.write('0.2\n')
				conf_w.write('trials 1\n')
				conf_w.write(repeating + '\n')
				conf_w.write('budget 1\n')
				conf_w.write('60 3\n')
				conf_w.write('tspan 1\n')
				conf_w.write(tspan_dict[mdl_abbr] + '\n')
				if not (param_num_dict[mdl_abbr] == 0):
					conf_w.write('parameters ' + str(param_num_dict[mdl_abbr]) + '\n')
					conf_w.write(parameter_dict[mdl_abbr])




	
