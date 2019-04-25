import sys

model = ''
algorithm = ''
phi_str = []
controlpoints = ''
budget = []
#budget_unit = []
scalar = []
parameters = []
#budget_pre = ''
tspan = ''
loadfile = ''
phi_type = ''

input_name = []
input_range = []

addpath = []
trials = ''
status = 0


with open(sys.argv[1], 'r') as conf:
	for line in conf.readlines():
		argu = line.strip().split()
		if status == 0:
			status = 1
			arg = argu[0]
			print arg
			linenum = int(argu[1])
		elif status == 1:
			linenum = linenum - 1
			if arg == 'model':
				model = argu[0]
			elif arg == 'phi':
				complete_phi = argu[0] + ';' + argu[1]
				for a in argu[2:]:
					complete_phi = complete_phi + ' ' + a
				phi_str.append(complete_phi)
			elif arg == 'controlpoints':
				controlpoints = argu[0]
			elif arg == 'scalar':
				scalar.append(argu[0])
			elif arg == 'budget':
				budget.append(argu)
#			elif arg == 'budget_unit':
#				budget_unit.append(argu[0])
			elif arg == 'input_name':
				input_name.append(argu[0])
			elif arg == 'input_range':
				input_range.append([float(argu[0]), float(argu[1])])
			elif arg == 'addpath':
				addpath.append(argu[0])
			elif arg == 'parameters':
				parameters.append(argu[0])
			elif arg == 'trials':
				trials = argu[0]
			elif arg == 'phi_type':
				phi_type = argu[0]
			elif arg == 'algorithm':
				algorithm = argu[0]
#	    elif arg == 'budget_pre':
#		budget_pre = argu[0]
			elif arg == 'tspan':
				tspan = argu[0]
			elif arg == 'loadfile':
				loadfile = argu[0]
			else:
				continue
			if linenum == 0:
				status = 0

for ph in phi_str:
	for c in scalar:
		for bd in budget:
			#print bd[0]

			
			property = ph.split(';')
			filename = model + '_' + algorithm + '_' + property[0] + '_'+ str(c) + '_' + str(bd[0])+'_'+ str(bd[1])
			with open('../benchmarks/' + filename, 'w')	as bm:
				bm.write('#!/bin/sh\n')
				bm.write('csv=$1\n')
				bm.write('matlab -nodesktop -nosplash <<EOF\n')
				bm.write('clear;\n')
				for ap in addpath:
					bm.write('addpath(genpath(\'' + ap + '\'));\n')
	       
				for para in parameters:
					bm.write(para+'\n')
				bm.write('InitBreach;\n\n')
				if loadfile!='':
					bm.write('load ' + loadfile + '\n')
				bm.write('mdl = \''+ model + '\';\n')
				bm.write('Br = MyBreachSimulinkSystem(mdl);\n')
				bm.write('Br.Sys.tspan = ' + tspan + ';\n')
				bm.write('phi_type = \''+ phi_type +'\';\n')
				bm.write('phi_str = \'' + property[1] + '\';\n')
				bm.write('phi = STL_Formula(\'phi1\',phi_str);\n')
				bm.write('budget = ' + bd[0] + ';\n')
				bm.write('budget_unit = ' + bd[1] + ';\n')
				bm.write('scalar = ' + c + ';\n')
#		bm.write('budget_pre = '+ budget_pre + ';\n')
				bm.write('algorithm = \''+ algorithm + '\';\n\n')
				bm.write('input_gen.type = \'UniStep\';\n')
				bm.write('input_gen.cp = ' + str(controlpoints) + ';\n')
				bm.write('Br.SetInputGen(input_gen);\n')
				bm.write('for cpi = 0:input_gen.cp-1\n')
				for i in range(len(input_name)):
					bm.write('\t' + input_name[i] + '_sig = strcat(\'' + input_name[i] + '_u\', num2str(cpi));\n')
					bm.write('\tBr.SetParamRanges({' + input_name[i] + '_sig},[' + str(input_range[i][0]) + ' ' + str(input_range[i][1]) + ']);\n')
				bm.write('end\n')
		
				bm.write('total_time = [];\n')
				bm.write('falsified = [];\n')
#		bm.write('best_rob1 = [];\n')
#		bm.write('best_rob2 = [];\n')
				bm.write('numsim = [];\n')
				bm.write('trials = ' + trials + ';\n')
				bm.write('for i = 1: trials\n')
				bm.write('\t tic\n')
		
				if algorithm == 'UCB1':
					bm.write('\t fp = UCB1Falsification_2(Br, phi, budget, budget_unit, scalar, phi_type);\n')
				else:
					bm.write('\t fp = EpsilonGreedyFalsification(Br, phi, budget, budget_unit, scalar, phi_type);\n')
				bm.write('\t fp.solve();\n')
				bm.write('\t tt = toc;\n')
				bm.write('\t falsified = [falsified;fp.falsified];\n')
				bm.write('\t total_time = [total_time; tt];\n')
#		bm.write('\t best_rob1 = [best_rob1; fp.rob1];\n')
#		bm.write('\t best_rob2 = [best_rob2; fp.rob2];\n')
				bm.write('\t numsim = [numsim; fp.num_sim];\n')
				bm.write('end\n')
				bm.write('phi_strset = {phi_str')
				for j in range(1, int(trials)):
					bm.write(';phi_str')
				bm.write('};\n')
		
				bm.write('algorithmset = {algorithm')
				for j in range(1, int(trials)):
					bm.write(';algorithm')
				bm.write('};\n')
				bm.write('scalarset = scalar*ones(trials, 1);\n')
				bm.write('budgetset = budget*ones(trials, 1);\n')
				bm.write('budget_unitset = budget_unit*ones(trials, 1);\n')	
	
				bm.write('result = table(phi_strset, algorithmset, scalarset, budgetset, budget_unitset, falsified, total_time, numsim);\n')
				bm.write('writetable(result, \'$csv\', \'Delimiter\', \';\');\n')
				bm.write('quit\n')
				bm.write('EOF\n')

		
