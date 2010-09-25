//
//  AnimatedStatus.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 25/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "AnimatedStatus.h"
#import "time.h"

@implementation AnimatedStatus

- (void) dealloc
{
	[stage1 release];
	[stage2 release];
	[stage3 release];
	[super dealloc];
}

- (id) initWithPeriod:(double)secs
{
	if (!(self = [super init])) {
		return nil;
	}
	
	stage1 = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy16Progress1" ofType:@"png"]];
	stage2 = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy16Progress2" ofType:@"png"]];
	stage3 = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy16Progress3" ofType:@"png"]];
	
	period = secs;
	return self;
}

- (void) startAnimation
{
	if ( !thread ) {
		NSLog(@"Starting animation...");
		thread = [[NSThread alloc] initWithTarget:self selector:@selector(animateIcon) object:nil];
		[thread start];
	}
}

- (void) stopAnimation
{
	if (thread) {
		[thread cancel];
	}
}

- (void)animateIcon
{
	while (YES) {
		if ([thread isCancelled]) {
			NSLog(@"Exiting animation thread...");
			[[NSApp delegate] performSelectorOnMainThread:@selector(setCurrentImage) withObject:nil waitUntilDone:NO];
			[thread release];
			thread = nil;
			[NSThread exit];
		}
		
		[[NSApp delegate] performSelectorOnMainThread:@selector(setStatusImage:) withObject:stage1 waitUntilDone:NO];
		
		[NSThread sleepForTimeInterval:period];
		
		[[NSApp delegate] performSelectorOnMainThread:@selector(setStatusImage:) withObject:stage2 waitUntilDone:NO];

		[NSThread sleepForTimeInterval:period];
		
		[[NSApp delegate] performSelectorOnMainThread:@selector(setStatusImage:) withObject:stage3 waitUntilDone:NO];

		[NSThread sleepForTimeInterval:period];
	}
}

@end
