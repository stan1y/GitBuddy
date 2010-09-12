//
//  Clone.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 10/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Clone.h"
#import "GitBuddy.h"
#import "GitWrapper.h"

@implementation Clone

@synthesize repoUrl, repoLocalPath;
@synthesize sshBtn, httpBtn, cloneBtn;
@synthesize indicator, msg;

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
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", [repoLocalPath stringValue]];
	NSString * cloneArg = [NSString stringWithFormat:@"--clone=%@", [repoUrl stringValue]];
	NSArray * urlParts = [[NSURL URLWithString:[repoUrl stringValue]] pathComponents];
	NSString * repoPath = [[repoLocalPath stringValue] stringByAppendingPathComponent:[[urlParts objectAtIndex:[urlParts count] - 1] stringByDeletingPathExtension]];
	
	[indicator setHidden:NO];
	[indicator startAnimation:sender];
	[msg setHidden:NO];
	[msg setStringValue:[NSString stringWithFormat:@"Cloning %@...", repoPath]];
	
	[wrapper executeGit:[NSArray arrayWithObjects:repoArg, cloneArg, nil] withCompletionBlock:^ (NSDictionary *dict){
		[indicator stopAnimation:sender];
		[indicator setHidden:YES];
		[msg setHidden:YES];

		
		GitBuddy *buddy = (GitBuddy*)[NSApp delegate];
		
		if ([buddy addMonitoredPath:repoPath]) {
			[buddy initializeEventForPaths:[buddy monitoredPathsArray]];
			//set new repo as active
			[buddy setActiveProjectByPath:repoPath];
			
			NSRunInformationalAlertPanel(@"GitBuddy successfully cloned repository.", [NSString stringWithFormat:@"New repository was cloned to %@ and set as Active Project.", repoPath], @"Continue", nil, nil);
		}
		else {
			NSRunAlertPanel(@"Oups...", @"Specified path is not valid Git repository to monitor. Cloning failed someway.", @"Continue", nil, nil);
		}
	}];
	
	//close dialog
	[[self window] performClose:sender];
}

//text edit delegate to react on changes in url field
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	[self updateRepoPath:[fieldEditor string]];
	return YES;
}

@end
