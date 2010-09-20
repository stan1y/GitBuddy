#!/usr/bin/python
import os
import sys
import logging
import inspect
import subprocess
import json
import re
import time
from optparse import OptionParser

__debug = False

def log(msg):
	global __debug
	if __debug:
		print 'DEBUG {%s}\n' % msg

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
	'branch'			: '(?:.\S+)\S+'
}

__REMOTE_LIST_TOKENS = {
	'source'			: '(?:.\S+)\S+'
}

__REMOTE_BRANCH_TOKENS = {
	'rbranch'			: '(?:.\S+)\S+'
}

__LS_FILES_INDEX = {
	'keys'		: '(?:\s\S*)\s',
	'files'		: '(?:\t\S*)$'
}

__LOG_TOKENS = {
	'author'	: '(?<=Author: )\w+'
}

__ERR_USAGE = -1

def b_cmd(git, repo, command, gitspec = True):
	repo = os.path.abspath(repo)
	
	while True:
		if os.path.exists(os.path.join(repo, '.git', 'index.lock')):
			log('index is locked, waiting...')
			time.sleep(1)
		else:
			log('index is not locked')
			break
	
	if gitspec:
		cmdline = [git, '--work-tree=%s' % repo, '--git-dir=%s' % os.path.join(repo, '.git')]
	else:
		cmdline = [git]
		
	cmdline += command
	log('cmd %s' % ' '.join(command))
	proc = subprocess.Popen(cmdline, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
	stdout = []
	stderr = []
	log('waiting for git...')
	while proc.returncode == None:
		stdout += proc.stdout.readlines()
		stderr += proc.stderr.readlines()
		proc.poll()
	return proc.returncode, stdout, stderr

def b_cmd_chdir(git, repo, command, gitspec = True):
	pwd = os.getcwdu()
	log('chdir to %s' % repo)
	os.chdir(repo)
	rc, err, out = b_cmd(git, repo, command, gitspec)
	os.chdir(pwd)
	log('chdir to %s' % pwd)
	return rc, err, out

def b_cmd_lines(git, repo, command):
	rc, out, err = b_cmd_chdir(git, repo, command)
	status = {'gitrc' : rc, 'giterr' : err, 'lines' : []}
	count = 0
	for line in out:
		status['lines'].append(line.strip())
		count += 1
	status['count'] = count
	return status
	
def b_cmd_json(git, repo, command, tokens):
	rc, out, err = b_cmd_chdir(git, repo, command)
	status = {'gitrc' : rc, 'giterr' : err}
	#init status with git info
	for token in tokens: status[token] = []
	#populate arrays
	count = 0
	for line in out:
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
	rc, out, err = b_cmd_chdir(git, repo, command)
	#init status with git info
	status = {'gitrc' : rc, 'giterr' : err}

	#add group dicts
	for grp in token_groups:
		status[grp] = {'count' : 0}
		for token in token_groups[grp][1]:
			status[grp][token] = []
	
	#populate arrays
	current_group = None
	for line in out:
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
	
	parser.add_option("--debug", action="store_true", default=False, help="Enable debug outout, not valid json output.")
	parser.add_option("--repo", help="path to git repository")
	parser.add_option("--git", help="path to git binary, default is /opt/local/bin/git")
	parser.add_option("--status", action="store_true", default=False, help="git status")
	
	parser.add_option("--branch-list", action="store_true", default=False, help="git branch")
	parser.add_option("--branch-rm", help="git branch -d [name]")
	parser.add_option("--branch-add", help="git branch [name]")
	parser.add_option("--branch-switch", help="git checkout [name]")
	
	parser.add_option("--remote-branch-list", action="store_true", default=False, help="git branch -r")
	parser.add_option("--remote-list", action="store_true", default=False, help="git remote")
	parser.add_option("--remote-add", help="git remote add [name] [url]")
	parser.add_option("--remote-rm", help="git remote rm [name]")
	parser.add_option("--url", help="A URL for remote source, used in --remote-add")
	
	parser.add_option("--staged-index", action="store_true", default=False, help="git ls-files -s")
	
	parser.add_option("--cached-diff", help="git diff --cached [path]")
	parser.add_option("--diff", help="git diff [path]")
	
	parser.add_option("--stage", help="git stage [path]")
	parser.add_option("--unstage", help="git reset HEAD [path]")
	
	parser.add_option("--commit", help="git commit -m [message]")
	parser.add_option("--reset", help="git checkout [path]")
	
	parser.add_option("--clone", help="git clone [url]\n --repo is used to specify PARENT folder of new repo.")
	
	parser.add_option("--push", help="git push [remote] [branch]. Branch must specified with --branch=[name].")
	parser.add_option("--pull", help="git pull [remote] [branch]. Branch must specified with --branch=[name].")
	parser.add_option("--branch", help="Specify branch name for --push & --pull.")
	
	parser.add_option("--log", help="git log [branch name]")
	
	(options, args) = parser.parse_args()

	if not options.repo:
		options.repo = "."
	
	if not options.git:
		options.git = "/opt/local/bin/git"
	
	if options.debug:
		__debug = True
		log('input %s' % repr(options));
		
	
	if options.status:
		obj = b_cmd_json_parts(options.git, options.repo, ['status'], {
			'staged'	: [ 'Changes to be committed', __STATUS_TOKENS ],
			'unstaged'	: [ 'Changed but not updated', __STATUS_TOKENS ],
			'untracked'	: [ 'Untracked files', __UNTRACKED_STATUS ]
		})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.branch_list:
		obj = b_cmd_json_parts(options.git, options.repo, ['branch'], {
			'branches'	: ['',	__BRANCH_LIST_TOKENS]
		})
		#there is one item "current_branch" which
		#should not affect total items count
		obj['branches']['count'] -= 1
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
		
	elif options.branch_switch:
		obj = b_cmd_json(options.git, options.repo, ['checkout', options.branch_switch], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.remote_branch_list:
		obj = b_cmd_json(options.git, options.repo, ['branch', '-r'], __REMOTE_BRANCH_TOKENS)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
	
	elif options.remote_list:
		obj = b_cmd_json_parts(options.git, options.repo, ['remote'], {
			'sources'	: ['',	__REMOTE_LIST_TOKENS]
		})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.remote_add:
		if not options.url:
			parser.print_help()
			sys.stderr.write('--url is required argument\n')
			sys.exit(__ERR_USAGE)
		
		obj = b_cmd_json(options.git, options.repo, ['remote', 'add', options.remote_add, options.url], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.remote_rm:
		obj = b_cmd_json(options.git, options.repo, ['remote', 'rm', options.remote_rm], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.staged_index:
		obj = b_cmd_json(options.git, options.repo, ['ls-files', '-s'], __LS_FILES_INDEX)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.diff:
		obj = b_cmd_lines(options.git, options.repo, ['diff', options.diff])
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.cached_diff:
		obj = b_cmd_lines(options.git, options.repo, ['diff', '--cached', options.cached_diff])
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
		
	elif options.reset:
		obj = b_cmd_json(options.git, options.repo, ['checkout', options.reset], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.push:
		if not options.branch:
			parser.print_help()
			sys.stderr.write('--branch is required argument\n')
			sys.exit(__ERR_USAGE)
			
		obj = b_cmd_json(options.git, options.repo, ['push', options.push, options.branch], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.pull:
		if not options.branch:
			parser.print_help()
			sys.stderr.write('--branch is required argument\n')
			sys.exit(__ERR_USAGE)
			
		obj = b_cmd_json(options.git, options.repo, ['pull', options.pull, options.branch], {})
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	elif options.clone:
		rc, out, err = b_cmd_chdir(options.git, options.repo, ['clone', options.clone], gitspec = False);
		sys.stdout.write(json.dumps({ 'gitrc' : rc, 'giterr' : err}))
		sys.exit(rc)
		
	elif options.log:
		obj = b_cmd_json(options.git, options.repo, ['log', options.log], __LOG_TOKENS)
		sys.stdout.write('%s\n' % json.dumps(obj))
		sys.exit(obj['gitrc'])
		
	else:
		parser.print_help()
		sys.exit(0)