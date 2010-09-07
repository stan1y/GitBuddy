//
//  ProjectSubMenu.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProjectSubMenu.h"

@implementation ProjectSubMenu

@synthesize pending;

- (void) dealloc
{
	[data release];
	[super dealloc];
}

- (id) initWithDict:(NSDictionary*)dict forMenu:(NSMenu *)aMenu
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	[self setPending:NO];
	itemsInitially = 0;
	menu = aMenu;
	[menu retain];
	data = dict;
	[data retain];
	
	return self;
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
	if (pending) {
		[item setTitle:@"Pending..."];
	}
	else {
		if (index >= itemsInitially) {
			NSArray *modified = [data objectForKey:@"modified"];
			NSArray *added = [data objectForKey:@"added"];
			NSArray *removed = [data objectForKey:@"removed"];
			NSArray *renamed = [data objectForKey:@"renamed"];
			NSString *itemPath = @"";
			
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
			
			[item setRepresentedObject:itemPath];
			[item setAction:itemSelector];
			[item setTarget:itemTarget];
		}
	}

	return YES;
}

- (int) totalNumberOfFiles
{
	return [[data objectForKey:@"modified"] count] + [[data objectForKey:@"added"] count] + [[data objectForKey:@"removed"] count] + [[data objectForKey:@"renamed"] count];
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	//return "Pending..." when ProjectBuddy tells isPending == YES
	if (pending) {
		return 1;
	}
	else {
		return itemsInitially + [self totalNumberOfFiles];
	}
}


@end
