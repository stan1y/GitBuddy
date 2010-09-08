//
//  ChangesSource.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ChangesSource.h"

@implementation ChangesSource

@synthesize tableView, indicator, gitObjectsIndex;

- (id) init
{
	if ( !(self = [super init])) {
		return nil;
	}
	
	wrapper = [[GitWrapper alloc] init];
	gitObjectsIndex = nil;
	
	return self;
}

- (void) dealloc
{
	[wrapper release];
	[gitObjectsIndex release];
	[currentSource release];
	[super dealloc];
}

- (void) rebuildIndex:(NSString *)projectPath withCompletionBlock:(void (^)(void))codeBlock
{
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSLog(@"Quering staged contents at %@...", projectPath);
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	//scan remote, branch and changes
	[wrapper executeGit:[NSArray arrayWithObjects:@"--staged-index", repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		
		if (gitObjectsIndex) {
			[gitObjectsIndex release];
		}
		if (dict) {
			gitObjectsIndex = [[NSMutableDictionary alloc] init];
			for(int i=0; i < [[dict objectForKey:@"count"] intValue] / 2; i++) {
				[gitObjectsIndex setObject:[[dict objectForKey:@"keys"] objectAtIndex:i] forKey:[[dict objectForKey:@"files"] objectAtIndex:i]];
			}
			NSLog(@"Git Stage Index");
			NSLog(@"%@", gitObjectsIndex);
			NSLog(@"***");
			
			[tableView setEnabled:YES];
			//call block
			codeBlock();
		}
	}];
}

- (void) updateWithChangeset:(NSString *)filePath inPath:(NSString *)projectPath
{
	//scan remote, branch and changes
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSString * showArg = [NSString stringWithFormat:@"--show=%@", [gitObjectsIndex objectForKey:filePath] ];
	
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	
	[wrapper executeGit:[NSArray arrayWithObjects:showArg, repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		if (currentSource) {
			[currentSource release];
		}
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];
		
		NSLog(@"Reloading changes with changeset");
		currentSource = dict;
		[currentSource retain];
		[tableView reloadData];
	}];
}

- (void) updateWithFileDiff:(NSString *)filePath inPath:(NSString *)projectPath
{
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSString * diffArg = [NSString stringWithFormat:@"--diff=%@", filePath];
	
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	
	[wrapper executeGit:[NSArray arrayWithObjects:diffArg, repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		if (currentSource) {
			[currentSource release];
		}
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];
		
		NSLog(@"Reloading changes with file diff");
		currentSource = dict;
		[currentSource retain];
		[tableView reloadData];
	}];
	
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[currentSource objectForKey:@"lines"] count];
}

- (NSString *) stringAtIndex:(int)index
{
	return [[currentSource objectForKey:@"lines"] objectAtIndex:index];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [self stringAtIndex:rowIndex];
}

@end