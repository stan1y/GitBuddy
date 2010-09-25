//
//  Highlight.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "Highlight.h"

static NSDictionary* _charColorsDictionary = nil;

@implementation Highlight

+ (NSDictionary *) charColorsDictionary
{
	if (!_charColorsDictionary) {
		_charColorsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
								 [NSColor redColor], [NSString stringWithString:@"+"],
								 [NSColor greenColor], [NSString stringWithString:@"-"],
								 nil];
	}
	
	return _charColorsDictionary;
}

+ (void) highLightCell:(NSTextFieldCell*)cell forLine:(NSString*)line
{
	//color
	[cell setTextColor:[NSColor secondarySelectedControlColor]];
	if ([line length] > 0) {
		NSString *first = [line substringToIndex:1];
		NSColor *c = [[Highlight charColorsDictionary] objectForKey:first];
		if (c) {
			[cell setTextColor:c];
		}
	}
}
@end
