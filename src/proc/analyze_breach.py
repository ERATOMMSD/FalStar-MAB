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
#	numsim = 0
	#f.write(lines[0].strip()+'\n')
		head = 'algorithm;specID;success rate (SR);time\n'
		f.write(head)
		print '--------------------------------------------------------------RESULT\n'
		print head
	
		first_line = lines[0]
		_data = first_line.strip().split(';')
		specID_idx = _data.index('specID')
		spec_idx = _data.index('spec')
		fal_idx = spec_idx + 1
		time_idx = fal_idx + 1

		for line in lines[1:]:
			data = line.strip().split(';')

			status = status + 1
			specID = data[specID_idx]
#			spec = data[spec_idx]
		
			fal = fal + int(data[fal_idx])
			time = (time + float(data[time_idx])) if int(data[fal_idx])==1 else (time + 600)
#	    numsim = (numsim + int(data[5])) if int(data[2])==1 else numsim
			if status == repeat:
				status = 0
		
				time = (time*1.0/repeat)
#		numsim = (numsim/fal) if fal != 0 else -1
				row = 'Breach;'+ specID + ';'+str(fal)+ '/' + _repeat +';'+str(time)#+';'+str(-1) + ';'+str(numsim)
				print row + '\n'
				f.write(row+'\n')
				print '--------------------------------------------------------------------\n'
				fal = 0
				time = 0
#		numsim = 0
		

