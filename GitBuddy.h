//
//  GitBuddy.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectBuddy.h"
#import "FilesStager.h"
#import "Preview.h"
#import "Commit.h"
#import "Clone.h"

@interface GitBuddy : NSObject <NSApplicationDelegate, NSMenuDelegate> {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	
	NSImage *statusImage;
	NSImage *statusAltImage;
	
	double eventsRescanDelay;
	double lastUpdatedSec;
	unsigned long long lastEventId;
    FSEventStreamRef stream;
	
	NSPanel *addRepoPanel;
	NSTextField *addRepoField;
	NSOperationQueue *queue;
	
	NSThread *eventsThread;
	NSLock *eventsLock;
	NSArray *queuedEvents;
	NSMutableDictionary *projCounters;
	
	FilesStager *filesStager;
	Preview *preview;
	Commit *commit;
	Clone *clone;
	
	NSPanel *operationPanel;
	NSTextField *operationDescription;
	NSProgressIndicator *operationIndicator;
	
	NSPanel *newBranchPanel;
	NSTextField *newBranchName;
	ProjectBuddy *newBranchProject;
	
	NSPanel *newRemotePanel;
	NSTextField *newRemoteName;
	NSTextField *newRemoteURL;
	ProjectBuddy *newRemoteProject;
	
	NSMenuItem *activeProject;
}

//Events thread implementation
- (void) processEvents;

- (void) setActiveProjectByPath:(NSString*)path;
- (ProjectBuddy*) getActiveProjectBuddy;

//assigned from nib
@property (assign) IBOutlet Clone *clone;
@property (assign) IBOutlet FilesStager *filesStager;
@property (assign) IBOutlet Preview *preview;
@property (assign) IBOutlet Commit *commit;

@property (assign) IBOutlet NSPanel *operationPanel;
@property (assign) IBOutlet NSTextField *operationDescription;
@property (assign) IBOutlet NSProgressIndicator *operationIndicator;

@property (assign) IBOutlet NSPanel *newBranchPanel;
@property (assign) IBOutlet NSTextField *newBranchName;

@property (assign) IBOutlet NSPanel *newRemotePanel;
@property (assign) IBOutlet NSTextField *newRemoteURL;
@property (assign) IBOutlet NSTextField *newRemoteName;

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (assign) IBOutlet NSTextField *addRepoField;
@property (assign) IBOutlet NSPanel *addRepoPanel;

- (void) initializeEventForPaths:(NSArray *)pathsToWatch;
- (NSMenuItem *) menuItemForPath:(NSString *)path;
- (NSMenuItem *) newMenuItem:(NSString *)title withPath:(NSString *)path;
- (BOOL) addMonitoredPath:(NSString *)path;
- (NSArray *) monitoredPathsArray;

- (void) scanFsEventsAtPaths:(NSArray *)paths;

- (IBAction) browseForRepo:(id)sender;
- (IBAction) addRepo:(id)sender;
- (IBAction) showGitManual:(id)sender;
- (IBAction) checkUpdates:(id)sender;

- (void) createBranchFor:(ProjectBuddy*)buddy;
- (void) createRemoteFor:(ProjectBuddy*)buddy;

- (IBAction) createBranch:(id)sender;
- (IBAction) createRemote:(id)sender;

- (void) startOperation:(NSString*)description;
- (void) finishOperation;

//projects counters
- (void) setCounter:(int)changed forProject:(NSString*)path;

@end

//get current time in seconds
double now_seconds();
