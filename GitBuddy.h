//
//  GitBuddy.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectBuddy.h"

@interface GitBuddy : NSObject <NSApplicationDelegate, NSMenuDelegate> {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	NSImage *statusImage;
	NSImage *statusAltImage;
	
	NSNumber* lastEventId;
    FSEventStreamRef stream;
	
	NSPanel *addPathPanel;
	NSTextField *addPathField;
}

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
- (IBAction) pushClicked:(id)sender;
- (IBAction) stageChangesClicked:(id)sender;
- (IBAction) moveToBranchChangesClicked:(id)sender;
- (IBAction) showChangeSet:(id)sender;
- (IBAction) removePath:(id)sender;
- (IBAction) showGitManual:(id)sender;

@end
