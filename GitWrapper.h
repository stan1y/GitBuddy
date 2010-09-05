//
//  GitWrapper.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSON.h"

@interface GitWrapper : NSObject {
	NSString * wrapperPath;
	NSString * gitPath;
	SBJsonParser *parser;
	int timeout;
}

- (id) getCommandJson:(NSArray *)args;
- (NSDictionary *) getChanges:(NSString *)path;
- (NSDictionary *) getBranches:(NSString *)path;
- (NSDictionary *) getRemote:(NSString *)path;

@end
