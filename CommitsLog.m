//
//  CommitsLog.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 22/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "CommitsLog.h"
#import "Highlight.h"

@implementation CommitsLog

@synthesize projectRoot, currentPath, filesTableView;
@synthesize commitSource, folder, parentFolder;

- (void) dealloc
{
	[filesTableView release];
	[projectRoot release];
	[currentPath release];
	[filesTableView release];
	[super dealloc];
}

- (void) setCurrentPath:(NSString*)path
{
	if (currentPath) {
		[currentPath release];
	}
	
	currentPath = path;
	[currentPath retain];
	
	if ([currentPath isEqual:[NSString stringWithString:@"/"]]) {
		[[self parentFolder] setEnabled:NO];
	}
	else {
		[[self parentFolder] setEnabled:YES];
	}

	
	[folder setStringValue:[NSString stringWithFormat:@"Files at %@", [self currentPath]]];
}

- (IBAction) goToParentFolder:(id)sender
{
	if ([currentPath isEqual:[NSString stringWithString:@"/"]]) {
		return;
	}
	
	NSArray *components = [currentPath pathComponents];
	NSString *newCurrentPath = [[components subarrayWithRange:NSMakeRange(0, [components count] - 1)] componentsJoinedByString:@"/"];
	NSLog(@"Change directory to %@", newCurrentPath);
	[self setCurrentPath:newCurrentPath];
	[[self filesTableView] reloadData];}

- (void) fileDoubleClicked
{
	int index = [[self filesTableView] clickedRow];
	NSArray *contents = [self currentFolderFiles];
	NSString *clickedPath = [contents objectAtIndex:index];
	NSString *currentFullPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
	NSString *cdToPath = [currentFullPath stringByAppendingPathComponent:clickedPath];
	BOOL isDir = NO;
	NSFileManager *mgr = [NSFileManager defaultManager];
	[mgr fileExistsAtPath:cdToPath isDirectory:&isDir];
	if (isDir) {
		[self setCurrentPath:[[self currentPath] stringByAppendingPathComponent:clickedPath]];
		[[self filesTableView] reloadData];
	}
}

- (void) initForProject:(NSString*)project
{
	[[self filesTableView] setDoubleAction:@selector(fileDoubleClicked)];
	[[self filesTableView] setTarget:self];
	[self setProjectRoot:project];
	[self setCurrentPath:@"/"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == [[[self commitSource] diffSource] tableView]) {
		//high light diff view
		NSString *str = [[[self commitSource] diffSource] stringAtIndex:rowIndex];
		[Highlight highLightCell:aCell forLine:str];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] != [[[self commitSource] diffSource] tableView]) {
		int index = [[aNotification object] selectedRow];
		if (index >= 0) {

			NSString *listPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
			NSString *file = [[self currentFolderFiles] objectAtIndex:index];
			BOOL isDir = NO;
			NSFileManager *mgr = [NSFileManager defaultManager];
			[mgr fileExistsAtPath:[listPath stringByAppendingPathComponent:file] isDirectory:&isDir];
			if (!isDir) {
				NSString *filePath = [[self currentPath] stringByAppendingPathComponent:file];
				[commitSource loadCommitsFor: [filePath substringWithRange:NSMakeRange(1, [filePath length] -1)] inProject:[self projectRoot]];
			}
		}
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self currentFolderFiles] count];
}

- (NSArray*) currentFolderFiles
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *err = nil;
	NSString *fullPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
	NSArray *contents = [fm contentsOfDirectoryAtPath:fullPath error:&err];
	if (err) {
		[[NSApp delegate] presentError:err];
		return 0;
	}
	return contents;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *listPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
	NSArray *contents = [self currentFolderFiles];
	NSString *file = [contents objectAtIndex:rowIndex];
	NSString *col = [aTableColumn identifier];
	if ([col isEqual:@"icon"]) {
		return [[NSWorkspace sharedWorkspace] iconForFile:[listPath stringByAppendingPathComponent:file]];
	}
	else if ([col isEqual:@"file"]) {
		return file;
	}
	else {
		return nil;
	}
}

@end
