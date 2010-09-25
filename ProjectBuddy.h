//
//  ProjectBuddy.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectSubMenu.h"

@interface ProjectBuddy : NSObject {
	NSMenuItem *parentItem;
	NSMenu *parentMenu;
	NSMenuItem *activate;
	
	NSMenuItem *branch;
	NSMenu *branchMenu;
	ProjectSubMenu *branchSubMenu;
	
	NSMenuItem *remote;
	NSMenu *remoteMenu;
	ProjectSubMenu *remoteSubMenu;
	
	NSMenuItem *changed;
	NSMenu *changedMenu;
	ProjectSubMenu *changedSubMenu;
	
	NSMenuItem *staged;
	NSMenu *stagedMenu;
	ProjectSubMenu *stagedSubMenu;
	
	NSMenuItem *untracked;
	NSMenu *untrackedMenu;
	ProjectSubMenu *untrackedSubMenu;
	
	NSMenuItem *pull;
	NSMenuItem *push;
	NSMenuItem *rescan;
	NSMenuItem *remove;
	NSMenuItem *commitsLog;
	
	NSString * path;
	NSString * title;
	
	NSString * currentBranch;
	
	// Project data dict
	NSMutableDictionary * itemDict;
	NSLock *itemLock;
	
	NSMutableArray * selectedChanges;
}

@property (nonatomic, retain, readonly) NSDictionary * itemDict;
@property (nonatomic, retain) NSString * currentBranch;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSMenuItem * parentItem;

- (id) initBuddy:(NSMenuItem *)anItem forPath:(NSString *)aPath withTitle:(NSString *)aTitle;
- (int) totalChangeSetItems;

- (void) mergeData:(NSDictionary *)dict;
- (void) updateMenuItems;

- (void) rescanWithCompletionBlock:(void (^)(void))codeBlock;

//push commits
- (void) pushToNamedSource:(NSString*)source;

// Selectors
- (IBAction) addFile:(id)sender;
- (IBAction) remove:(id)sender;
- (IBAction) rescan:(id)sender;
- (IBAction) commit:(id)sender;
- (IBAction) push:(id)sender;
- (IBAction) pull:(id)sender;

- (IBAction) switchToBranch:(id)sender;
- (IBAction) newBranch:(id)sender;

- (IBAction) pushToSource:(id)sender;
- (IBAction) newSource:(id)sender;

- (IBAction) stageSelectedFiles:(id)sender;
- (IBAction) stageAll:(id)sender;
- (IBAction) unstageFile:(id)sender;

- (IBAction) commitsLog:(id)sender;

@end
