//
//  ProjectSubMenu.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectSubMenu.h"

@implementation ProjectSubMenu

- (void) dealloc
{
	[data release];
	[project release];
	[super dealloc];
}

- (id) initProject:(NSString*)prj withDict:(NSDictionary*)dict forMenu:(NSMenu *)aMenu
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	project = prj;
	[project retain];
	itemsInitially = 0;
	menu = aMenu;
	[menu retain];
	data = dict;
	[data retain];
	
	return self;
}

- (void) setCheckedItems:(NSArray*)items
{
	checkedItems = [items copy];
}

- (void) setData:(NSDictionary *)dict
{
	if (data) {
		[data release];
	}
	data = dict;
	[data retain];
}

- (void) setInitialItems:(NSArray*)items
{
	for(NSMenuItem *i in items) {
		[menu addItem:i];
	}
	itemsInitially = [items count];
}

- (void) setItemSelector:(SEL)sel target:(id)aTarget
{
	itemSelector = sel;
	itemTarget = aTarget;
}

- (NSArray*) selectedFiles
{
	NSMutableArray *selected = [NSMutableArray array];
	for(NSMenuItem *i in [menu itemArray]) {
		if ([i state]) {
			[selected addObject:[i title]];
		}
	}
	return selected;
}

//	--- Changes Menu Delegate

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	if (index >= itemsInitially && index < itemsInitially + [self totalNumberOfFiles]) {
		NSString *itemPath = @"";
		BOOL isFile = NO;
		
		NSLog(@"Data: %@", data);
		
		// Check what are we going to list here
		// whenever we read files from staged/unstaged, untracked, branch list or remote list
		if ( [data objectForKey:@"branch"] ) {
			
			// Branches list
			
			itemPath = [[data objectForKey:@"branch"] objectAtIndex:(index - itemsInitially)];
			[item setTitle:itemPath];
		}
		else if ( [data objectForKey:@"source"] ) {
			
			// Remotes list
			
			itemPath = [[data objectForKey:@"source"] objectAtIndex:(index - itemsInitially)];
			[item setTitle:itemPath];
			
		}
		else if ([data objectForKey:@"files"]) {
			
			// Untracked files list
			isFile = YES;
			
			itemPath = [[data objectForKey:@"files"] objectAtIndex:(index - itemsInitially)];
			[item setTitle:[NSString stringWithFormat:@"%@", itemPath]];
		}
		else {
			
			//Changed files list with groups
			isFile = YES;
			
			NSArray *modified = [data objectForKey:@"modified"];
			NSArray *added = [data objectForKey:@"added"];
			NSArray *removed = [data objectForKey:@"removed"];
			NSArray *renamed = [data objectForKey:@"renamed"];
			
			if ([modified count] && index - itemsInitially < [modified count]) {
				//modified files list
				itemPath = [modified objectAtIndex:(index - itemsInitially)];
				[item setTitle:[NSString stringWithFormat:@"%@ (changed)", itemPath]];
			}
			if ([added count] && index - itemsInitially >= [modified count]) { 
				//added files list
				itemPath = [added objectAtIndex:(index - itemsInitially  - [modified count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (added)", itemPath]];
			}
			if ([removed count] && index - itemsInitially >= [modified count] + [added count]) { 
				//removed files list
				itemPath = [removed objectAtIndex:(index - itemsInitially  - [modified count] - [added count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (removed)", itemPath]];
			}
			if ([renamed count] && index - itemsInitially >= [modified count] + [added count] + [removed count]) { 
				//renamed files list
				itemPath = [renamed objectAtIndex:(index - itemsInitially  - [modified count] - [added count] - [removed count])];
				[item setTitle:[NSString stringWithFormat:@"%@ (renamed)", itemPath]];
			}
		}
		[item setRepresentedObject:itemPath];
		[item setAction:itemSelector];
		[item setTarget:itemTarget];
		
		//file with icon or checked item?
		if (isFile) {
			[item setState:YES];
			NSString * filePath = [project stringByAppendingPathComponent:itemPath];
			NSImage *img = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
			[img setSize:NSMakeSize(16, 16)];
			[item setOnStateImage:img];
		}
		else if ([checkedItems count] && [checkedItems indexOfObject:itemPath] != NSNotFound) {
			[item setState:YES];
		}
		else {
			[item setState:NO];
		}

	}
	
	return YES;
}

- (int) totalNumberOfFiles
{
	return [[data objectForKey:@"count"] intValue];
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	return itemsInitially + [self totalNumberOfFiles];
}


@end
