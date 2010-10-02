//
//  RepositoryTracker.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 29/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RepositoryTracker : NSObject {

	NSThread *thread;
	SEL branchUdpSel;
	id branchUdpTarget;
	int period;
	NSString *projectPath;
	
	NSMutableArray *notPushed;
	NSMutableArray *notPulled;
	NSLock *threadLock;
}
@property (assign) int period;
@property (nonatomic, retain) NSMutableArray *notPushed;
@property (nonatomic, retain) NSMutableArray *notPulled;
@property (nonatomic, retain) NSString *projectPath;

- (id) initTrackerForProject:(NSString*)path withPeriod:(int)secs;
- (void) setBranchUpdatedSelector:(SEL)sel;
- (void) setBranchUpdatedTarget:(id)target;

- (IBAction) startMonitoring:(id)sender;
- (IBAction) stopMonitoring:(id)sender wait:(BOOL)wait;

- (BOOL) isRunning;

@end
