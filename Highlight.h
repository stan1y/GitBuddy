//
//  Highlight.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Highlight : NSObject {

}

+ (NSDictionary *) charColorsDictionary;

+ (void) highLightCell:(NSTextFieldCell*)cell forLine:(NSString*)line;

@end
