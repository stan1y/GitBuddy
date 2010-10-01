//
//  GitWrapper.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GitWrapper : NSObject {
	NSString * wrapperPath;
	NSString * gitPath;
	int timeout;
	NSOperationQueue *queue;
}

+ (GitWrapper*) sharedInstance;
- (void) executeGit:(NSArray *)args timeoutAfter:(int)tsecs withCompletionBlock:(void (^)(NSDictionary*))codeBlock;
- (void) executeGit:(NSArray *)args withCompletionBlock:(void (^)(NSDictionary*))codeBlock;

- (NSDictionary*) executeGit:(NSArray *)args timeoutAfter:(int)tsecs;
- (NSDictionary*) executeGit:(NSArray *)args;

@end
