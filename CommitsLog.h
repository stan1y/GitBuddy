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
	
	CommitsSource *commitSource;
}

@property (assign) IBOutlet NSTextField *folder;
@property (assign) IBOutlet NSButton *parentFolder;
@property (assign) IBOutlet CommitsSource *commitSource;

@property (nonatomic, retain) NSString *projectRoot;
@property (nonatomic, retain, readonly) NSString *currentPath;

- (void) initForProject:(NSString*)project;

@end
