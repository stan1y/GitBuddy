//
//  CommitsLog.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 22/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommitsSource.h"

@interface CommitsLog : NSWindowController<NSTableViewDataSource, NSTableViewDelegate> {
	NSString *projectRoot;
	NSString *currentPath;
		
	NSTextField *folder;
	NSButton *parentFolder;
	
	NSTableView *filesTableView;
	CommitsSource *commitSource;
	NSString *selectedFile;
}

@property (assign) IBOutlet NSTextField *folder;
@property (assign) IBOutlet NSButton *parentFolder;
@property (assign) IBOutlet CommitsSource *commitSource;
@property (assign) IBOutlet NSTableView *filesTableView;

@property (nonatomic, retain) NSString *projectRoot;
@property (nonatomic, retain) NSString *selectedFile;
@property (nonatomic, retain, readonly) NSString *currentPath;

- (void) initForProject:(NSString*)project;
- (void) fileDoubleClicked;
- (IBAction) goToParentFolder:(id)sender;
- (IBAction) revertToRevision:(id)sender;
- (NSArray*) currentFolderFiles;

@end
