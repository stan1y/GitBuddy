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
	
	NSLog(@"Loading File Stager with Project Dictionary:");
	NSLog(@"%@", dict);
	NSLog(@" *** ");
	
	[title setStringValue:@"Loading Git index..."];
	[stagedView setEnabled:NO];
	[unstagedView setEnabled:NO];
	
	[stagedView registerForDraggedTypes:[NSArray arrayWithObject:@"StageItem"]];
	[unstagedView registerForDraggedTypes:[NSArray arrayWithObject:@"StageItem"]];
	
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
	NSString *file = [[aTableView dataSource] fileAtIndex:rowIndex];
	[title setStringValue:[NSString stringWithFormat:@"Preview of %@", file]  ];
	
	//deselect opposite table if it was selected
	if ([aTableView dataSource] == stagedSource) {
		[unstagedView deselectAll:nil];
	}
	else if ([aTableView dataSource] == unstagedSource){
		[stagedView deselectAll:nil];
	}
	
	//sources have their own copy of staged & unstaged
	//dicts to support grag & drop operations
	//need to make sure which one file really belongs
	NSString* grp = [[aTableView dataSource] fileInGroup:file];
	NSLog(@"Loading %@ (%@)", file, grp);
	NSArray * stagedGroup = [[project objectForKey:@"staged"] objectForKey:grp];
	NSArray * unstagedGroup = [[project objectForKey:@"unstaged"] objectForKey:grp];
	NSLog(@"Staged Files:");
	NSLog(@"%@", stagedGroup);
	NSLog(@" *** ");
	NSLog(@"Unstaged Files:");
	NSLog(@"%@", unstagedGroup);
	NSLog(@" *** ");
	if ( [stagedGroup indexOfObject:file] != NSNotFound ) {
		//belogs to staged.group.file
		[changesSource updateWithChangeset:[[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
	}
	else if ( [unstagedGroup indexOfObject:file] != NSNotFound ){
		//belogs to unstaged.group.file
		[changesSource updateWithFileDiff:[[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
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
		NSString* grp = nil;
		int offset = 0;
		[[aTableView dataSource] fileAtIndex:rowIndex inGroup:&grp groupIndexOffset:&offset];;
		
		if ([grp isEqual:@"modified"]) {
			[aCell setTextColor:[NSColor orangeColor]];
		}
		else if ([grp isEqual:@"added"]) {
			[aCell setTextColor:[NSColor greenColor]];
		}
		else if ([grp isEqual:@"removed"] || [grp isEqual:@"renamed"]) {
			[aCell setTextColor:[NSColor orangeColor]];
		}
		
	} else {
		
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
