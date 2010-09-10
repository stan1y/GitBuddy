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
	NSDictionary *d = [itemDict copy];
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
		[itemDict setObject:theObject forKey:theKey];
	}
	[itemLock unlock];
	[self updateMenuItems];
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
	[changedSubMenu setPending:YES];
	[stagedSubMenu setPending:YES];
	
	@try {
		NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
		NSLog(@"Quering repo at %@...", path);
		//scan remote, branch and changes
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--branch-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
		}];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--remote-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
		}];
		[wrapper executeGit:[NSArray arrayWithObjects:@"--status", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
			[self mergeData:dict];
			[[self parentItem] setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], [self totalChangeSetItems]]];
			NSLog(@"Project Status Dictionary:\n");
			NSLog(@"%@", [self itemDict]);
			NSLog(@"  ***");
			[changedSubMenu setPending:NO];
			[stagedSubMenu setPending:NO];
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
- (IBAction) push:(id)sender
{}
- (IBAction) pull:(id)sender
{}
- (IBAction) switchToSource:(id)sender
{}
- (IBAction) newSource:(id)sender
{}
- (IBAction) switchToBranch:(id)sender
{}
- (IBAction) newBranch:(id)sender
{}
- (IBAction) commit:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] commit] commitProject:[self itemDict] atPath:path];
	[[(GitBuddy*)[NSApp delegate] commit] showWindow:sender];
}
- (IBAction) showPreview:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] preview] loadPreviewOf:[sender representedObject] inPath:path];
	[[(GitBuddy*)[NSApp delegate] preview] showWindow:sender];
}
- (IBAction) stageSelectedFiles:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] filesStager] setProject:[self itemDict] stageAll:NO];
	[[(GitBuddy*)[NSApp delegate] filesStager] showWindow:sender];
}
- (IBAction) stageAll:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] filesStager] setProject:[self itemDict] stageAll:YES];
	[[(GitBuddy*)[NSApp delegate] filesStager] showWindow:sender];
}
- (IBAction) unstageFile:(id)sender
{
	int rc = NSRunInformationalAlertPanel(@"Config File Unstaging", [NSString stringWithFormat:@"You are about to unstage file %@. Are you sure about it?", [sender representedObject]], @"Yes", @"No", nil);
	if (rc == 1) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
		NSString * unstageArg = [NSString stringWithFormat:@"--unstage=%@", [sender representedObject]];
		[wrapper executeGit:[NSArray arrayWithObjects:unstageArg, repoArg, nil] withCompletionBlock:^(NSDictionary *dict){
			NSLog(@"Unstaging done...");
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
	
	//update branch list
	[branchMenu removeAllItems];
	//new branch
	NSMenuItem *newBranch = [[NSMenuItem alloc] initWithTitle:@"New Branch" action:@selector(newBranch:) keyEquivalent:[NSString string]];
	[newBranch setTarget:self];
	[branchMenu addItem:newBranch];
	//separator
	[branchMenu addItem:[NSMenuItem separatorItem]];
	//branch list
	for(NSString * br in [[self itemDict] objectForKey:@"branches"]) {
		NSMenuItem *b = [[NSMenuItem alloc] initWithTitle:br action:@selector(switchToBranch:) keyEquivalent:[NSString string]];
		[b setTarget:self];
		[branchMenu addItem:b];
	}
	
	//update remote list
	[remoteMenu removeAllItems];
	//new remote
	NSMenuItem *newRemote = [[NSMenuItem alloc] initWithTitle:@"Add Remote Branch" action:@selector(newSource:) keyEquivalent:[NSString string]];
	[newRemote setTarget:self];
	[remoteMenu addItem:newRemote];
	//separator
	[remoteMenu addItem:[NSMenuItem separatorItem]];
	//remote branch list
	for(NSString * rt in [[self itemDict] objectForKey:@"remote"]) {
		NSMenuItem *r = [[NSMenuItem alloc] initWithTitle:rt action:@selector(switchToSource:) keyEquivalent:[NSString string]];
		[r setTarget:self];
		[remoteMenu addItem:r];
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
	
	//branch menu
	branchMenu = [[NSMenu alloc] init];
	branch = [[NSMenuItem alloc] initWithTitle:@"Branch" action:nil keyEquivalent:[NSString string]];
	[branch setSubmenu:branchMenu];
	[parentMenu addItem:branch];
	
	//remote menu
	remoteMenu = [[NSMenu alloc] init];
	remote = [[NSMenuItem alloc] initWithTitle:@"Remote" action:nil keyEquivalent:[NSString string]];
	[remote setSubmenu:remoteMenu];
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
