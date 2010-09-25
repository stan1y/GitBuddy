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

@synthesize projectRoot, currentPath;
@synthesize commitSource, folder, parentFolder;

- (void) setCurrentPath:(NSString*)path
{
	if (currentPath) {
		[currentPath release];
	}
	
	currentPath = path;
	[currentPath retain];
	
	[folder setStringValue:[NSString stringWithFormat:@"Files at %@", [self currentPath]]];
}

- (void) initForProject:(NSString*)project
{
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
			NSFileManager *fm = [NSFileManager defaultManager];
			NSString *listPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
			NSError *err = nil;
			NSArray *contents = [fm contentsOfDirectoryAtPath:listPath error:&err];
			if (err) {
				[[NSApp delegate] presentError:err];
				return;
			}
			NSString *file =[contents objectAtIndex:index];
			
			[commitSource loadCommitsFor:file inProject:[self projectRoot]];
		}
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSError *err = nil;
	id contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self projectRoot] stringByAppendingPathComponent:[self currentPath]]  error:&err];
	if (err) {
		[[NSApp delegate] presentError:err];
		return 0;
	}
	return [contents count];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *listPath = [[self projectRoot] stringByAppendingPathComponent:[self currentPath]];
	NSError *err = nil;
	NSArray *contents = [fm contentsOfDirectoryAtPath:listPath error:&err];
	if (err) {
		[[NSApp delegate] presentError:err];
		return 0;
	}
	NSString *file =[contents objectAtIndex:rowIndex];

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
