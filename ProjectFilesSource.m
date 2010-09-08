//
//  ProjectFilesSource.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectFilesSource.h"


@implementation ProjectFilesSource

- (void)loadProjectData:(NSDictionary*)pData forPath:(NSString*)p
{
	data = [pData mutableCopy];
	[data retain];
	path = [p copy];
	[path retain];
}

- (void) dealloc
{
	[data release];
	[path release];
	[super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[data objectForKey:@"count"] intValue];
}

- (id)fileAtIndex:(int)index
{
	int grp = -1;
	return [self fileAtIndex:index inGroupIndex:&grp];
}

- (id)fileAtIndex:(int)index inGroupIndex:(int*)grpIndex
{
	NSArray *modified = [data objectForKey:@"modified"];
	NSArray *added = [data objectForKey:@"added"];
	NSArray *removed = [data objectForKey:@"removed"];
	NSArray *renamed = [data objectForKey:@"renamed"];
	
	if ([modified count] && index < [modified count]) {
		*grpIndex = 0;
		return [modified objectAtIndex:index];
	}
	if ([added count] && index >= [modified count] ) {
		*grpIndex = 1;
		return [added objectAtIndex:(index - [modified count])];
	}
	if ([removed count] && index >= [modified count] + [added count]) {
		*grpIndex = 2;
		return [removed objectAtIndex:(index - [modified count] - [added count])];
	}
	if ([renamed count] && index >= [modified count] + [added count] + [removed count]) {
		*grpIndex = 3;
		return [renamed objectAtIndex:(index - [modified count] - [added count] - [removed count])];
	}
	
	return nil;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *file = [self fileAtIndex:rowIndex];
	NSLog(@"Listing %@", [path stringByAppendingPathComponent:file]);
	NSString *col = [aTableColumn identifier];
	if ([col isEqual:@"icon"]) {
		return [[NSWorkspace sharedWorkspace] iconForFile:[path stringByAppendingPathComponent:file]];
	}
	else if ([col isEqual:@"file"]) {
		return file;
	}
	else {
		return nil;
	}
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
}
			
- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
}
				

@end
