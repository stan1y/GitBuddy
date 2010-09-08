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

@interface GitBuddy : NSObject <NSApplicationDelegate, NSMenuDelegate> {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	NSImage *statusImage;
	NSImage *statusAltImage;
	
	double minimalUpdateTimeSec;
	double lastUpdatedSec;
	NSNumber* lastEventId;
    FSEventStreamRef stream;
	
	NSPanel *addPathPanel;
	NSTextField *addPathField;
	NSOperationQueue *queue;
	
	NSLock *eventsLock;
	NSArray *queuedEvents;
	
	FilesStager *filesStager;
}

//assigned from nib
@property (assign) IBOutlet FilesStager *filesStager;

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (assign) IBOutlet NSTextField *addPathField;
@property (assign) IBOutlet NSPanel *addPathPanel;

- (void) initializeEventForPaths:(NSArray *)pathsToWatch;
- (NSMenuItem *) menuItemForPath:(NSString *)path;
- (NSMenuItem *) newMenuItem:(NSString *)title withPath:(NSString *)path;
- (BOOL) addMonitoredPath:(NSString *)path;
- (NSArray *) monitoredPathsArray;

- (void) scanUpdatesAtPaths:(NSArray *)paths;

- (IBAction) browseForPath:(id)sender;
- (IBAction) addPath:(id)sender;
- (IBAction) showGitManual:(id)sender;
- (IBAction) checkUpdates:(id)sender;

@end

//get current time in seconds
double now_seconds();
