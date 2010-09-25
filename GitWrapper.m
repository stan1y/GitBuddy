//
//  GitWrapper.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "GitWrapper.h"
#import "GitWrapperCommand.h"
#import "GitBuddy.h"

@implementation GitWrapper

//	- Singleton

static GitWrapper *_sharedGitWrapper = nil;

//	- Initialization

- (void) dealloc
{
	[queue release];
	[wrapperPath release];
	
	[super dealloc];
}

- (GitWrapper*) _init
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	queue = [[NSOperationQueue alloc] init];
	wrapperPath = [[NSBundle mainBundle] pathForResource:@"wrapper" ofType:@"py"];
	[wrapperPath retain];
	NSLog(@"Git wrapper at %@", wrapperPath);
	
	return self;
}

+ (GitWrapper*) sharedInstance
{
	if ( !_sharedGitWrapper ) {
		_sharedGitWrapper =  [[GitWrapper alloc] _init];
	}
	
	return _sharedGitWrapper;
}

- (GitWrapper*) init
{
	return [[GitWrapper sharedInstance] retain];
}

- (void) executeGit:(NSArray *)args withCompletionBlock:(void (^)(NSDictionary*))codeBlock
{
	int tsecs = [[NSUserDefaults standardUserDefaults] integerForKey:@"gitTimeout"];
	[self executeGit:args timeoutAfter:tsecs withCompletionBlock:codeBlock];
}

- (void) executeGit:(NSArray *)args timeoutAfter:(int)tsecs withCompletionBlock:(void (^)(NSDictionary*))codeBlock
{
	/*
	GitWrapperCommand *cmd = [[GitWrapperCommand alloc] initWith:wrapperPath withArgs:args andTimeout:tsecs];
	
	[cmd setCompletionBlock: ^{
		codeBlock([cmd jsonResult]);
	}];
	
	[queue addOperation:cmd];
	[cmd release];
	 */
	
	[queue addOperationWithBlock:^{
		GitWrapperCommand *cmd = [[GitWrapperCommand alloc] initWith:wrapperPath withArgs:args andTimeout:tsecs];
		[cmd main];
		id result = [cmd jsonResult];
		if (result) {
			codeBlock(result);
		}
		
		[cmd release];
	}];
}

@end
