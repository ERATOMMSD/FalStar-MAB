import sys

csv = sys.argv[1]
outfile = sys.argv[2]
_repeat = sys.argv[3]
repeat = int(_repeat)

with open(outfile,'w') as f:
	with open(csv, 'r') as tab:
		status = 0
		row = ''
		lines = tab.readlines()
		fal = 0
		time = 0.0
		#numsim = 0
		
		head = 'algorithm;specID;spec;success rate (SR); time\n'
		f.write(head)
		print '-----------------------------------\n'
		print head

		line0 = lines[0].strip().split(';')
		
		algo_idx = line0.index('algorithmset')
		specID_idx = line0.index('specID')
#		spec_idx = line0.index('phi_strset')
		fal_idx = line0.index('falsified')
		time_idx = line0.index('total_time')

		for line in lines[1:]:
			data = line.strip().split(';')
			status = status + 1
			algorithm = 'MAB-UCB' if data[algo_idx] == 'UCB1' else 'MAB-epsilon-greedy'
			specID = data[specID_idx]
#			spec = data[spec_idx]

			valid = (int(data[fal_idx]) == 1) and (float(data[time_idx])<605)
			fal = (fal + 1) if valid else fal
			time = (time + float(data[time_idx])) if valid else time
			#numsim = (numsim + int(data[7])) if valid else numsim
			if status == repeat:
				status = 0
				time = (time/fal) if fal != 0 else -1
				#numsim = (numsim/fal) if fal!=0 else -1
				row = algorithm + ';' +specID + ';' + str(fal) +'/' + _repeat +';'+str(time)#+ ';' + str(numsim)
				f.write(row+'\n')
				print row + '\n'
				fal = 0
				time = 0
				#numsim = 0
		
		

