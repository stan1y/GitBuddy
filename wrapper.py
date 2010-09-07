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
	'added'		: '(?<=new.file:   )\S+',
	'removed'	: '(?<=deleted:   )\S+',
	'renamed'	: '(?<=renamed:   )\S+',
}

__BRANCH_LIST_TOKENS = {
	'current_branch'	: '(?<=\*\s)\S+',
	'branches'			: '(?:.\S+)\S+'
}

__ERR_USAGE = -1

def cmd(command, **kwargs):
	return subprocess.Popen(command, stdout = subprocess.PIPE, stderr = subprocess.PIPE, **kwargs)
	
def b_cmd_chdir(git, repo, command):
	command.insert(0, git)
	pwd = os.getcwdu()
	os.chdir(repo)
	proc = cmd(command)
	proc.wait()
	os.chdir(pwd)
	return proc
	
def b_cmd_json(git, repo, command, tokens):
	proc = b_cmd_chdir(git, repo, command)
	err = ''.join(proc.stderr.readlines())
	status = {'gitrc' : proc.returncode, 'giterr' : err}
	#init status with git info
	for token in tokens: status[token] = []
	#populate arrays
	for line in proc.stdout.readlines():
		for token in tokens:
			m = re.search(tokens[token], line.strip())
			if m:
				value = m.group(0).strip()
				if value:
					items = status[token]
					items.append(value.strip())
	return status

if __name__ == '__main__':
	this_dir = os.path.dirname(os.path.abspath(inspect.getfile( inspect.currentframe())))

	parser = OptionParser()
	
	parser.add_option("--debug-request", action="store_true", default=False, help="print json view of request")
	parser.add_option("--repo", help="path to git repository")
	parser.add_option("--git", help="path to git binary, default is /opt/local/bin/git")
	parser.add_option("--status", action="store_true", default=False, help="git status")
	parser.add_option("--branch-list", action="store_true", default=False, help="git branch")
	parser.add_option("--branch-rm", help="git branch [name]")
	parser.add_option("--branch-add", help="git branch -d [name]")
	parser.add_option("--remote-list", action="store_true", default=False, help="git branch -r")
	(options, args) = parser.parse_args()
	
	if not options.repo:
		sys.stderr.write('--repo is required argument\n')
		parser.print_help()
		sys.exit(__ERR_USAGE)
	
	if not options.git:
		options.git = "/opt/local/bin/git"
	
	if options.debug_request:
		sys.stderr.write('request: %s\n' % repr(options));
	
	if options.status:
		obj = b_cmd_json(options.git, options.repo, ['status'], __STATUS_TOKENS)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.branch_list:
		obj = b_cmd_json(options.git, options.repo, ['branch'], __BRANCH_LIST_TOKENS)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
			
	elif options.branch_rm:
		obj = b_cmd_json(options.git, options.repo, ['branch', '-d', options.branch_rm], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.branch_add:
		obj = b_cmd_json(options.git, options.repo, ['branch', options.branch_add], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.remote_list:
		obj = b_cmd_json(options.git, options.repo, ['branch', '-r'], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	else:
		parser.print_help()
		sys.exit(1)