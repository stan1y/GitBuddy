//
//  Preview.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ChangesSource.h"

@interface Preview : NSWindowController<NSTabViewDelegate> {
	ChangesSource *changesSource;
}

//assigned from nib
@property (assign) IBOutlet ChangesSource *changesSource;

//load preview of file
- (void) loadPreviewOf:(NSString *)file inPath:(NSString*)path;

//table view highligth
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end
