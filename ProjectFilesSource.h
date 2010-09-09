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

//static array of group names (keys) 
//in [self data] containing arrays of files in groups
+ (NSArray*) dataKeys;

@property (retain, readonly) NSMutableDictionary* data;

- (void)loadProjectData:(NSDictionary*)pData forPath:(NSString*)p;
- (NSString *)fileAtIndex:(int)index;
- (NSString *)fileAtIndex:(int)index inGroup:(NSString**)grp groupIndexOffset:(int*)offset;

- (void)addFile:(NSString*)file toGroup:(NSString*)group;
- (void)removeFile:(NSString*)file fromGroup:(NSString*)group;

- (void) copyFilesFrom:(ProjectFilesSource *)source;

@end
