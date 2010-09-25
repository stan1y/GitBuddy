//
//  Preview.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DiffViewSource.h"

@interface Preview : NSWindowController<NSTabViewDelegate> {
	DiffViewSource *changesSource;
	
	NSString *filePath;
	NSString *projectPath;
}

@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *projectPath;

//assigned from nib
@property (assign) IBOutlet DiffViewSource *changesSource;

//load preview of file
- (void) loadPreviewOf:(NSString *)file inPath:(NSString*)path;

//load preview of changeset
- (void) loadChangeSetOf:(NSString *)file inPath:(NSString*)path;

//table view highligth
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

- (IBAction) showInExternalViewer:(id)sender;
- (IBAction) resetChanges:(id)sender;

@end
