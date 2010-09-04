//
//  ProjectBuddy.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectBuddy.h"

@implementation ProjectBuddy

@synthesize path, title, parentItem;
@synthesize currentBranch, itemDict;

// Selectors

- (IBAction) remove:(id)sender
{}
- (IBAction) rescan:(id)sender
{}
- (IBAction) commit:(id)sender
{}
- (IBAction) switchToSource:(id)sender
{}
- (IBAction) newSource:(id)sender
{}
- (IBAction) switchToBranch:(id)sender
{}
- (IBAction) newBranch:(id)sender
{}
- (IBAction) resetChanges:(id)sender
{}
- (IBAction) stageChanges:(id)sender
{}
- (IBAction) moveChangesToNewBranch:(id)sender
{}
- (IBAction) showChanges:(id)sender
{}


//	--- Changes Menu Delegate

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	int addedFilesSepIndex = [[[self itemDict] objectForKey:@"modified"] count];
	int removedFilesSepIndex = [[[self itemDict] objectForKey:@"modified"] count] + [[[self itemDict] objectForKey:@"added"] count];

	switch (index) {
		case CNG_MENU_RESET:
			[item setTitle:@"Reset"];
			[item setAction:@selector(resetChanges)];
			[item setTarget:self];
			break;
			
		case CNG_MENU_STAGE:
			[item setTitle:@"Stage"];
			[item setAction:@selector(stageChanges)];
			[item setTarget:self];
			break;
			
		case CNG_MENU_MVBRANCH:
			[item setTitle:@"Move to new branch..."];
			[item setAction:@selector(moveChangesToNewBranch)];
			break;
			
		case CNG_MENU_SEP:
			[menu removeItemAtIndex:CNG_MENU_SEP];
			[menu insertItem:[NSMenuItem separatorItem] atIndex:CNG_MENU_SEP];
			break;
			
			// changeset items
		default:
			if ( index - CNG_MENU_ITEMS == addedFilesSepIndex || index - CNG_MENU_ITEMS == removedFilesSepIndex ) {
				//separator elements
				[menu removeItemAtIndex:(index - CNG_MENU_ITEMS)];
				[menu insertItem:[NSMenuItem separatorItem] atIndex:(index - CNG_MENU_ITEMS)];
				
			}
			else if (index - CNG_MENU_ITEMS < addedFilesSepIndex) {
				//modified files list
				[item setTitle:[[[self itemDict] objectForKey:@"modified"] objectAtIndex:(index - CNG_MENU_ITEMS)]];
				[item setAction:@selector(showChangeSet)];
				[item setTarget:self];
			}
			else if (index - CNG_MENU_ITEMS < removedFilesSepIndex) { 
				//added files list
				[item setTitle:[[[self itemDict] objectForKey:@"added"] objectAtIndex:(index - CNG_MENU_ITEMS)]];
				[item setAction:@selector(showChangeSet)];
				[item setTarget:self];
			}
			else {
				//removed file list
				[item setTitle:[[[self itemDict] objectForKey:@"removed"] objectAtIndex:(index - CNG_MENU_ITEMS)]];
				[item setAction:@selector(showChangeSet)];
				[item setTarget:self];
			}
			break;
	}
	return YES;
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	return CNG_MENU_ITEMS + [self totalChangedFiles];
}

- (int) totalChangedFiles
{
	int total = 0;
	total += [[[self itemDict] valueForKey:@"modified"] count];
	total += [[[self itemDict] valueForKey:@"added"] count];
	total += [[[self itemDict] valueForKey:@"removed"] count];
	total += [[[self itemDict] valueForKey:@"untacked"] count];
	return total;
}

//	---	Git access

- (void) scanChanges
{
	NSDictionary * changes = [wrapper getChanges:[self path]];
	[[self itemDict] setObject:[changes objectForKey:@"modified"] forKey:@"modified"];
	[[self itemDict] setObject:[changes objectForKey:@"added"] forKey:@"added"];
	[[self itemDict] setObject:[changes objectForKey:@"removed"] forKey:@"removed"];
	[[self itemDict] setObject:[changes objectForKey:@"untracked"] forKey:@"untacked"];
	
	[self setCurrentBranch:[[changes objectForKey:@"current_branch"] objectAtIndex:0]];
	[parentItem setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], [self totalChangedFiles]]];
}

- (void) scanRemote
{
	[[self itemDict] setObject:[wrapper getRemote:[self path]] forKey:@"remote"];
}

- (void) scanBranches
{
	[[self itemDict] setObject:[wrapper getBranches:[self path]] forKey:@"branches"];
}

//	--- Initialization

- (id) initBuddy:(NSMenuItem *)anItem forPath:(NSString *)aPath withTitle:(NSString *)aTitle
{
	if ( !(self = [super init])) {
		return nil;
	}
	
	itemDict = [[NSMutableDictionary alloc] init];
	projectMenu = [[NSMenu alloc] init];
	onBranchMenu = [[NSMenu alloc] init]; 
	remoteMenu = [[NSMenu alloc] init];
	changesMenu = [[NSMenu alloc] init];
	wrapper = [[GitWrapper alloc] init];
	
	[self setParentItem:anItem];
	[self setTitle:aTitle];
	[self setPath:aPath];
	
	[self scanRemote];
	[self scanChanges];
	[self scanBranches];
	
	//build project menu
	NSMenuItem *removePath = [[NSMenuItem alloc] initWithTitle:@"Remove path" action:@selector(remove:) keyEquivalent:[NSString string]];
	NSMenuItem *rescanPath = [[NSMenuItem alloc] initWithTitle:@"Rescan path" action:@selector(remove:) keyEquivalent:[NSString string]];
	NSMenuItem *onBranch = [[NSMenuItem alloc] initWithTitle:@"On branch" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *remote = [[NSMenuItem alloc] initWithTitle:@"Remote" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *changes = [[NSMenuItem alloc] initWithTitle:@"Changes" action:nil keyEquivalent:[NSString string]];
	NSMenuItem *commit = [[NSMenuItem alloc] initWithTitle:@"Commit" action:@selector(commit:) keyEquivalent:[NSString string]];
	[projectMenu addItem:removePath];
	[projectMenu addItem:rescanPath];
	[projectMenu addItem:onBranch];
	[projectMenu addItem:remote];
	[projectMenu addItem:changes];
	[projectMenu addItem:commit];
	[anItem setSubmenu:projectMenu];
	
	//build branch menu
	[onBranch setSubmenu:onBranchMenu];
	for(NSString * branch in [[self itemDict] objectForKey:@"branches"]) {
		NSMenuItem *b = [[NSMenuItem alloc] initWithTitle:branch action:@selector(switchToBranch:) keyEquivalent:[NSString string]];
		[onBranchMenu addItem:b];
	}
	NSMenuItem *newBranch = [[NSMenuItem alloc] initWithTitle:@"New Branch..." action:@selector(newBranch:) keyEquivalent:[NSString string]];
	[onBranchMenu addItem:newBranch];
	
	//build remote menu
	[remote setSubmenu:remoteMenu];
	for(NSString * rt in [[self itemDict] objectForKey:@"remote"]) {
		NSMenuItem *r = [[NSMenuItem alloc] initWithTitle:rt action:@selector(switchToSource:) keyEquivalent:[NSString string]];
		[remoteMenu addItem:r];
	}
	NSMenuItem *newSource = [[NSMenuItem alloc] initWithTitle:@"New Source..." action:@selector(newSource:) keyEquivalent:[NSString string]];
	[remoteMenu addItem:newSource];
	
	//changes menu setup
	[changes setSubmenu:changesMenu];
	[changesMenu setDelegate:self];
	
	return self;
}

- (void) dealloc
{
	[title release];
	[path release];
	[currentBranch release];
	[itemDict release];
	[projectMenu release];
	[onBranchMenu release];
	[remoteMenu release];
	[changesMenu release];
	
	[super dealloc];
}


@end
