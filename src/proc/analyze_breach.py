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
		f.write('algorithm;specID;spec;successfully falsified rate (SR);time\n')
	
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
			spec = data[spec_idx]
		
			fal = fal + int(data[fal_idx])
			time = (time + float(data[time_idx])) if int(data[fal_idx])==1 else time
#	    numsim = (numsim + int(data[5])) if int(data[2])==1 else numsim
			if status == repeat:
				status = 0
		
				time = (time/fal) if fal != 0 else -1
#		numsim = (numsim/fal) if fal != 0 else -1
				row = 'Breach;'+ specID + ';' + spec + ';'+str(fal)+';'+str(time)#+';'+str(-1) + ';'+str(numsim)
				f.write(row+'\n')
				fal = 0
				time = 0
#		numsim = 0
		

