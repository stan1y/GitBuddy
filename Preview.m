//
//  Preview.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "Preview.h"
#import "Highlight.h"
#import "GitBuddy.h"
#import "GitWrapper.h"

@implementation Preview

@synthesize changesSource;
@synthesize filePath, projectPath;

- (void)dealloc
{
	if (filePath) {
		[filePath release];
		filePath = nil;
	}
	
	if (projectPath) {
		[projectPath release];
		projectPath = nil;
	}
	
	
	[super dealloc];
}

- (void) loadPreviewOf:(NSString *)file inPath:(NSString*)path
{
	[self setFilePath:file];
	[self setProjectPath:path];
	
	[[self window] setTitle:[NSString stringWithFormat:@"Changes in %@", [path stringByAppendingPathComponent:file]]];
	[changesSource updateWithFileDiff:file inPath:path];
}

- (void) loadChangeSetOf:(NSString *)file inPath:(NSString*)path
{
	[self setFilePath:file];
	[self setProjectPath:path];
	
	[[self window] setTitle:[NSString stringWithFormat:@"Staged changes in %@", [path stringByAppendingPathComponent:file]]];
	[changesSource updateWithCachedFileDiff:file inPath:path];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *str = [changesSource stringAtIndex:rowIndex];
	[Highlight highLightCell:aCell forLine:str];
}

- (IBAction) showInExternalViewer:(id)sender
{
	[DiffViewSource externalDiffViewer:[self filePath] withOriginal:@"/dev/nul" project:[self projectPath]];
	[[self window] performClose:sender];
}

- (IBAction) resetChanges:(id)sender
{
	int rc = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Revert %@ to head of current branch?", [self filePath]], [NSString stringWithFormat:@"You are about to revert your current %@ to last commited state.", [self filePath]], @"Yes", @"No", nil);
	
	if (rc == 1) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", [self projectPath]];
		NSString *resetArg = [NSString stringWithFormat:@"--reset=%@", [self filePath]];
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, resetArg, nil] withCompletionBlock:^(NSDictionary *dict){
			[ (GitBuddy*)[NSApp delegate] rescanRepoAtPath:projectPath];
			NSLog(@"File %@ was reset to HEAD", [self filePath]);
		}];
		
		[[self window] performClose:sender];
	}
}

@end
