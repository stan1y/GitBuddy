//
//  NewBranch.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 1/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NewBranch.h"
#import "GitBuddy.h"
#import "ProjectBuddy.h"

@implementation NewBranch

@synthesize projectSources, projectOfBranch, selectedSource;
@synthesize sourcesForBranch, pushBtn;

- (void) showNewBranchOf:(NSString*)project withSources:(NSArray*)sources;
{
	[self setProjectSources:sources];
	[self setProjectOfBranch:project];
	[[self sourcesForBranch] reloadData];
	[self showWindow:self];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if ([self projectSources]) {
		return [[self projectSources] count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([self projectSources] && rowIndex >= 0) {
		return [[self projectSources] objectAtIndex:rowIndex];
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int index = [[aNotification object] selectedRow];
	if (index >= 0) {
		[pushBtn setEnabled:YES];
		[self setSelectedSource:[[self projectSources] objectAtIndex:index]];
	}
	else {
		[pushBtn setEnabled:NO];
	}

}

- (IBAction) createNewBranch:(id)sender
{
	ProjectBuddy *pbuddy = [ (GitBuddy*)[NSApp delegate] getActiveProjectBuddy];
	NSLog(@"Pushing NEW branch '%@' to %@", [pbuddy currentBranch], [self selectedSource]);
	[[self window] orderOut:sender];
	[pbuddy pushToNamedSource:[self selectedSource]];
}

- (IBAction) createNewSource:(id)sender
{
	ProjectBuddy *pbuddy = [ (GitBuddy*)[NSApp delegate] getActiveProjectBuddy];
	NSLog(@"Displaying new source dialog");
	[[self window] orderOut:sender];
	[pbuddy newSource:sender];
}

@end
