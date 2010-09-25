//
//  DiffViewSource.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "DiffViewSource.h"
#import "GitWrapper.h"

@implementation DiffViewSource

@synthesize tableView, indicator, gitObjectsIndex, currentSource;

- (id) init
{
	if ( !(self = [super init])) {
		return nil;
	}
	
	gitObjectsIndex = nil;
	
	return self;
}

- (void) dealloc
{
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
	GitWrapper * wrapper = [GitWrapper sharedInstance];
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

- (void) updateWithCommitDiff:(NSString *)filePath commitId:(NSString*)commitId inPath:(NSString *)projectPath
{
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSString * diffArg = [NSString stringWithFormat:@"--commit-diff=%@", filePath];
	NSString * keyArg = [NSString stringWithFormat:@"--key=%@", commitId];
	
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	
	GitWrapper * wrapper = [GitWrapper sharedInstance];
	[wrapper executeGit:[NSArray arrayWithObjects:diffArg, repoArg, keyArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		
		[self setCurrentSource:dict];
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];

		NSLog(@"Reloading changes with commit diff");
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
	
	GitWrapper * wrapper = [GitWrapper sharedInstance];
	[wrapper executeGit:[NSArray arrayWithObjects:diffArg, repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		[self setCurrentSource:dict];
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];

		NSLog(@"Reloading changes with file diff");
		[tableView reloadData];
	}];
	
}

- (void) updateWithCachedFileDiff:(NSString *)filePath inPath:(NSString *)projectPath
{
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSString * diffArg = [NSString stringWithFormat:@"--cached-diff=%@", filePath];
	
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	
	GitWrapper * wrapper = [GitWrapper sharedInstance];
	[wrapper executeGit:[NSArray arrayWithObjects:diffArg, repoArg, nil] withCompletionBlock: ^(NSDictionary *dict){
		[self setCurrentSource:dict];
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];

		NSLog(@"Reloading changes with cached file diff");
		[tableView reloadData];
	}];
	
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	
	if (currentSource) return [[currentSource objectForKey:@"lines"] count];
	return 0;
}

- (NSString *) stringAtIndex:(int)index
{
	if (currentSource) return [[currentSource objectForKey:@"lines"] objectAtIndex:index];
	return @"";
	
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [self stringAtIndex:rowIndex];
}

@end
