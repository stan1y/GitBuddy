//
//  Clone.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 10/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "Clone.h"
#import "GitBuddy.h"
#import "GitWrapper.h"

@implementation Clone

@synthesize repoUrl, repoLocalPath;
@synthesize sshBtn, httpBtn, cloneBtn;

- (void) awakeFromNib
{
	[sshBtn setState:YES];
	[httpBtn setState:NO];
	repoType = SshType;
}

- (IBAction) toggleRepoType:(id)sender
{
	if (sender == sshBtn) {
		[httpBtn setState:NO];
		repoType = SshType;
	}
	else {
		[sshBtn setState:NO];
		repoType = HttpType;
	}

}

- (void) updateRepoPath:(NSString *)url
{
	NSURL *u = [NSURL URLWithString:url];
	if (u) {
		NSArray *components = [u pathComponents];
		if (components && [components count] > 0) {
			[cloneBtn setEnabled:YES];
			return;
		}
	}
	[cloneBtn setEnabled:NO];
}

- (IBAction) browseForLocalPath:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
    if ([op runModal] == NSOKButton){
		[repoLocalPath setStringValue:[op filename]];
		[self updateRepoPath:[repoUrl stringValue]];
    }
}

- (IBAction) cloneRepo:(id)sender
{	
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * localPath = [[repoLocalPath stringValue] stringByExpandingTildeInPath];
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL exists = [mgr fileExistsAtPath:localPath isDirectory:&isDir];
	if ( !exists ) {
		NSError *err = nil;
		[mgr createDirectoryAtPath:localPath withIntermediateDirectories:YES attributes:nil error:&err];
		if (err) {
			[[NSApp delegate] presentError:err];
			return;
		}
	}
	else if ( !isDir) {
		NSRunAlertPanel(@"Oups...", [NSString stringWithFormat:@"Specified path %@ is occupied by some file, you need to remove it or specify another local path for repository.", localPath], @"Continue", nil, nil);
		return;
	}
	
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", localPath];
	NSString * cloneArg = [NSString stringWithFormat:@"--clone=%@", [repoUrl stringValue]];
	NSArray * urlParts = [[NSURL URLWithString:[repoUrl stringValue]] pathComponents];
	NSString * repoPath = [localPath stringByAppendingPathComponent:[[urlParts objectAtIndex:[urlParts count] - 1] stringByDeletingPathExtension]];
	
	int cloneTimeout = [[NSUserDefaults standardUserDefaults] integerForKey:@"gitCloneTimeout"];
	NSLog(@"Cloning repo with timeout %d seconds", cloneTimeout);
	
	//close dialog
	[[self window] performClose:sender];
	
	//show operation panel
	[ (GitBuddy*)[NSApp delegate] startOperation:[NSString stringWithFormat:@"Cloning %@. It may take a while, please wait...", [repoUrl stringValue]]];
	
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, cloneArg, nil] timeoutAfter:cloneTimeout withCompletionBlock:^ (NSDictionary *dict){
		
		//hide operation panel
		[ (GitBuddy*)[NSApp delegate] finishOperation];
		
		if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
			
			GitBuddy *buddy = (GitBuddy*)[NSApp delegate];
			
			if ([buddy addMonitoredPath:repoPath]) {
				[buddy initializeEventForPaths:[buddy monitoredPathsArray]];
				//set new repo as active
				[buddy setActiveProjectByPath:repoPath];
				
				//scan new repo
				[buddy appendEventPaths:[NSArray arrayWithObject:repoPath]];
				[buddy processEventsNow];

				NSRunInformationalAlertPanel(@"GitBuddy successfully cloned repository.", [NSString stringWithFormat:@"New repository was cloned to %@ and set as Active Project.", repoPath], @"Continue", nil, nil);
			}
			else {
				NSRunAlertPanel(@"Oups...", @"Specified path is not valid Git repository to monitor. Cloning failed in some way.", @"Continue", nil, nil);
			}
		}

	}];

}

//text edit delegate to react on changes in url field
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	[self updateRepoPath:[fieldEditor string]];
	return YES;
}

@end
