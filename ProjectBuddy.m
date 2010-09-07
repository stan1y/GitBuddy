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

// Dictionary management

- (void) mergeData:(NSDictionary *)dict
{
	@synchronized (self) {
		NSEnumerator* e = [dict keyEnumerator];
		id theKey = nil;
		while((theKey = [e nextObject]) != nil)
		{
			id theObject = [dict objectForKey:theKey];
			[[self itemDict] setObject:theObject forKey:theKey];
		}
		
		[self rebuildMenu];
	}
}
					

// Selectors

- (IBAction) removePath:(id)sender
{
	if (NSRunInformationalAlertPanel(@"Confirm repo removal", [NSString stringWithFormat:@"You are about to delete Git repo %@ from tracking. Are you sure?", [self path]], @"Remove repo", @"Cancel", nil) == 1) {
		[[parentItem menu] removeItem:parentItem];
		[self release];
	}
}

- (IBAction) rescan:(id)sender
{
	if ([wrapperLock tryLock]) {
		@try {
			NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", path];
			NSLog(@"Quering repo at %@...", path);
			//scan remote, branches and changes
			[wrapper executeGit:[NSArray arrayWithObjects:@"--branch-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
				[self mergeData:dict];
			}];
			[wrapper executeGit:[NSArray arrayWithObjects:@"--remote-list", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
				[self mergeData:dict];
			}];
			[wrapper executeGit:[NSArray arrayWithObjects:@"--status", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
				[self mergeData:dict];
				[[self parentItem] setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], [self totalChangedFiles]]];
				NSLog(@"Status:\n");
				NSLog(@"%@", [self itemDict]);
				NSLog(@"  ***");
			}];
		}
		@catch (NSException * e) {
			NSLog(@"---------Exception----------");
			NSLog(@"%@", e);
			NSLog(@"----------------------------");
			
			[[NSApplication sharedApplication] presentError:[NSError errorWithDomain:@"GitBuddy failed to scan Git repo" code:-1 userInfo:[e userInfo]]];
		}
		@finally {
			[wrapperLock unlock];
		}
	}
	else {
		NSLog(@"Project busy processing another event...");
	}

}
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
{
	ChangeSetViewer * viewer = [ChangeSetViewer viewModified:@"/dev/null" diffTo:[[self path] stringByAppendingPathComponent:[sender representedObject]]];
	[[[NSApp delegate] queue] addOperation:viewer];
	[viewer release];
}

//	--- Changes Menu Delegate

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	NSArray *modified = [[self itemDict] objectForKey:@"modified"];
	NSArray *added = [[self itemDict] objectForKey:@"added"];
	NSArray *removed = [[self itemDict] objectForKey:@"removed"];
	NSArray *renamed = [[self itemDict] objectForKey:@"renamed"];
	NSLog(@"updating menu: %d, %d, %d, %d", [modified count], [added count], [removed count], [renamed count]);
	NSString *itemPath = @"";
	
	switch (index) {
		case CNG_MENU_RESET:
			[item setTitle:@"Reset"];
			[item setAction:@selector(resetChanges:)];
			[item setTarget:self];
			break;
			
		case CNG_MENU_STAGE:
			[item setTitle:@"Stage"];
			[item setAction:@selector(stageChanges:)];
			[item setTarget:self];
			break;
			
		case CNG_MENU_MVBRANCH:
			[item setTitle:@"Move to new branch..."];
			[item setAction:@selector(moveChangesToNewBranch:)];
			[item setTarget:self];
			break;
			
		case CNG_MENU_SEP:
			[menu removeItemAtIndex:CNG_MENU_SEP];
			[menu insertItem:[NSMenuItem separatorItem] atIndex:CNG_MENU_SEP];
			break;
			
			// changeset items
		default:
			if ([modified count] && index - CNG_MENU_ITEMS < [modified count]) {
				//modified files list
				itemPath = [[[self itemDict] objectForKey:@"modified"] objectAtIndex:(index - CNG_MENU_ITEMS)];
				[item setTitle:[NSString stringWithFormat:@"%@ (changed)", itemPath]];
				[item setAction:@selector(showChanges:)];
				[item setTarget:self];
			}
			if ([added count] && index - CNG_MENU_ITEMS >= [modified count]) { 
				//added files list
				itemPath = [[[self itemDict] objectForKey:@"added"] objectAtIndex:(index - CNG_MENU_ITEMS  - [modified count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (added)", itemPath]];
				[item setAction:@selector(showChanges:)];
				[item setTarget:self];
			}
			if ([removed count] && index - CNG_MENU_ITEMS >= [modified count] + [added count]) { 
				//removed files list
				itemPath = [[[self itemDict] objectForKey:@"removed"] objectAtIndex:(index - CNG_MENU_ITEMS  - [modified count] - [added count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (removed)", itemPath]];
				[item setAction:@selector(showChanges:)];
				[item setTarget:self];
			}
			if ([renamed count] && index - CNG_MENU_ITEMS >= [modified count] + [added count] + [removed count]) { 
				//renamed files list
				itemPath = [[[self itemDict] objectForKey:@"renamed"] objectAtIndex:(index - CNG_MENU_ITEMS  - [modified count] - [added count] - [removed count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (renamed)", itemPath]];
				[item setAction:@selector(showChanges:)];
				[item setTarget:self];
			}
			[item setRepresentedObject:itemPath];
			NSLog(@"changeset item at index %d : %@", index - CNG_MENU_ITEMS, item);
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
	return [[[self itemDict] objectForKey:@"modified"] count] + [[[self itemDict] objectForKey:@"added"] count] + [[[self itemDict] objectForKey:@"removed"] count] + [[[self itemDict] objectForKey:@"renamed"] count];
}

//	--- Menu building ---

- (void) rebuildMenu
{
	NSLog(@"Rebuilding menu for %@...", title);
	@try {
		//crear
		[projectMenu removeAllItems];
		[onBranchMenu removeAllItems];
		[remoteMenu removeAllItems];
		[changesMenu removeAllItems];
		
		//build project menu
		NSMenuItem *removePath = [[NSMenuItem alloc] initWithTitle:@"Remove path" action:@selector(removePath:) keyEquivalent:[NSString string]];
		[removePath setTarget:self];
		NSMenuItem *rescanPath = [[NSMenuItem alloc] initWithTitle:@"Rescan path" action:@selector(rescan:) keyEquivalent:[NSString string]];
		[rescanPath setTarget:self];
		NSMenuItem *onBranch = [[NSMenuItem alloc] initWithTitle:@"On branch" action:nil keyEquivalent:[NSString string]];
		NSMenuItem *remote = [[NSMenuItem alloc] initWithTitle:@"Remote" action:nil keyEquivalent:[NSString string]];
		NSMenuItem *changes = [[NSMenuItem alloc] initWithTitle:@"Changes" action:nil keyEquivalent:[NSString string]];
		NSMenuItem *commit = [[NSMenuItem alloc] initWithTitle:@"Commit" action:@selector(commit:) keyEquivalent:[NSString string]];
		[commit setTarget:self];
		[projectMenu addItem:removePath];
		[projectMenu addItem:rescanPath];
		[projectMenu addItem:onBranch];
		[projectMenu addItem:remote];
		[projectMenu addItem:changes];
		[projectMenu addItem:commit];
		[parentItem setSubmenu:projectMenu];
		
		//build branch menu
		[onBranch setSubmenu:onBranchMenu];
		for(NSString * branch in [[self itemDict] objectForKey:@"branches"]) {
			NSMenuItem *b = [[NSMenuItem alloc] initWithTitle:branch action:@selector(switchToBranch:) keyEquivalent:[NSString string]];
			[b setTarget:self];
			[onBranchMenu addItem:b];
		}
		NSMenuItem *newBranch = [[NSMenuItem alloc] initWithTitle:@"New Branch..." action:@selector(newBranch:) keyEquivalent:[NSString string]];
		[newBranch setTarget:self];
		[onBranchMenu addItem:newBranch];
		
		//build remote menu
		[remote setSubmenu:remoteMenu];
		for(NSString * rt in [[self itemDict] objectForKey:@"remote"]) {
			NSMenuItem *r = [[NSMenuItem alloc] initWithTitle:rt action:@selector(switchToSource:) keyEquivalent:[NSString string]];
			[r setTarget:self];
			[remoteMenu addItem:r];
		}
		NSMenuItem *newSource = [[NSMenuItem alloc] initWithTitle:@"New Source..." action:@selector(newSource:) keyEquivalent:[NSString string]];
		[newSource setTarget:self];
		[remoteMenu addItem:newSource];
		
		//changes menu setup
		[changes setSubmenu:changesMenu];
		[changesMenu setDelegate:self];
		
		NSLog(@"Done.");
	}
	@catch (NSException * e) {
		NSLog(@"---------Exception----------");
		NSLog(@"%@", e);
		NSLog(@"----------------------------");
		
		[[NSApplication sharedApplication] presentError:[NSError errorWithDomain:@"Failed to initalize project watcher" code:-1 userInfo:[e userInfo]]];
		[[NSApplication sharedApplication] terminate:nil];
	}
}

//	--- Initialization ---

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
	wrapperLock = [[NSLock alloc] init];
	
	[self setParentItem:anItem];
	[self setTitle:aTitle];
	[self setPath:aPath];
	[self rebuildMenu];
	
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
