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
}

@property (nonatomic, retain) NSString * original;
@property (nonatomic, retain) NSString * changed;

- (void) main;

// original is a path to file that before edit
// compared to file in current state
+ viewModified:(NSString *)original diffTo:(NSString *)changed;

// added is a path to file that was added
// compared with /dev/null
+ viewAdded:(NSString *)added;

// removed is a path to file that was removed
// compared with /dev/null
+ viewRemoved:(NSString *)removed;

@end