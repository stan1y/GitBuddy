//
//  Preview.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Preview.h"
#import "Highlight.h"
#import "ChangeSetViewer.h"
#import "GitBuddy.h"
#import "GitWrapper.h"

@implementation Preview

@synthesize changesSource;
@synthesize filePath, projectPath;

- (void)dealloc
{
	if (filePath) {
		[filePath release];
	}
	
	if (projectPath) {
		[projectPath release];
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
	//FIXME : won't work for anything except git difftool
	
	ChangeSetViewer *viewer = [ChangeSetViewer viewModified:@"/dev/null" diffTo:[self filePath] project:[self projectPath]];
	[[(GitBuddy*)[NSApp delegate] queue] addOperation:viewer];
	[viewer release];
	
	[[self window] performClose:sender];
}

- (IBAction) resetChanges:(id)sender
{
	int rc = NSRunAlertPanel(@"Resetting changes in file", [NSString stringWithFormat:@"You are about to dismiss all changes you've made to %@. Are you sure about it?", [self filePath]] , @"Yes", @"No", nil);
	
	if (rc == 1) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", [self projectPath]];
		NSString *resetArg = [NSString stringWithFormat:@"--reset=%@", [self filePath]];
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, resetArg, nil] withCompletionBlock:^(NSDictionary *dict){
			[dict release];
			NSLog(@"File %@ was reset to HEAD", [self filePath]);
		}];
		
		[[self window] performClose:sender];
	}
}

@end
