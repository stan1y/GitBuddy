//
//  DiffViewSource.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//	Class implements table view source with
//	diff contents either from:
//	 * git diff /repo/file/path
//	 * git diff --cache /repo/file/path

@interface DiffViewSource :  NSObject<NSTableViewDataSource> {
	NSDictionary *currentSource;
	NSMutableDictionary *gitObjectsIndex;
	NSTableView *tableView;
	NSProgressIndicator *indicator;
}

//assigned from nib
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSProgressIndicator *indicator;
@property (retain, readonly) NSMutableDictionary *gitObjectsIndex;

@property (retain) NSDictionary *currentSource;

- (void) rebuildIndex:(NSString *)projectPath withCompletionBlock:(void (^)(void))codeBlock;
+ (void) externalDiffViewer:(NSString*)modified withOriginal:(NSString*)original project:(NSString*)project;
- (void) updateWithFileDiff:(NSString *)filePath inPath:(NSString *)projectPath;
- (void) updateWithCachedFileDiff:(NSString *)filePath inPath:(NSString *)projectPath;
- (void) updateWithCommitDiff:(NSString *)filePath commitId:(NSString*)commitId inPath:(NSString *)projectPath;

- (NSString *) stringAtIndex:(int)index;
@end
