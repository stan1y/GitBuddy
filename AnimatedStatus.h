//
//  AnimatedStatus.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 25/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AnimatedStatus : NSObject {
	NSImage *stage1;
	NSImage *stage2;
	NSImage *stage3;
	
	NSThread *thread;
	double period;
}

- (id) initWithPeriod:(double)secs;

- (void) startAnimation;
- (void) stopAnimation;

@end
