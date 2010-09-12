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

+ (GitWrapper*) sharedInstance;
- (void) executeGit:(NSArray *)args timeoutAfter:(int)tsecs withCompletionBlock:(void (^)(NSDictionary*))codeBlock;
- (void) executeGit:(NSArray *)args withCompletionBlock:(void (^)(NSDictionary*))codeBlock;

@end
