//
//  CommitsSource.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 22/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DiffViewSource.h"

@interface CommitsSource : NSObject<NSTableViewDataSource, NSTableViewDelegate> {
	NSArray *commits;
	NSString *sourceFile;
	NSString *projectPath;
	NSTextField *commitMessage;
	NSTableView *tableView;
	NSProgressIndicator *indicator;
	
	DiffViewSource *diffSource;
}

@property (assign) IBOutlet NSTextField *commitMessage;
@property (assign) IBOutlet DiffViewSource *diffSource;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSProgressIndicator *indicator;

@property(nonatomic, retain) NSArray *commits;
@property(nonatomic, retain) NSString *sourceFile;
@property(nonatomic, retain) NSString *projectPath;

- (void) loadCommitsFor:(NSString*)file inProject:(NSString*)project;

@end
