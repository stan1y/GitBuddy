#!/usr/bin/python
import os
import sys
import logging
import inspect
import subprocess
import json
import re
from optparse import OptionParser

__STATUS_TOKENS = {
	'current_branch' : '(?<=On.branch.)\w+',
	'modified' : '(?<=modified:   )\S+'
}

__ERR_USAGE = 1
__ERR_GIT = 2

def cmd(command, **kwargs):
	return subprocess.Popen(command, stdout = subprocess.PIPE, stderr = subprocess.PIPE, **kwargs)

def get_status(git, path):
	pwd = os.getcwdu()
	os.chdir(path)
	proc = cmd([git, 'status'])
	proc.wait()
	os.chdir(pwd)
	if proc.returncode != 1:
		sys.stderr.write('git status exited with code %d : %s\n' % (proc.returncode, ''.join(proc.stderr.readlines())))
		return None
	else:
		status = { 'path' : [ path ] }
		for line in proc.stdout.readlines():
			for token in __STATUS_TOKENS:
				m = re.search(__STATUS_TOKENS[token], line.strip())
				if m:
					value = m.group(0).strip()
					if value:
						if token in status:
							list_value = status[token]
							list_value.append(value.strip())
						else: 
							list_value = [ value.strip() ]
						status[token] = list_value
		return status
		
if __name__ == '__main__':
	this_dir = os.path.dirname(os.path.abspath(inspect.getfile( inspect.currentframe())))

	parser = OptionParser()
	parser.add_option("--git", help="path to git binary, default is /opt/local/bin/git")
	parser.add_option("--status", action="store_true", default=False, help="git status <path>")
	parser.add_option("--diff", action="store_true", default=False, help="git diff <path1> <path2>")

	(options, args) = parser.parse_args()
	
	if not options.git:
		options.git = "/opt/local/bin/git"
	
	if options.status:
		if len(args) < 1:
			sys.stderr.write('--status require an argument of path\n')
			parser.print_help()
			sys.exit(__ERR_USAGE)
			
		status = get_status(options.git, args[0])
		if status:
			sys.stdout.write(json.dumps(status) + '\n')
			sys.exit(0)
		else:
			sys.stderr.write('failed to get status of %s\n' % args[0])
			sys.exit(__ERR_GIT)
	
	elif options.diff:
		if len(args) < 2:
			sys.stderr.write('--diff requires two path arguments\n')
			parser.print_help()
			sys.exit(__ERR_USAGE)
		pass
		
	else:
		parser.print_help()
		sys.exit(1)