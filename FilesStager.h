//
//  FilesStager.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectFilesSource.h"
#import "ChangesSource.h"

@interface FilesStager : NSWindowController<NSTableViewDelegate> {
	ProjectFilesSource *stagedSource;
	ProjectFilesSource *unstagedSource;
	ChangesSource *changesSource;
	NSDictionary *project;
	
	NSTableView *stagedView;
	NSTableView *unstagedView;
	
	
}

//assigned from nib
@property (assign) IBOutlet NSTextField *title;
@property (assign) IBOutlet ChangesSource *changesSource;
@property (assign) IBOutlet ProjectFilesSource *stagedSource;
@property (assign) IBOutlet ProjectFilesSource *unstagedSource;
@property (assign) IBOutlet NSTableView *stagedView;
@property (assign) IBOutlet NSTableView *unstagedView;

- (void) setProject:(NSDictionary *)dict;

//table view selection
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex;

//table view hightligth
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

@end