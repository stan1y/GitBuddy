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

@interface GitBuddy : NSObject <NSApplicationDelegate, NSMenuDelegate> {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	
	NSImage *statusImage;
	NSImage *statusAltImage;
	
	double minimalUpdateTimeSec;
	double lastUpdatedSec;
	NSNumber* lastEventId;
    FSEventStreamRef stream;
	
	NSPanel *addRepoPanel;
	NSTextField *addRepoField;
	NSOperationQueue *queue;
	
	NSLock *eventsLock;
	NSArray *queuedEvents;
	NSMutableDictionary *projCounters;
	
	FilesStager *filesStager;
	Preview *preview;
}

//assigned from nib
@property (assign) IBOutlet FilesStager *filesStager;
@property (assign) IBOutlet Preview *preview;

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (assign) IBOutlet NSTextField *addRepoField;
@property (assign) IBOutlet NSPanel *addRepoPanel;

- (void) initializeEventForPaths:(NSArray *)pathsToWatch;
- (NSMenuItem *) menuItemForPath:(NSString *)path;
- (NSMenuItem *) newMenuItem:(NSString *)title withPath:(NSString *)path;
- (BOOL) addMonitoredPath:(NSString *)path;
- (NSArray *) monitoredPathsArray;

- (void) scanUpdatesAtPaths:(NSArray *)paths;

- (IBAction) browseForRepo:(id)sender;
- (IBAction) addRepo:(id)sender;
- (IBAction) showGitManual:(id)sender;
- (IBAction) checkUpdates:(id)sender;
- (IBAction) rescanRepos:(id)sender;

//projects counters
- (void) setCounter:(int)changed forProject:(NSString*)path;

@end

//get current time in seconds
double now_seconds();
