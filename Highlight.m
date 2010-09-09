//
//  Highlight.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Highlight.h"

static NSDictionary* _charColorsDictionary = nil;

@implementation Highlight

+ (NSDictionary *) charColorsDictionary
{
	if (!_charColorsDictionary) {
		_charColorsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
								 [NSColor greenColor], [NSString stringWithString:@"+"],
								 [NSColor redColor], [NSString stringWithString:@"-"],
								 nil];
	}
	
	return _charColorsDictionary;
}

+ (void) highLightCell:(NSTextFieldCell*)cell forLine:(NSString*)line
{
	//light gray by default
	[cell setTextColor:[NSColor lightGrayColor]];
	
	//color
	if ([line length] > 0) {
		NSString *first = [line substringToIndex:1];
		NSColor *c = [[Highlight charColorsDictionary] objectForKey:first];
		if (c) {
			[cell setTextColor:c];
		}
	}
}
@end
