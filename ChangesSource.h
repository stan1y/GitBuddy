//
//  ChangesSource.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//	Class implements table view source with
//	diff contents either from:
//	 * git show KEY
//	 * git diff /repo/file/path
@interface ChangesSource :  NSObject<NSTableViewDataSource> {
	NSMutableDictionary *gitObjectsIndex;
	NSDictionary *currentSource;
	
	NSTableView *tableView;
	NSProgressIndicator *indicator;
}

//assigned from nib
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSProgressIndicator *indicator;
@property (retain, readonly) NSMutableDictionary *gitObjectsIndex;
- (void) rebuildIndex:(NSString *)projectPath withCompletionBlock:(void (^)(void))codeBlock;

- (void) updateWithChangeset:(NSString *)filePath inPath:(NSString *)projectPath;
- (void) updateWithFileDiff:(NSString *)filePath inPath:(NSString *)projectPath;

- (NSString *) stringAtIndex:(int)index;
@end
