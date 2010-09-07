//
//  GitWrapper.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitWrapper.h"
#import "GitWrapperCommand.h"

@implementation GitWrapper

- (id) init
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	wrapperPath = [[NSBundle mainBundle] pathForResource:@"wrapper" ofType:@"py"];
	[wrapperPath retain];
	NSLog(@"Git wrapper at %@", wrapperPath);
	
	return self;
}

- (void) executeGit:(NSArray *)args withCompletionBlock:(void (^)(NSDictionary*))codeBlock
{
	GitWrapperCommand *cmd = [GitWrapperCommand gitCommand:wrapperPath withArgs:args];
	[cmd setCompletionBlock: ^{
		codeBlock([cmd jsonResult]);
	}];
	[[[NSApp delegate] queue] addOperation:cmd];
	[cmd release];
}

@end
