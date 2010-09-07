//
//  ProjectBuddy.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GitWrapper.h"
#import "ChangeSetViewer.h"

/*

 About
 Preferences
 Add Git Repo
 ------
 /Path/to/project (3) ->	Remove path
 Exit						Rescan path
							On Branch	->	[master, Add New Branch...]
							Remote		->	[origin, Add New Remote...]
							Changes		->	Reset
							Commit			Stage changes
											Move to new branch...
											--------------
											/Path/to/file1	+10, -3
											/Path/to/file2	+1, -5
											/Path/to/file3	+5, -45
 */

#define CNG_MENU_RESET 0 // index of reset changes menu item
#define CNG_MENU_STAGE 1 // index of stage changes menu item
#define CNG_MENU_MVBRANCH 2 // index of move to branch item
#define CNG_MENU_SEP 3 // index of separator
#define CNG_MENU_ITEMS 4 // number of items in changes menu initially

@interface ProjectBuddy : NSObject<NSMenuDelegate> {
	NSMenuItem * parentItem;
	
	NSMenu * projectMenu;
	NSMenu * onBranchMenu;
	NSMenu * remoteMenu;
	NSMenu * changesMenu;
	
	NSString * path;
	NSString * title;
	
	NSString * currentBranch;
	NSMutableDictionary * itemDict;
	GitWrapper *wrapper;
	NSLock * wrapperLock;
}

@property (nonatomic, retain) NSMutableDictionary * itemDict;
@property (nonatomic, retain) NSString * currentBranch;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSMenuItem * parentItem;

- (id) initBuddy:(NSMenuItem *)anItem forPath:(NSString *)aPath withTitle:(NSString *)aTitle;
- (int) totalChangedFiles;
- (void) mergeData:(NSDictionary *)dict;
- (void) rebuildMenu;

//	Menu delegate
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel;
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu;

// Selectors

- (IBAction) removePath:(id)sender;
- (IBAction) rescan:(id)sender;
- (IBAction) commit:(id)sender;

- (IBAction) switchToBranch:(id)sender;
- (IBAction) newBranch:(id)sender;

- (IBAction) switchToSource:(id)sender;
- (IBAction) newSource:(id)sender;

- (IBAction) resetChanges:(id)sender;
- (IBAction) stageChanges:(id)sender;
- (IBAction) moveChangesToNewBranch:(id)sender;

- (IBAction) showChanges:(id)sender;

@end
