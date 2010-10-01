//
//  RepositoryTracker.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 29/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Growl/GrowlApplicationBridge.h>
#import "RepositoryTracker.h"
#import "GitWrapper.h"
#import "GitBuddy.h"
#import "ProjectBuddy.h"
#include "time.h"

@implementation RepositoryTracker

@synthesize projectPath;
@synthesize notPushed, notPulled, period;

- (void)dealloc
{
	[projectPath release];
	[notPushed release];
	[notPulled release];
	
	[super dealloc];
}

- (id) initTrackerForProject:(NSString *)path withPeriod:(int)secs
{
	if (!(self = [super init])) {
		return nil;
	}
	
	[self setProjectPath:path];
	period = secs;
	
	return self;
}

//	-- Thread body

- (void) monitorProject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while (YES) {
		if ([thread isCancelled]) {
			NSLog(@"Exiting remote changes monitor thread...");
			[thread release];
			thread = nil;
			[pool release];
			pool = nil;
			[NSThread exit];
		}
		
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		ProjectBuddy *pbuddy = [[(GitBuddy*)[NSApp delegate] menuItemForPath:projectPath] representedObject];
		
		//compare each branch with it's couterpart in rbranch
		for (NSString *branch in [[[pbuddy itemDict] objectForKey:@"branches"] objectForKey:@"branch"]) {
			NSString *remoteSource = [pbuddy getSourceForBranch:branch];
			if (remoteSource && [remoteSource length]) {
				
				//get local status
				NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath ];
				NSString *remoteInfoArg = [NSString stringWithFormat:@"--log=%@", branch ];
				NSDictionary *localInfo = [wrapper executeGit:[NSArray arrayWithObjects:repoArg, remoteInfoArg, nil]];
				NSLog(@"%@ %@ has %d commits", projectPath, branch, [[localInfo objectForKey:@"items"] count]);
				
				NSString *remoteArg = [NSString stringWithFormat:@"--log=%@/%@", remoteSource, branch];
				NSDictionary *remoteInfo = [wrapper executeGit:[NSArray arrayWithObjects:repoArg, remoteArg, nil]];
				NSLog(@"%@ branch %@/%@ has %d commits", projectPath, remoteSource, branch, [[remoteInfo objectForKey:@"items"] count]);
				
				//compare
				NSMutableDictionary *remoteCommits = [NSMutableDictionary dictionary];
				NSMutableDictionary *localCommits = [NSMutableDictionary dictionary];
				for (NSArray *remoteCommit in [remoteInfo valueForKey:@"items"]) {
					[remoteCommits setObject:remoteCommit forKey:[remoteCommit objectAtIndex:0]];
				}
				for (NSArray *localCommit in [localInfo valueForKey:@"items"]) {
					[localCommits setObject:localCommit forKey:[localCommit objectAtIndex:0]];
				}
				
				NSMutableSet *remoteIds = [NSMutableSet setWithArray:[remoteCommits allKeys]];
				NSMutableSet *localIds = [NSMutableSet setWithArray:[localCommits allKeys]];
				
				[remoteIds minusSet:[NSMutableSet setWithArray:[localCommits allKeys]]];
				[localIds minusSet:[NSMutableSet setWithArray:[remoteCommits allKeys]]];
				
				/*
				 * Data for update is a dict with keys:
				 *	- not_pushed - list of sha256
				 *	- not_pulled - list of sha256
				 *	- remote_commits - dict with [sha256:commit array]
				 *	- local_commits - dict with [sha256:commit array]
				 *	- cached - array with changed files in repo
				 */
				
				NSLog(@"%d commit(s) not pushed and %d not pulled from %@ in project %@", [localIds count], [remoteIds count], branch, projectPath);
				
				if (branchUdpTarget && branchUdpSel) {
					NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:localIds, @"not_pushed", remoteIds, @"not_pulled", remoteCommits, @"remote_commits", localCommits, @"local_commits", [self projectPath], @"path", nil];
					[branchUdpTarget performSelectorOnMainThread:branchUdpSel withObject:data  waitUntilDone:YES];
				}
				
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if ([remoteIds count] && [defaults boolForKey:@"monitorRemoteNotifyGrowl"]) {
					
					//remote notify with growl
					[GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"%@ on %@ was updated.", branch, remoteSource] description:[NSString stringWithFormat:@"%d commit(s) appeared. Pull to %@", [remoteIds count], projectPath] notificationName:@"REMOTE_BRANCH_CHANGED" iconData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy" ofType:@"png"]] priority:0 isSticky:NO clickContext:nil];
				}
				
				if ([localIds count] && [defaults boolForKey:@"monitorRemoteNotifyGrowl"]) {
					
					//remote notify with growl
					[GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"%@ was updated.", branch] description:[NSString stringWithFormat:@"You need to push %d commit(s) from %@", [localIds count], projectPath] notificationName:@"LOCAL_BRANCH_CHANGED" iconData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy" ofType:@"png"]] priority:0 isSticky:NO clickContext:nil];
				}
			}
		}
		
		NSLog(@"Remote changes thread for %@ is sleeping for %d seconds.", projectPath, period);
		sleep(period);
	}
}

// -- Callbacks setup

- (void) setBranchUpdatedSelector:(SEL)sel
{
	branchUdpSel = sel;
}

- (void) setBranchUpdatedTarget:(id)target
{
	branchUdpTarget = target;
}

// -- Start & Stop

- (BOOL) isRunning
{
	return (thread != nil);
}

- (IBAction) startMonitoring:(id)sender
{
	if ( !thread ) {
		NSLog(@"Starting remote changes monitor thread...");
		thread = [[NSThread alloc] initWithTarget:self selector:@selector(monitorProject) object:nil];
		[thread start];
	}
}

- (IBAction) stopMonitoring:(id)sender
{
	if (thread) {
		[thread cancel];
	}
}

@end
