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
	'modified'	: '(?<=modified:...)\S+',
	'added'		: '(?<=new.file:...)\S+',
	'removed'	: '(?<=deleted:...)\S+',
	'renamed'	: '(?<=renamed:...)\S+',
}

__UNTRACKED_STATUS = {
	'files'		: '(?:\t\S*)$'
}

__BRANCH_LIST_TOKENS = {
	'current_branch'	: '(?<=\*\s)\S+',
	'branches'			: '(?:.\S+)\S+'
}

__REMOTE_LIST_TOKENS = {
	'remote'			: '(?:.\S+)\S+'
}

__LS_FILES_INDEX = {
	'keys'		: '(?:\s\S*)\s',
	'files'		: '(?:\t\S*)$'
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
	
def b_cmd_lines(git, repo, command):
	proc = b_cmd_chdir(git, repo, command)
	err = ''.join(proc.stderr.readlines())
	status = {'gitrc' : proc.returncode, 'giterr' : err, 'lines' : []}
	count = 0
	for line in proc.stdout.readlines():
		status['lines'].append(line.strip())
		count += 1
	status['count'] = count
	return status
	
def b_cmd_json(git, repo, command, tokens):
	proc = b_cmd_chdir(git, repo, command)
	err = ''.join(proc.stderr.readlines())
	status = {'gitrc' : proc.returncode, 'giterr' : err}
	#init status with git info
	for token in tokens: status[token] = []
	#populate arrays
	count = 0
	for line in proc.stdout.readlines():
		for token in tokens:
			m = re.search(tokens[token], line.strip())
			if m:
				value = m.group(0).strip()
				if value:
					items = status[token]
					count += 1
					items.append(value.strip())
	status["count"] = count
	return status
	
def b_cmd_json_parts(git, repo, command, token_groups):
	proc = b_cmd_chdir(git, repo, command)
	err = ''.join(proc.stderr.readlines())
	#init status with git info
	status = {'gitrc' : proc.returncode, 'giterr' : err}

	#add group dicts
	for grp in token_groups:
		status[grp] = {'count' : 0}
		for token in token_groups[grp][1]:
			status[grp][token] = []
	
	#populate arrays
	current_group = None
	for line in proc.stdout.readlines():
		#is token header
		for grp in token_groups:
			if token_groups[grp][0] in line: 
				current_group = grp
				break
				
		#check line with token in current group
		if current_group:
			tokens = token_groups[current_group][1]
			for token in tokens:
				m = re.search(tokens[token], line.strip())
				if m:
					value = m.group(0).strip()
					if value:
						items = status[current_group][token]
						items.append(value.strip())
						status[current_group]['count'] += 1 
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
	parser.add_option("--staged-index", action="store_true", default=False, help="git ls-files -s")
	parser.add_option("--show", help="git show [key]")
	parser.add_option("--diff", help="git diff [path]")
	parser.add_option("--stage", help="git stage [path]")
	parser.add_option("--unstage", help="git reset HEAD [path]")
	parser.add_option("--commit", help="git commit -m [message]")
	parser.add_option("--clone", help="git clone [url]. --repo is used to specify PARENT folder of new repo.")
	
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
		obj = b_cmd_json_parts(options.git, options.repo, ['status'], {
			'staged'	: [ 'Changes to be committed', __STATUS_TOKENS ],
			'unstaged'	: [ 'Changed but not updated', __STATUS_TOKENS ],
			'untracked'	: [ 'Untracked files', __UNTRACKED_STATUS ]
		})
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
		obj = b_cmd_json(options.git, options.repo, ['branch', '-r'], __REMOTE_LIST_TOKENS)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.staged_index:
		obj = b_cmd_json(options.git, options.repo, ['ls-files', '-s'], __LS_FILES_INDEX)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.show:
		obj = b_cmd_lines(options.git, options.repo, ['show', options.show])
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.diff:
		obj = b_cmd_lines(options.git, options.repo, ['diff', options.diff])
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.stage:
		args = ['stage', '--']
		[args.append(part) for part in options.stage.split(',') ]
		obj = b_cmd_json(options.git, options.repo, args, {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.unstage:
		args = ['reset', 'HEAD', '--']
		[args.append(part) for part in options.unstage.split(',') ]
		obj = b_cmd_json(options.git, options.repo, args, {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.commit:
		obj = b_cmd_json(options.git, options.repo, ['commit', '-m', '%s' % options.commit], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.clone:
		obj = b_cmd_json(options.git, options.repo, ['clone', options.clone], {});
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	else:
		parser.print_help()
		sys.exit(1)