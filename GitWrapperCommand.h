//
//  GitWrapperCommand.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 6/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSON.h"

@interface GitWrapperCommand : NSOperation {
	NSTask *gitWrapper;
	NSPipe *stdoutPipe;
	NSPipe *stderrPipe;
	
	int timeout;
	NSDictionary * jsonResult;
	SBJsonParser *parser;
}

@property (assign) int timeout;
@property (nonatomic, retain, readonly) NSTask *gitWrapper;
@property (assign, readonly) NSDictionary * jsonResult;
- (id) initWith:(NSString*)wrapperPath withArgs:(NSArray *)args andTimeout:(int)tsecs;

@end
