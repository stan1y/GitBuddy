//
//  NewBranch.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 1/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NewBranch : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
	NSTableView *sourcesForBranch;
	
	NSString *projectOfBranch;
	NSArray *projectSources;
	
	NSString *selectedSource;
	NSButton *pushBtn;
}

@property (assign) IBOutlet NSTableView *sourcesForBranch;
@property (assign) IBOutlet NSButton *pushBtn;

@property (nonatomic, retain) NSArray *projectSources;
@property (nonatomic, retain) NSString *projectOfBranch;
@property (nonatomic, retain) NSString *selectedSource;

- (void) showNewBranchOf:(NSString*)project withSources:(NSArray*)sources;

- (IBAction) createNewBranch:(id)sender;
- (IBAction) createNewSource:(id)sender;

@end
