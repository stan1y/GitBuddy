//
//  GitBuddy.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import "MGPreferencePanel.h"
#import "ProjectBuddy.h"
#import "FilesStager.h"
#import "Preview.h"
#import "Commit.h"
#import "Clone.h"
#import "CommitsLog.h"
#import "AnimatedStatus.h"

@interface GitBuddy : NSObject <NSApplicationDelegate, NSMenuDelegate, GrowlApplicationBridgeDelegate> {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	
	NSImage *currentImage;
	NSImage *statusImage;
	NSImage *statusAltImage;
	
	double eventsRescanDelay;
	double lastUpdatedSec;
	unsigned long long lastEventId;
    FSEventStreamRef stream;
	
	NSPanel *addRepoPanel;
	NSTextField *addRepoField;
	
	NSThread *eventsThread;
	NSLock *eventsLock;
	NSArray *queuedEvents;
	
	MGPreferencePanel *preferences;
	
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
	
	NSPanel *commitsLogPanel;
	CommitsLog *commitsLog;
	
	NSMenuItem *activeProject;
	
	NSTextField *lastUpdatedOn;
	NSTextField *appVersion;
	id updater;
	
	NSMutableDictionary *statusCounters;
	AnimatedStatus *animStatus;
	
	NSWindow *aboutWnd;
}

//Events thread implementation
- (void) processEvents;
- (void) processEventsNow;

- (void) setActiveProjectByPath:(NSString*)path;
- (ProjectBuddy*) getActiveProjectBuddy;

//assigned from nib
@property (assign) IBOutlet NSWindow *aboutWnd;
@property (assign) IBOutlet MGPreferencePanel *preferences;
@property (assign) IBOutlet id updater;
@property (assign) IBOutlet NSTextField *lastUpdatedOn;
@property (assign) IBOutlet NSTextField *appVersion;
@property (assign) IBOutlet CommitsLog *commitsLog;
@property (assign) IBOutlet Clone *clone;
@property (assign) IBOutlet FilesStager *filesStager;
@property (assign) IBOutlet Preview *preview;
@property (assign) IBOutlet Commit *commit;

@property (assign) IBOutlet NSPanel *commitsLogPanel;
@property (assign) IBOutlet NSPanel *operationPanel;
@property (assign) IBOutlet NSTextField *operationDescription;
@property (assign) IBOutlet NSProgressIndicator *operationIndicator;

@property (assign) IBOutlet NSPanel *newBranchPanel;
@property (assign) IBOutlet NSTextField *newBranchName;

@property (assign) IBOutlet NSPanel *newRemotePanel;
@property (assign) IBOutlet NSTextField *newRemoteURL;
@property (assign) IBOutlet NSTextField *newRemoteName;

@property (assign) IBOutlet NSTextField *addRepoField;
@property (assign) IBOutlet NSPanel *addRepoPanel;

- (void) initializeEventForPaths:(NSArray *)pathsToWatch;
- (NSMenuItem *) menuItemForPath:(NSString *)path;
- (NSMenuItem *) newMenuItem:(NSString *)title withPath:(NSString *)path;
- (BOOL) addMonitoredPath:(NSString *)path;
- (NSArray *) monitoredPathsArray;

- (void) appendEventPaths:(NSArray *)paths;

- (IBAction) browseForRepo:(id)sender;
- (IBAction) addRepo:(id)sender;
- (IBAction) showGitManual:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;

- (void) createBranchFor:(ProjectBuddy*)buddy;
- (void) createRemoteFor:(ProjectBuddy*)buddy;

- (IBAction) createBranch:(id)sender;
- (IBAction) createRemote:(id)sender;

- (void) startOperation:(NSString*)description;
- (void) finishOperation;

//rescan
- (void) rescanAll;
- (void) rescanRepoAtPath:(NSString*)path;

//projects counters
- (void) updateCounters:(NSDictionary*)data;

//status icon
- (void) setStatusImage:(NSImage*)image;
- (void) setCurrentImage;
@end

//get current time in seconds
double now_seconds();
