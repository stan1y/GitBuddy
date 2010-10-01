//
//  NewBranch.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 1/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NewBranch.h"


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
}

- (IBAction) createNewSource:(id)sender
{
}

@end
