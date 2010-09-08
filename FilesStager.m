//
//  FilesStager.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FilesStager.h"

@implementation FilesStager

@synthesize stagedSource, unstagedSource, changesSource;
@synthesize stagedView, unstagedView, title;

- (void) dealloc
{
	[project release];
	[super dealloc];
}

- (void) setProject:(NSDictionary *)dict
{
	project = [dict copy];
	[project retain];
	
	[title setStringValue:@"Loading Git index..."];
	[stagedView setEnabled:NO];
	[unstagedView setEnabled:NO];
	
	[changesSource rebuildIndex:[project objectForKey:@"path"] withCompletionBlock: ^{
		[stagedView setEnabled:YES];
		[unstagedView setEnabled:YES];
		
		//load project files to table views
		[stagedSource loadProjectData:[project objectForKey:@"staged"] forPath:[project objectForKey:@"path"]];
		[unstagedSource loadProjectData:[project objectForKey:@"unstaged"] forPath:[project objectForKey:@"path"]];
		[stagedView reloadData];
		[unstagedView reloadData];
		if ([[[project objectForKey:@"unstaged"] objectForKey:@"count"] intValue] > 0) {
			[unstagedView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			[self tableView:unstagedView shouldSelectRow:0];
		}
		else if ([[[project objectForKey:@"staged"] objectForKey:@"count"] intValue] > 0) {
			[stagedView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			[self tableView:stagedView shouldSelectRow:0];
		}
	}];
}

//	TableView selection
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	if ([aTableView dataSource] == stagedSource) {
		[unstagedView deselectAll:nil];
		[title setStringValue:[NSString stringWithFormat:@"Preview of ChangeSet %@", [[changesSource gitObjectsIndex] objectForKey:[[aTableView dataSource] fileAtIndex:rowIndex]]]  ];
		[changesSource updateWithChangeset:[[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		return YES;
	}
	else if ([aTableView dataSource] == unstagedSource){
		NSString *filePath = [[project objectForKey:@"path"] stringByAppendingPathComponent:[[aTableView dataSource] fileAtIndex:rowIndex]];
		[title setStringValue:[NSString stringWithFormat:@"Diff of %@", filePath] ];
		[stagedView deselectAll:nil];
		[changesSource updateWithFileDiff:[[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		return YES;
	}
	return YES;
}

// TableView selection

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (![aCell isKindOfClass:[NSTextFieldCell class]]) {
		return;
	}
	
	if (aTableView == stagedView || aTableView == unstagedView) {
		int grp = -1;
		NSString *f = [[aTableView dataSource] fileAtIndex:rowIndex inGroupIndex:&grp];
		switch (grp) {
			case 0:
				//modified
				[aCell setTextColor:[NSColor orangeColor]];
				break;
			case 1:
				//added
				[aCell setTextColor:[NSColor greenColor]];
				break;
			case 2:
			case 3:
				//removed
				//renamed
				[aCell setTextColor:[NSColor redColor]];
				break;
			default:
				break;
		}
	}
	else
	{
		NSString *str = [[aTableView dataSource] stringAtIndex:rowIndex];
		if ([str length] > 0) {
			NSLog(@"%d - %@", [str characterAtIndex:0], str);
			if ( [str characterAtIndex:0] == 43 ) {
				[aCell setTextColor:[NSColor greenColor]];
			}
			else if ( [str characterAtIndex:0] == 45) {
				[aCell setTextColor:[NSColor redColor]];
			}
			else {
				[aCell setTextColor:[NSColor lightGrayColor]];
			}

			return;
		}
		
		//other lines
		[aCell setTextColor:[NSColor lightGrayColor]];
		return;
	}
}

@end
