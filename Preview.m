//
//  Preview.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Preview.h"
#import "Highlight.h"

@implementation Preview

@synthesize changesSource;

- (void) loadPreviewOf:(NSString *)file inPath:(NSString*)path
{
	[[self window] setTitle:[NSString stringWithFormat:@"Preview of %@", [path stringByAppendingPathComponent:file]]];
	[changesSource updateWithFileDiff:file inPath:path];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *str = [changesSource stringAtIndex:rowIndex];
	[Highlight highLightCell:aCell forLine:str];
}

@end
