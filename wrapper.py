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
	'on_branch'	: '(?<=On.branch.)\S+',
	'modified'	: '(?<=modified:   )\S+',
	'added'		: '(?<=added:   )\S+',
	'removed'	: '(?<=added:   )\S+',
	'renamed'	: '(?<=renamed:   )\S+',
}

__BRANCH_LIST_TOKENS = {
	'current_branch'	: '(?<=\*\s)\S+',
	'branches'			: '(?:.\S+)\S+'
}

__ERR_USAGE = 1
__ERR_GIT = 2

def cmd(command, **kwargs):
	return subprocess.Popen(command, stdout = subprocess.PIPE, stderr = subprocess.PIPE, **kwargs)

def git_status(git, path):
	pwd = os.getcwdu()
	os.chdir(path)
	proc = cmd([git, 'status'])
	proc.wait()
	os.chdir(pwd)
	
	err = ''.join(proc.stderr.readlines())
	status = {'gitrc' : proc.returncode, 'giterr' : err}
	#init status with git info
	for token in __STATUS_TOKENS: status[token] = []
	#populate arrays
	for line in proc.stdout.readlines():
		for token in __STATUS_TOKENS:
			m = re.search(__STATUS_TOKENS[token], line.strip())
			if m:
				value = m.group(0).strip()
				if value:
					items = status[token]
					items.append(value.strip())
					#status[token] = files
	return status

def git_branch_list(git, path):
	pwd = os.getcwdu()
	os.chdir(path)
	proc = cmd([git, 'branch'])
	proc.wait()
	os.chdir(pwd)
	err = ''.join(proc.stderr.readlines())
	list_dict = {'gitrc' : proc.returncode, 'giterr' : err}
	#init status with git info
	for token in __BRANCH_LIST_TOKENS: list_dict[token] = []
	for line in proc.stdout.readlines():
		for token in __BRANCH_LIST_TOKENS:
			m = re.search(__BRANCH_LIST_TOKENS[token], line.strip())
			if m:
				value = m.group(0).strip()
				if value:
					items = list_dict[token]
					items.append(value.strip())
	return list_dict;

if __name__ == '__main__':
	this_dir = os.path.dirname(os.path.abspath(inspect.getfile( inspect.currentframe())))

	parser = OptionParser()
	parser.add_option("--git", help="path to git binary, default is /opt/local/bin/git")
	parser.add_option("--status", action="store_true", default=False, help="git status <path>")
	parser.add_option("--diff", action="store_true", default=False, help="git diff <path1> <path2>")
	parser.add_option("--branch-list", action="store_true", default=False, help="git branch <path>")
	(options, args) = parser.parse_args()
	
	if not options.git:
		options.git = "/opt/local/bin/git"
	
	sys.stderr.write('request:\n');
	sys.stderr.write(repr(options) + '\n');
	
	if options.status:
		if len(args) < 1:
			sys.stderr.write('--status require an argument of path\n')
			parser.print_help()
			sys.exit(__ERR_USAGE)
			
		status = git_status(options.git, args[0])
		if status:
			sys.stdout.write(json.dumps(status) + '\n')
			sys.exit(0)
		else:
			sys.stderr.write('failed to get status of %s\n' % args[0])
			sys.exit(__ERR_GIT)
	
	elif options.branch_list:
		if len(args) < 1:
			sys.stderr.write('--status require an argument of path\n')
			parser.print_help()
			sys.exit(__ERR_USAGE)
		
		list_dict = git_branch_list(options.git, args[0]);
		if list_dict:
			sys.stdout.write(json.dumps(list_dict) + '\n')
			sys.exit(0)
		else:
			sys.stderr.write('failed to get branch list of %s\n' % args[0])
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