//
//  ChangeSetViewer.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 5/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChangeSetViewer : NSOperation {
	NSString * original;
	NSString * changed;
	NSString * projectPath;
}

@property (nonatomic, retain) NSString * projectPath;
@property (nonatomic, retain) NSString * original;
@property (nonatomic, retain) NSString * changed;

- (void) main;

// original is a path to file that before edit
// compared to file in current state
+ viewModified:(NSString *)original diffTo:(NSString *)changed project:(NSString*)project;

// added is a path to file that was added
// compared with /dev/null
+ viewAdded:(NSString *)added project:(NSString*)project;

// removed is a path to file that was removed
// compared with /dev/null
+ viewRemoved:(NSString *)removed project:(NSString*)project;

@end