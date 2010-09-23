//
//  ProjectBuddy.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectBuddy.h"
#import "GitWrapper.h"
#import "GitBuddy.h"

@implementation ProjectBuddy

@synthesize path, title, parentItem;
@synthesize currentBranch;


// Dictionary management

- (NSDictionary*) itemDict
{
	[itemLock lock];
	NSDictionary *d = [[[NSMutableDictionary alloc] initWithDictionary:itemDict copyItems:YES] autorelease];
	[itemLock unlock];
	return d;
	
}

- (void) mergeData:(NSDictionary *)dict
{
	[itemLock lock];
	NSEnumerator* e = [dict keyEnumerator];
	id theKey = nil;
	while((theKey = [e nextObject]) != nil)
	{
		id theObject = [dict objectForKey:theKey];
		[theObject retain];
		[itemDict setObject:theObject forKey:theKey];
	}
	
	[itemLock unlock];
}

- (NSString*) getSourceForBranch:(NSString*)branchName
{
	for (NSString *rbranch in [[self itemDict] objectForKey:@"rbranch"]) {
		if ([rbranch hasSuffix:branchName]) {
			NSRange r = [rbranch rangeOfString:@"/"];
			NSString *source = [rbranch substringToIndex:r.location];
			return source;
		}
	}
	return nil;
}
					

// Selectors

- (IBAction) remove:(id)sender
{
	if (NSRunInformationalAlertPanel(@"Confirm repo removal", [NSString stringWithFormat:@"You are about to delete Git repo %@ from tracking. Are you sure?", [self path]], @"Remove repo", @"Cancel", nil) == 1) {
		[[parentItem menu] removeItem:parentItem];
		[self release]; 
	}
}

- (void) rescanWithCompletionBlock:(void (^)(void))codeBlock
{
	@try {
		NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
		NSLog(@"Quering repo at %@...", path);
		//scan remote, branch and changes
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--branch-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
			[self setCurrentBranch:[[[[self itemDict] objectForKey:@"branches"] objectForKey:@"current_branch"] objectAtIndex:0]];
			NSLog(@"Current branch is %@", [self currentBranch]);
			[dict release];
		}];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--remote-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
			[dict release];
		}];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--remote-branch-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
			[dict release];
		}];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--status", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
			[dict release];

			NSLog(@"Project Status Dictionary:\n");
			NSLog(@"%@", [self itemDict]);
			NSLog(@"  ***");
			
			[self updateMenuItems];
			[parentMenu update];
			
			//set counter for project
			[ (GitBuddy*)[NSApp delegate] setCounter:[self totalChangeSetItems] forProject:path];
			
			//call user code block
			codeBlock();
		}];
	}
	@catch (NSException * e) {
		NSLog(@"---------Exception----------");
		NSLog(@"%@", e);
		NSLog(@"----------------------------");
		
		[[NSApplication sharedApplication] presentError:[NSError errorWithDomain:@"GitBuddy failed to scan Git repo" code:-1 userInfo:[e userInfo]]];
	}
}

- (IBAction) rescan:(id)sender
{
	[self rescanWithCompletionBlock: ^{}];
}

- (void) pushToNamedSource:(NSString*)source
{
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
	NSString * pushArg = [NSString stringWithFormat:@"--push=%@", source];
	NSString * branchArg = [NSString stringWithFormat:@"--branch=%@", [self currentBranch]];
	
	int pushTimeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"gitPushTimeout"];
	NSLog(@"Pushing changes with timeout %d seconds", pushTimeout);
	
	//show operation panel
	[ (GitBuddy*)[NSApp delegate] startOperation:[NSString stringWithFormat:@"Pushing commits in branch %@ to %@. It may take a while, please wait...", [self currentBranch], source]];
	
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, pushArg, branchArg, nil] timeoutAfter:pushTimeout withCompletionBlock:^ (NSDictionary *dict){

		[ (GitBuddy*)[NSApp delegate] finishOperation];
		
		if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
			NSRunInformationalAlertPanel(@"Push operation complete.", [NSString stringWithFormat:@"Your commits to branch %@ were successfully pushed to %@", [self currentBranch], source] , @"All right", nil, nil);
		}
		[dict release];
	}];
}

- (IBAction) push:(id)sender
{
	NSString *targetRemoteSource = [self getSourceForBranch:[self currentBranch]];
	if ( !targetRemoteSource) {
		NSRunAlertPanel(@"No destination known.", [NSString stringWithFormat:@"The branch %@ does not have it's remote counterpart to push too. You need to add a remote source with target branch", [self currentBranch]], @"Ok", nil, nil);
		return;
	}
	
	[self pushToNamedSource:targetRemoteSource];
}
- (IBAction) pull:(id)sender
{
	NSString *targetRemoteSource = [self getSourceForBranch:[self currentBranch]];
	if ( !targetRemoteSource) {
		NSRunAlertPanel(@"No destination known.", [NSString stringWithFormat:@"The branch %@ does not have it's remote counterpart to pull from. You need to add a remote source with target branch.", [self currentBranch]], @"Ok", nil, nil);
		return;
	}
	
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
	NSString * pullArg = [NSString stringWithFormat:@"--pull=%@", targetRemoteSource];
	NSString * branchArg = [NSString stringWithFormat:@"--branch=%@", [self currentBranch]];
	
	int pullTimeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"gitPullTimeout"];
	NSLog(@"Pulling changes with timeout %d seconds", pullTimeout);
	
	//show operation panel
	[ (GitBuddy*)[NSApp delegate] startOperation:[NSString stringWithFormat:@"Pulling changes in branch %@ from %@. It may take a while, please wait...", [self currentBranch], targetRemoteSource]];
	
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, pullArg, branchArg, nil] timeoutAfter:pullTimeout withCompletionBlock:^ (NSDictionary *dict){

		[ (GitBuddy*)[NSApp delegate] finishOperation];
		
		if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
			NSRunInformationalAlertPanel(@"Pull operation complete.", [NSString stringWithFormat:@"Changed in branch %@ were successfully pulled from %@", [self currentBranch], targetRemoteSource] , @"All right", nil, nil);
		}
		[dict release];
	}];
}
- (IBAction) pushToSource:(id)sender
{
	NSString *source = [sender representedObject];
	int rc = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Push %@ to %@", [self currentBranch], source], [NSString stringWithFormat:@"You are about to push your commits in branch %@ to remote source %@. Are you sure about it?", [self currentBranch], source], @"Yes", @"No", nil);
	
	if (rc == 1) {
		[self pushToNamedSource:source];
	}
}

- (IBAction) newSource:(id)sender
{
	[ (GitBuddy*)[NSApp delegate] createRemoteFor:self];
}
- (IBAction) switchToBranch:(id)sender
{
	NSString *b = [sender representedObject];
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
	NSString * switchArg = [NSString stringWithFormat:@"--branch-switch=%@", b];
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, switchArg, nil] withCompletionBlock:^(NSDictionary *dict){
		
		[dict release];
		[self setCurrentBranch:b];
		NSLog(@"Switched to branch %@", b);
	}];
}
- (IBAction) newBranch:(id)sender
{
	[ (GitBuddy*)[NSApp delegate] createBranchFor:self];
}
- (IBAction) commitsLog:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] commitsLog] initForProject:path];
	[[(GitBuddy*)[NSApp delegate] commitsLog] showWindow:sender];
}
- (IBAction) commit:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[(GitBuddy*)[NSApp delegate] commit] commitProject:[self itemDict] atPath:path];
	[[(GitBuddy*)[NSApp delegate] commit] showWindow:sender];
}
- (IBAction) showPreview:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[(GitBuddy*)[NSApp delegate] preview] loadPreviewOf:[sender representedObject] inPath:path];
	[[(GitBuddy*)[NSApp delegate] preview] showWindow:sender];
}
- (IBAction) stageSelectedFiles:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[(GitBuddy*)[NSApp delegate] filesStager] setProject:[self itemDict] stageAll:NO];
	[[(GitBuddy*)[NSApp delegate] filesStager] showWindow:sender];
}
- (IBAction) stageAll:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[(GitBuddy*)[NSApp delegate] filesStager] setProject:[self itemDict] stageAll:YES];
	[[(GitBuddy*)[NSApp delegate] filesStager] showWindow:sender];
}
- (IBAction) unstageFile:(id)sender
{
	int rc = NSRunInformationalAlertPanel(@"Confirmation required.", [NSString stringWithFormat:@"You are about to unstage file %@. Are you sure about it?", [sender representedObject]], @"Yes", @"No", nil);
	if (rc == 1) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
		NSString * unstageArg = [NSString stringWithFormat:@"--unstage=%@", [sender representedObject]];
		[wrapper executeGit:[NSArray arrayWithObjects:unstageArg, repoArg, nil] withCompletionBlock:^(NSDictionary *dict){
			[dict release];
			NSLog(@"Unstaging done...");
		}];
	}
	 
}
- (IBAction) setActive:(id)sender
{
	[(GitBuddy*)[NSApp delegate] setActiveProjectByPath:[self path]];
	[self updateMenuItems];
}
- (IBAction) addFile:(id)sender
{
	int rc = NSRunInformationalAlertPanel(@"Confirmation required.", [NSString stringWithFormat:@"You are about to add file %@ to repo. Are you sure about it?", [sender representedObject]], @"Yes", @"No", nil);
	if (rc == 1) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
		NSString * stageArg = [NSString stringWithFormat:@"--stage=%@", [sender representedObject]];
		[wrapper executeGit:[NSArray arrayWithObjects:stageArg, repoArg, nil] withCompletionBlock:^(NSDictionary *dict){
			[dict release];
			NSLog(@"Adding file done...");
		}];
	}
}

- (int) totalChangeSetItems
{
	return [changedSubMenu totalNumberOfFiles] + [stagedSubMenu totalNumberOfFiles];
}

- (void) updateMenuItems
{
	//update dynamic menus
	[changedSubMenu setData:[[self itemDict] objectForKey:@"unstaged"]];
	[stagedSubMenu setData:[[self itemDict] objectForKey:@"staged"]];
	[untrackedSubMenu setData:[[self itemDict] objectForKey:@"untracked"]];
	[branchSubMenu setData:[[self itemDict] objectForKey:@"branches"]];
	[remoteSubMenu setData:[[self itemDict] objectForKey:@"sources"]];
	
	//set current branch
	if ([self currentBranch]) {
		[branchSubMenu setCheckedItems:[NSArray arrayWithObject:[self currentBranch]]];
	}
	
	//set number of modified and staged files
	if ([changedSubMenu totalNumberOfFiles]) {
		[changed setTitle:[NSString stringWithFormat:@"Changed (%d)", [changedSubMenu totalNumberOfFiles] ]];
	}
	else {
		[changed setTitle:@"Changed"];	
	}
	if ([stagedSubMenu totalNumberOfFiles]) {
		[staged setTitle:[NSString stringWithFormat:@"Staged (%d)", [stagedSubMenu totalNumberOfFiles] ]];
	}
	else {
		[staged setTitle:@"Staged"];
	}
	
	//set number of untracjed files
	if ([untrackedSubMenu totalNumberOfFiles]) {
		[untracked setTitle:[NSString stringWithFormat:@"Untracked (%d)", [untrackedSubMenu totalNumberOfFiles] ]];
	}
	else {
		[untracked setTitle:@"Untracked"];
	}
	
	//set parent item
	if ([self totalChangeSetItems]) {
		[[self parentItem] setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], [self totalChangeSetItems]]];
	}
	else {
		[[self parentItem] setTitle:[self title]];
	}
	
	//disable "Set Active" if already active
	if ([[self parentItem] state] == YES) {
		[activate setTitle:@"Active Project"];
		[activate setAction:nil];
		[activate setTarget:nil];
	}
	else {
		[activate setTitle:@"Set Active"];
		[activate setAction:@selector(setActive:)];
		[activate setTarget:self];
	}
}

//	--- Initialization ---

- (id) initBuddy:(NSMenuItem *)anItem forPath:(NSString *)aPath withTitle:(NSString *)aTitle
{
	if ( !(self = [super init])) {
		return nil;
	}
	
	//project properties
	itemDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:aPath, @"path", aTitle, @"title", nil];
	itemLock = [[NSLock alloc] init];
	[self setTitle:aTitle];
	[self setPath:aPath];
		
	//set parent menu
	[self setParentItem:anItem];
	parentMenu = [[NSMenu alloc] init];
	[parentItem setSubmenu:parentMenu];
	
	//activate menu item
	activate = [[NSMenuItem alloc] initWithTitle:@"Set Active" action:nil keyEquivalent:[NSString string]];
	[activate setAction:@selector(setActive:)];
	[activate setTarget:self];
	[parentMenu addItem:activate];
	
	//branch menu
	branchMenu = [[NSMenu alloc] init];
	branchSubMenu = [[ProjectSubMenu alloc] initProject:aPath withDict:[[self itemDict] objectForKey:@"branches"] forMenu:branchMenu];
	branch = [[NSMenuItem alloc] initWithTitle:@"Branch" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *newBranch = [[NSMenuItem alloc] initWithTitle:@"New Branch" action:@selector(newBranch:) keyEquivalent:[NSString string]];
	[newBranch setTarget:self];
	[branchSubMenu setInitialItems:[NSArray arrayWithObjects:newBranch, [NSMenuItem separatorItem], nil]];
	[branchSubMenu setItemSelector:@selector(switchToBranch:) target:self];
	[branch setSubmenu:branchMenu];
	[branchMenu setDelegate:branchSubMenu];
	[parentMenu addItem:branch];
	
	//remote menu
	remoteMenu = [[NSMenu alloc] init];
	remoteSubMenu = [[ProjectSubMenu alloc] initProject:aPath withDict:[[self itemDict] objectForKey:@"sources"] forMenu:remoteMenu];
	remote = [[NSMenuItem alloc] initWithTitle:@"Remote" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *newRemote = [[NSMenuItem alloc] initWithTitle:@"Add Source" action:@selector(newSource:) keyEquivalent:[NSString string]];
	[newRemote setTarget:self];
	[remoteSubMenu setInitialItems:[NSArray arrayWithObjects:newRemote, [NSMenuItem separatorItem], nil]];
	[remoteSubMenu setItemSelector:@selector(pushToSource:) target:self];
	[remote setSubmenu:remoteMenu];
	[remoteMenu setDelegate:remoteSubMenu];
	[parentMenu addItem:remote];
	
	//changed menu
	changedMenu = [[NSMenu alloc] init];
	changedSubMenu = [[ProjectSubMenu alloc] initProject:aPath withDict:[[self itemDict] objectForKey:@"unstaged"] forMenu:changedMenu];
	changed = [[NSMenuItem alloc] initWithTitle:@"Changed" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *stageAll = [[NSMenuItem alloc] initWithTitle:@"Stage Files" action:@selector(stageSelectedFiles:) keyEquivalent:[NSString string]];
	[stageAll setTarget:self];
	NSMenuItem *stageSelected = [[NSMenuItem alloc] initWithTitle:@"Stage All Files" action:@selector(stageAll:) keyEquivalent:[NSString string]];
	[stageSelected setTarget:self];
	[changedSubMenu setInitialItems:[NSArray arrayWithObjects:stageAll, stageSelected, [NSMenuItem separatorItem], nil]];
	[changedSubMenu setItemSelector:@selector(showPreview:) target:self];
	[changed setSubmenu:changedMenu];
	[changedMenu setDelegate:changedSubMenu];
	[parentMenu addItem:changed];
	
	//staged
	stagedMenu = [[NSMenu alloc] init];
	stagedSubMenu = [[ProjectSubMenu alloc] initProject:aPath withDict:[[self itemDict] objectForKey:@"staged"] forMenu:stagedMenu];
	staged = [[NSMenuItem alloc] initWithTitle:@"Staged" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *commit = [[NSMenuItem alloc] initWithTitle:@"Commit" action:@selector(commit:) keyEquivalent:[NSString string]];
	[commit setTarget:self];
	NSMenuItem *unStageAll = [[NSMenuItem alloc] initWithTitle:@"Unstage All" action:nil keyEquivalent:[NSString string]];
	[unStageAll setTarget:self];
	[stagedSubMenu setInitialItems:[NSArray arrayWithObjects: commit, unStageAll, [NSMenuItem separatorItem], nil]];
	[stagedSubMenu setItemSelector:@selector(unstageFile:) target:self];
	[staged setSubmenu:stagedMenu];
	[stagedMenu setDelegate:stagedSubMenu];
	[parentMenu addItem:staged];
	
	//untracked
	untrackedMenu = [[NSMenu alloc] init];
	untrackedSubMenu = [[ProjectSubMenu alloc] initProject:aPath withDict:[[self itemDict] objectForKey:@"untracked"] forMenu:untrackedMenu];
	untracked = [[NSMenuItem alloc] initWithTitle:@"Untracked" action:nil keyEquivalent:[NSString string]];
	[untrackedSubMenu setInitialItems:[NSArray array]];
	[untrackedSubMenu setItemSelector:@selector(addFile:) target:self];
	[untracked setSubmenu:untrackedMenu];
	[untrackedMenu setDelegate:untrackedSubMenu];
	[parentMenu addItem:untracked];
	
	//commits log
	commitsLog = [[NSMenuItem alloc] initWithTitle:@"Commits Log" action:@selector(commitsLog:) keyEquivalent:[NSString string]];
	[commitsLog setTarget:self];
	[parentMenu addItem:commitsLog];
	
	//push
	push = [[NSMenuItem alloc] initWithTitle:@"Push" action:@selector(push:) keyEquivalent:[NSString string]];
	[push setTarget:self];
	[parentMenu addItem:push];
	
	//pull
	pull = [[NSMenuItem alloc] initWithTitle:@"Pull" action:@selector(pull:) keyEquivalent:[NSString string]];
	[pull setTarget:self];
	[parentMenu	addItem:pull];
	
	//rescan
	rescan = [[NSMenuItem alloc] initWithTitle:@"Rescan" action:@selector(rescan:) keyEquivalent:[NSString string]];
	[rescan setTarget:self];
	[parentMenu addItem:rescan];
	
	//remote repo
	remove = [[NSMenuItem alloc] initWithTitle:@"Remove Repo" action:@selector(remove:) keyEquivalent:[NSString string]];
	[remove setTarget:self];
	[parentMenu addItem:remove];
	
	return self;
}

- (void) dealloc
{
	[itemLock release];
	[title release];
	[path release];
	[currentBranch release];
	[itemDict release];
	[branchMenu release];
	[parentMenu release];
	[remoteMenu release];
	[changedMenu release];
	[stagedMenu release];
	[selectedChanges release];
	
	[super dealloc];
}


@end
