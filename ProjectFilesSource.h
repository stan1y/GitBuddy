//
//  ProjectFilesSource.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// Class is a datasource protocol implementation
// for tableview, in order to support drag & drop of
// changes in "Stage Files" panel

@interface ProjectFilesSource : NSObject<NSTableViewDataSource> {
	NSMutableDictionary* data;
	NSString * path;
}

- (void)loadProjectData:(NSDictionary*)pData forPath:(NSString*)p;
- (NSString *)fileAtIndex:(int)index;
- (NSString *)fileAtIndex:(int)index inGroup:(NSString**)grp groupIndexOffset:(int*)offset;

- (void)addFile:(NSString*)file toGroup:(NSString*)group;
- (void)removeFile:(NSString*)file fromGroup:(NSString*)group;

@end
