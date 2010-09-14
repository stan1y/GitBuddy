//
//  ProjectFilesSource.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectFilesSource.h"

@implementation ProjectFilesSource

@synthesize data;

static NSArray *_arrayDataKeys;

//
//	Keys Arrays to read groups
//	in [self data]
//
+ (NSArray*) dataKeys
{
	if (!_arrayDataKeys) {
		_arrayDataKeys = [[NSArray alloc] initWithObjects:
						  @"modified",
						  @"added",
						  @"removed",
						  @"renamed",
						  nil];
	}
	return _arrayDataKeys;
}

- (id) init
{
	if ( !(self = [super init])) {
		return nil;
	}
	return self;
}

- (void)loadProjectData:(NSDictionary*)pData forPath:(NSString*)p
{
	//clear data
	if (data) {
		[data release];
		data = nil;
		
		[foreign release];
		foreign = nil;
	}
	
	//init data
	data = [[NSMutableDictionary alloc] init];
	for (NSString *k in [ProjectFilesSource dataKeys]) {
		[data setObject:[[NSMutableArray alloc] initWithArray:[pData objectForKey:k] copyItems:YES] forKey:k];
	}
	[data setObject:[NSNumber numberWithInt:[[pData objectForKey:@"count"] intValue]] forKey:@"count"];
	
	//init drag & grop container
	foreign = [[NSMutableArray alloc] init];

	//copy path
	path = [[NSString alloc] initWithString:p];
	
	NSLog(@"Loading Project File Source Data (%@):", self);
	NSLog(@"%@", data);
	NSLog(@" *** ");
}

- (void) dealloc
{
	[data release];
	[path release];
	[foreign release];
	
	[super dealloc];
}

//
//	Files Inspection API
//

- (NSString *)fileAtIndex:(int)index
{
	NSString *grp = nil;
	int grpOffset = 0;
	NSString *file = [self fileAtIndex:index inGroup:&grp groupIndexOffset:&grpOffset];
	return file;
}

-(NSString *)fileInGroup:(NSString*)file
{
	for(NSString *k in [ProjectFilesSource dataKeys]) {
		if ([[data objectForKey:k] indexOfObject:file] != NSNotFound) {
			return k;
		}
	}
	
	return nil;
}

- (NSString *)fileAtIndex:(int)index inGroup:(NSString**)grp groupIndexOffset:(int*)offset
{
	*offset = 0;
	int prevGroupCount = 0;
	for(NSString *k in [ProjectFilesSource dataKeys]) {
		*offset += [[data objectForKey:k] count];
		if ( index < *offset ) {
			*grp = k;
			return [[data objectForKey:k] objectAtIndex:index - prevGroupCount];
		}
		prevGroupCount = [[data objectForKey:k] count];
	}
		
	return nil;
}

- (void)addFile:(NSString*)file toGroup:(NSString*)group
{
	NSLog(@"Adding file %@ from %@", file, group);
	
	[(NSMutableArray*)[data objectForKey:group] addObject:file];
	int count = [[data objectForKey:@"count"] intValue];
	count++;
	[data setObject:[NSNumber numberWithInt:count] forKey:@"count"];
	[foreign addObject:file];
}

- (void)removeFile:(NSString*)file fromGroup:(NSString*)group
{
	NSLog(@"Removing file %@ from %@", file, group);
	
	[(NSMutableArray*)[data objectForKey:group] removeObject:file];
	int count = [[data objectForKey:@"count"] intValue];
	count--;
	[data setObject:[NSNumber numberWithInt:count] forKey:@"count"];
	[foreign removeObject:file];
}

- (BOOL) isForeignFile:(NSString*)file
{
	return [foreign indexOfObject:file] != NSNotFound;
}

- (void) copyFilesFrom:(ProjectFilesSource *)source
{
	for (NSString *k in [ProjectFilesSource dataKeys] ) {
		for (NSString * file in [[source data] objectForKey:k]) {
			[self addFile:file toGroup:k];
		}
	}
	[[source data] removeAllObjects];
}

//
//	Table View Data Source
//

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	int rows = [[data objectForKey:@"count"] intValue];
	return rows;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *file = [self fileAtIndex:rowIndex];
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

//validate received drop
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([info draggingSource] != aTableView && operation == NSTableViewDropAbove) {
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

//accept drop
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pboard = [info draggingPasteboard];
	NSArray * droppedFiles = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:@"StageItem"]];
	
	//add & remove dropped files
	for	(NSString *droppedFile in droppedFiles) {
		NSString *grp = [ (ProjectFilesSource*)[[info draggingSource] dataSource] fileInGroup:droppedFile];
		NSLog(@"Dropped file %@ (%@)", droppedFile, grp);
		ProjectFilesSource* source = (ProjectFilesSource*)[[info draggingSource] dataSource];
		[self addFile:droppedFile toGroup:grp];
		[source removeFile:droppedFile fromGroup:grp];
	}
	NSLog(@"Project File Sources Modified");
	NSLog(@"Receiver: %@", self);
	NSLog(@"%@", data);
	
	NSLog(@" *** ");
	
	//reload receiver
	[aTableView reloadData];
	//reload source
	[[info draggingSource] reloadData];
	
	return YES;
}

//start dragging
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	NSMutableArray *dragged = [[NSMutableArray alloc] init];
	[rowIndexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
		[dragged addObject:[self fileAtIndex:idx]];
	}];
	
	NSData *d = [NSKeyedArchiver archivedDataWithRootObject:dragged];
    [pboard declareTypes:[NSArray arrayWithObject:@"StageItem"] owner:self];
    [pboard setData:d forType:@"StageItem"];
	return YES;
}
				

@end
