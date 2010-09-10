//
//  Commit.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Commit.h"
#import "GitWrapper.h"
#import "GitBuddy.h"

@implementation Commit

@synthesize stagedSource, filesView, previewBtn;
@synthesize commitMessage;
@synthesize selectedFile, projectPath;

- (void) commitProject:(NSDictionary*)proj atPath:(NSString*)path
{
	[self setProjectPath:path];
	[stagedSource loadProjectData:[proj objectForKey:@"staged"] forPath:path];
	[filesView reloadData];
}

- (IBAction) fileSelected:(id)sender
{
	int index = [filesView selectedRow];
	if (index == -1) {
		NSLog(@"Deselected.");
		[previewBtn setHidden:YES];
	}
	[self setSelectedFile:[stagedSource fileAtIndex:index]];
	NSLog(@"Selected file %@", [self selectedFile]);
	[previewBtn setHidden:NO];
}

- (IBAction) showPreview:(id)sender
{
	[[(GitBuddy*)[NSApp delegate] preview] loadPreviewOf:[self selectedFile] inPath:[self projectPath]];
	[[(GitBuddy*)[NSApp delegate] preview] showWindow:sender];
}

- (IBAction) commit:(id)sender
{
	//check message
	NSString *msg = [commitMessage stringValue];
	if ([msg length] == 0) {
		if (NSRunAlertPanel(@"Empty Commit Log Message!", @"Are you sure that your commit should be with no message?", 
							@"Yes", @"No", nil) != 1) {
			//cancel commit
			return;
		}
	}
	
	//commit files
	GitWrapper* wrapper = [GitWrapper sharedInstance];
	NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath];
	NSString *commitArg = [NSString stringWithFormat:@"--commit=%@", msg];
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, commitArg, nil] withCompletionBlock:^(NSDictionary *dict){
	}];
	
	[[self window] performClose:sender];
}

@end
