//
//  CommitsSource.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 22/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommitsSource.h"
#import "GitWrapper.h"

@implementation CommitsSource

@synthesize commits, sourceFile, projectPath;
@synthesize tableView, indicator, diffSource, commitMessage;

- (void) loadCommitsFor:(NSString*)file inProject:(NSString*)project
{
	[self setSourceFile:file];
	[self setProjectPath:project];
	
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", project];
	NSString * logArg = [NSString stringWithFormat:@"--log=%@", file];
	
	[tableView setEnabled:NO];
	[indicator setHidden:NO];
	[indicator startAnimation:nil];
	
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, logArg, nil] withCompletionBlock:^(NSDictionary *dict) {
		
		[indicator stopAnimation:nil];
		[indicator setHidden:YES];
		[tableView setEnabled:YES];
		
		if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
			[self setCommits:[[dict objectForKey:@"items"] copy]];
			NSLog(@"Reloading commits %@",[self commits]);
			[tableView reloadData];
		}

	}];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int index = [[aNotification object] selectedRow];
	if (index >= 0) {
		NSArray *commit = [[self commits] objectAtIndex:index];
		[diffSource updateWithCommitDiff:sourceFile commitId:[commit objectAtIndex:0] inPath:[self projectPath]];
		[[self commitMessage] setStringValue:[commit objectAtIndex:3]];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (commits) {
		return [commits count];
	}
	return 0;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (commits) {
		NSArray *commit = [[self commits] objectAtIndex:rowIndex];
		return [NSString stringWithFormat:@"Commit #%d %@ by %@", rowIndex + 1, [commit objectAtIndex:1], [commit objectAtIndex:2]];
	}
	return nil;
}


@end
