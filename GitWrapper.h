//
//  GitWrapper.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GitWrapper : NSObject {
	NSString * wrapperPath;
	NSString * gitPath;
	int timeout;
}

- (void) executeGit:(NSArray *)args withCompletionBlock:(void (^)(NSDictionary*))codeBlock;

@end
