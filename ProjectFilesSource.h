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
- (id)fileAtIndex:(int)index;
- (id)fileAtIndex:(int)index inGroupIndex:(int*)grpIndex;

@end
