#!/usr/bin/env python2.7
import os
from datetime import datetime
import re
import sys



algo_dict = {'Breach':'Breach','MAB_e':'Epsi','MAB_u':'UCB1'}

def generate_config(conf_name, mdl, input_name, input_range, sp, phi_str, cp, tspan, repeat, param, al):
	algo = algo_dict[al]
	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Generating configurations'+'\n'
	input_num = str(len(input_name.split('\n')))
	with open(conf_name, 'w') as conf_w:
		if al == 'Breach':	
			conf_w.write('model 1\n')
			conf_w.write(mdl + '\n')
			conf_w.write('input_name '+input_num+'\n')
			conf_w.write(input_name + '\n')
			conf_w.write('input_range '+input_num + '\n')
			conf_w.write(input_range + '\n')
			conf_w.write('optimization 1\n')
			conf_w.write('cmaes\n')
			conf_w.write('phi 1\n')
			conf_w.write(sp + ' ' + phi_str+'\n')
			conf_w.write('controlpoints 1\n')
			conf_w.write(cp + '\n')
			conf_w.write('timespan 1\n')
			conf_w.write(tspan + '\n')
			conf_w.write('timeout 1\n')
			conf_w.write('600\n') #breach timeout
			conf_w.write('trials 1\n')
			conf_w.write(repeat +'\n')
			
			if not (param == ''):
				param_num = str(len(param.split('\n')))
				conf_w.write('parameters ' + param_num + '\n')
				conf_w.write(param)
		else:
			conf_w.write('model 1\n')
			conf_w.write(mdl + '\n')
			conf_w.write('algorithm 1\n')
			conf_w.write(algo + '\n')
			conf_w.write('input_name '+input_num + '\n')
			conf_w.write(input_name+ '\n')
			conf_w.write('input_range ' + input_num + '\n')
			conf_w.write(input_range + '\n')
			phi_type = 'and' if 'and' in phi_str else 'or'
			conf_w.write('phi_type 1\n')
			conf_w.write(phi_type + '\n')
			conf_w.write('phi 1\n')
			conf_w.write(sp + ' ' + phi_str + '\n')
			conf_w.write('controlpoints 1\n')
			conf_w.write(cp + '\n')
			conf_w.write('scalar 1\n')
			conf_w.write('0.2\n')
			conf_w.write('trials 1\n')
			conf_w.write(repeat + '\n')
			conf_w.write('budget 1\n')
			conf_w.write('60 3\n')
			conf_w.write('tspan 1\n')
			conf_w.write(tspan + '\n')
			if not (param == ''):
				param_num = str(len(param.split('\n')))
				conf_w.write('parameters ' + param_num  + '\n')
				conf_w.write(param)
	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Done!'+'\n'

def extract_repeating(conf_name):
	with open(conf_name, 'r') as conf:
		lines = conf.readlines()
		for line in lines:
			if 'trials' in line:
				r = lines[lines.index(line)+1].strip()
				return r
	return '0'
	
def extract_algo(conf_name):
	with open(conf_name, 'r') as conf:
		lines = conf.readlines()
		for line in lines:
			if ('UCB1' in line):
				return 'MAB_u'
			elif ('Epsi' in line):
				return 'MAB_e'
	return 'Breach'



def run_script(conf_name, script_name, tmpresult_name, result_name):
	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Generating scripts' + '\n'
	repeating = extract_repeating(conf_name)
	al = extract_algo(conf_name)
	if al == 'Breach':
		os.system('python src/test/breach_test.py ' + conf_name + ' ' + script_name)
	else:
		os.system('python src/test/gen_stltest.py ' + conf_name + ' ' + script_name)
	os.system('chmod 744 ' + script_name)
	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Done!'+'\n'


	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Running scripts' + '\n'
		
	os.system(script_name + ' ' + tmpresult_name)
	os.system('rm *.slxc')
	os.system('rm *.dat')
	os.system('rm *.mat')
	os.system('rm -rf slprj/')
	print '\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Done!'+'\n'

	print '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Processing results'+ '\n'	
            
	if al == 'Breach':
		os.system('python src/proc/analyze_breach.py ' + tmpresult_name + ' ' + result_name + ' ' + repeating)
	else:
		os.system('python src/proc/analyze_pa.py ' + tmpresult_name + ' ' + result_name + ' ' + repeating)
	


def check_spec(l):
	pass_check = True
	for i in l:
		_i = i.split('_')
		if len(_i)<2:
			pass_check = False
		else:
			__i = _i[1].split('^')
			if not spec_dict.has_key(_i[0]):
				pass_check = False
				break
			if len(__i) == 1:
				if _i[0] == 'AT5':
					if not re.match(r'[1-8]', __i[0]):
						pass_check = False
				elif _i[0] == 'AT7':
					if not re.match(r'[1-7]', __i[0]):
						pass_check = False
				else:
					if not re.match(r'[1-5]', __i[0]):
						pass_check = False

			else:
			
				if _i[0] == 'AT1':
					if not re.match(r'[1-5]', __i[0]):
						pass_check = False
					if not re.match(r'[-2|0|1|3]', __i[1]):
						pass_check = False
				elif _i[0] == 'AT5':
					if not re.match(r'[4-8]', __i[0]):
						pass_check = False
					if not re.match(r'[-2|0|1|3]', __i[1]):
						pass_check = False
				else:
					if not re.match(r'[1-5]', __i[0]):
						pass_check = False
					if not re.match(r'[0|1|2|3]', __i[1]):
						pass_check = False
			
	return pass_check

def check_algorithm(l):
	pass_check = False
	for i in l:
		if i =='Breach' or i == 'MAB_e' or i == 'MAB_u':
			pass_check = True
	return pass_check

def check_repeat(r):
	if r.strip().isdigit():
		return True
	else:
		return False

def display_result(rp):
	filenames = os.listdir(rp)
	i = 1
#	print '************************************************************RESULT '+str(i) + '\n'
	for filename in filenames:
		if '.csv' in filename:
			print '************************************************************RESULT '+str(i) + '\n'
			with open(rp + '/' + filename, 'r') as res:
				lines = res.readlines()
				for line in lines:
					print line + '\n'
			print '********************************************************************'
		i = i + 1

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
#phi_type_dict={'AT1':'or','AT2':'or','AT3':'or','AT4':'or','AT5':'and','AT6':'or','AT7':'or','AFC1':'or','AFC2':'or','NN1':'or','NN2':'or'}
tspan_dict = {'AT':'0:.01:30','AFC':'0:.01:50','NN':'0:.01:20'}
#scalar = 0.2
#budget = [60 3]
parameter_dict = {\
	'AT':'',
	'AFC':'fuel_inj_tol=1.0;\nMAF_sensor_tol=1.0;\nAF_sensor_tol=1.0;\npump_tol=1;\nkappa_tol=1;\ntau_ww_tol=1;\nfault_time=50;\nkp=0.04;\nki=0.14;',
	'NN':'u_ts=0.001;'}
#param_num_dict = {'AT':0, 'AFC':9, 'NN':1}
#algo_dict = {'MAB_e':'Epsi','MAB_u':'UCB1'}

scale_dict = {'0':'', '1':'_10', '2':'_100', '3':'_1000', '-2':'_001'}
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


print ('-------------------------Welcome to FalStar-------------------------')
print ('*                                                                  *')
print ('*                                                                  *')
print ('*                                                April 2019        *')
print ('--------------------------------------------------------------------')

speclist = ''
_speclist = []
__speclist = []


#read arguments from the commandline
if len(sys.argv) == 2:
	if sys.argv[1] == 'new': #branch 1
		print '--------------------------------------------------------------------\n'
		print 'Please make sure to put the model in src/model/\n'
		print '--------------------------------------------------------------------\n'
		mdl = raw_input('Please input the name of the model:\n')
		input_n = raw_input('Please input the names of input signals. Use \';\' if multiple:\nE.g., \'throttle;brake\'\n')
		input_r = raw_input('Please input the ranges of each input signals.\nThe format is \'lb ub\', and use \';\' if multiple:\nE.g., 0 100;0 300\n')
		param = raw_input('Please input the parameters of the model if applicable.\nThe format is \'p1=a\', a is a natural number. Use \';\' if multiple:\n')
		sp = raw_input('Please input the specification ID:\n')
		phi_str = raw_input('Please input the specification in STL.Refer to [Donze CAV\'10]:\n')
		
		sim_time = raw_input('Please input the total time of simulation:\n')
		cp = raw_input('Please input the number of control points:\n')

		algo = raw_input('Please specify the algorithm.\nCandidates are Breach, MAB_u, and MAB_e.\n')
		
		repeating = raw_input('Please input the number of trials:\n')
		
		sys_time = datetime.now().strftime("%Y%m%d%H%M%S")
		config_path = 'test/config/' + sys_time
		script_path = 'test/script/' + sys_time
		tmpresult_path = 'test/result_tmp/' + sys_time
		result_path = 'result/' + sys_time

		os.mkdir(config_path)
		os.mkdir(script_path)
		os.mkdir(tmpresult_path)
		os.mkdir(result_path)


		_instance_name = sp  + '-' + algo + '-' + repeating
		conf_name = config_path + '/' + _instance_name + '.config'
		script_name = script_path + '/' + _instance_name
		tmpresult_name = tmpresult_path + '/' + _instance_name + '.csv'
		result_name = result_path + '/' + _instance_name + '.csv'

		input_name = '\n'.join(input_n.split(';'))
		input_range = '\n'.join(input_r.split(';'))
		tspan = '0:.01:' + sim_time
		_parameters = param.strip().replace(' ', '').split(';')
		parameters = ';\n'.join(_parameters) + ';'
#		algorithm  = algo_dict[algo]
		
		generate_config(conf_name, mdl, input_name, input_range, sp, phi_str, cp, tspan, repeating, parameters, algo)
		run_script(conf_name, script_name, tmpresult_name, result_name)
		

	elif sys.argv[1] == 'exec': #branch 2
		print '--------------------------------------------------------------------\n'
		conf_name = raw_input('Please input the name of configuration file:\n')
		_pathbase = conf_name.split('/')
		pathbase = '/'.join(_pathbase[0:-1]) + '/'
		
	
		__filebase = _pathbase[-1]
		_filebase = __filebase.split('.')
		filebase = _filebase[0]

		script_path = pathbase.replace('config', 'script')
		if not os.path.isdir(script_path):
			os.makedirs(script_path)
		script_name = script_path + filebase

		tmpresult_path = pathbase.replace('config', 'result_tmp')
		if not os.path.isdir(tmpresult_path):
			os.makedirs(tmpresult_path)
		tmpresult_name = tmpresult_path + filebase + '.csv'
		
		_result_path = pathbase.replace('test/', '')
		result_path = _result_path.replace('config','result')
		if not os.path.isdir(result_path):
			os.makedirs(result_path)
		result_name = result_path + filebase + '.csv'


		run_script(conf_name, script_name, tmpresult_name, result_name)
	

##############################################################################
else: #main branch: no argument
	while True:
		print '-------------------------------Step 1-------------------------------'
		speclist = raw_input('Please input the Spec ID. Use \';\' if checking multiple specs.\nSee examples below: \nAT1_1\nAT1_1^-2\nAT1_1;AT1_2\n--------------------------------------------------------------------\n')

		_speclist = speclist.strip().split(';')
		__speclist = [_s.strip() for _s in _speclist]
		if check_spec(__speclist):
			print '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Done!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
			break
		else:
			print 'The format is wrong, please input again.\n'


	while True:
		print '-------------------------------Step 2-------------------------------'
		algorithm = raw_input('Please input the solver. Use \';\' if checking multiple solvers.\nCandidates are 3 solvers, namely,\nBreach\nMAB_e\nMAB_u\n--------------------------------------------------------------------\n')
		_algorithm = algorithm.strip().split(';')
		__algorithm = [_a.strip() for _a in _algorithm]
		if check_algorithm(__algorithm):
			print '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Done!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
			break
		else:
			print 'The format is wrong, please input again.\n'


    #repeating = '30'
	while True:
		print '-------------------------------Step 3-------------------------------'
		repeating = raw_input('Please input the number of trials.\n--------------------------------------------------------------------\n')
		if check_repeat(repeating):
			print '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Done!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
			break
		else:
			print 'The format is wrong, please input again.\n'

#	print '>>>>>>>>>>>>>>>>>>>>Please wait for the results>>>>>>>>>>>>>>>>>>>>>'
	print '                                                                    '
	print '                                                                    '

	sys_time = datetime.now().strftime("%Y%m%d%H%M%S")
	config_path = 'test/config/' + sys_time
	script_path = 'test/script/' + sys_time
	tmpresult_path = 'test/result_tmp/' + sys_time
	result_path = 'result/' + sys_time

	os.mkdir(config_path)
	os.mkdir(script_path)
	os.mkdir(tmpresult_path)
	os.mkdir(result_path)

	for sp in __speclist:
		for al in __algorithm:
    #mkdir, name is like just system time, and generate one config file for each configuration.
			_instance_name = sp  + '-' + al + '-' + repeating
			conf_name = config_path + '/' + _instance_name + '.config'
			script_name = script_path + '/' + _instance_name
			tmpresult_name = tmpresult_path + '/' + _instance_name + '.csv'
			result_name = result_path + '/' + _instance_name + '.csv'


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


			input_num = input_num_dict[mdl_abbr]
			input_name = input_name_dict[mdl_abbr]
			input_range = input_range_dict[mdl_abbr]
            
			cp = cp_dict[mdl_abbr]
			tspan = tspan_dict[mdl_abbr]

			scale = ''
			if len(sp_suf_arg) == 2:
				scale = sp_suf_arg[1] #e.g., 10 if there is.
				mdl = mdl  + scale_dict[scale]
				phi_str = phi_temp.replace('#', str(float(_phi_arg)*(10**(int(scale)))))

			param = parameter_dict[mdl_abbr]
    
			generate_config(conf_name, mdl, input_name, input_range, sp, phi_str, cp, tspan, repeating, param, al)

			run_script(conf_name, script_name, tmpresult_name, result_name)
			
	display_result(result_path)
