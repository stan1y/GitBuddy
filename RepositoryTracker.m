//
//  RepositoryTracker.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 29/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RepositoryTracker.h"
#import "GitWrapper.h"
#include "time.h"

@implementation RepositoryTracker

@synthesize projectPath, remoteBranches;
@synthesize notPushed, notPulled;

- (void)dealloc
{
	[projectPath release];
	[remoteBranches release];
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
	NSLog(@"Remote branches update period: %d seconds", secs);
	period = secs;
	
	return self;
}

//	-- Thread body

- (void) monitorProject
{
	while (YES) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if ([thread isCancelled]) {
			NSLog(@"Exiting remote changes monitor thread...");
			[thread release];
			thread = nil;
			[pool release];
			pool = nil;
			[NSThread exit];
		}
		
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath ];
		NSString *logArg = [NSString stringWithFormat:@"--log=%@", projectPath ];
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, logArg, nil] withCompletionBlock:^(NSDictionary *dict) {
			
			if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
				//Got log for project, now need to get
				//remote log for every 'rbranch' in project
				//dict.
				NSLog(@"Thread received local log.");
				[self compare:dict withBranches:remoteBranches ];
			}
			
		}];
		
		sleep(period);
	}
}

- (void) compare:(NSDictionary*)projectLog withBranches:(NSArray*)branches
{
	for(NSString *rbranch in branches) {
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", projectPath ];
		NSString *remoetLogArg = [NSString stringWithFormat:@"--log=%@", rbranch];

		NSLog(@"Quering branch %@.", rbranch);
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, remoetLogArg, nil] withCompletionBlock:^(NSDictionary *remoteLog) {
			
			NSMutableDictionary *remoteCommits = [NSMutableDictionary dictionary];
			NSMutableDictionary *localCommits = [NSMutableDictionary dictionary];
			for (NSArray *remoteCommit in [remoteLog valueForKey:@"items"]) {
				[remoteCommits setObject:remoteCommit forKey:[remoteCommit objectAtIndex:0]];
			}
			for (NSArray *localCommit in [projectLog valueForKey:@"items"]) {
				[localCommits setObject:localCommit forKey:[localCommit objectAtIndex:0]];
			}
			
			NSMutableSet *remoteIds = [NSMutableSet setWithArray:[remoteCommits allKeys]];
			NSMutableSet *localIds = [NSMutableSet setWithArray:[localCommits allKeys]];
			
			[remoteIds minusSet:[NSMutableSet setWithArray:[localCommits allKeys]]];
			[localIds minusSet:[NSMutableSet setWithArray:[remoteCommits allKeys]]];
			
			if (branchUdpTarget && branchUdpSel) {
				[branchUdpTarget performSelectorOnMainThread:branchUdpSel withObject:[NSDictionary dictionaryWithObjectsAndKeys:localIds, "not_pushed", remoteIds, "not_pulled", nil]  waitUntilDone:YES];
			}
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if ([defaults boolForKey:@"monitorRemoteNotifyGrowl"]) {
				//FIXME notify growl here
			}
			
			NSLog(@"Remote status: %d commit(s) not pushed and %d not pulled from %@", [localIds count], [remoteIds count], rbranch);
		}];
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
	if ( !thread && remoteBranches) {
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
