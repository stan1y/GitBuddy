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

@interface FilesStager : NSWindowController<NSTableViewDelegate, NSWindowDelegate> {
	ProjectFilesSource *stagedSource;
	ProjectFilesSource *unstagedSource;
	ChangesSource *changesSource;
	NSDictionary *project;
	
	NSTableView *stagedView;
	NSTableView *unstagedView;
	
	BOOL checkOnClose;
}

//assigned from nib
@property (assign) IBOutlet NSTextField *title;
@property (assign) IBOutlet ChangesSource *changesSource;
@property (assign) IBOutlet ProjectFilesSource *stagedSource;
@property (assign) IBOutlet ProjectFilesSource *unstagedSource;
@property (assign) IBOutlet NSTableView *stagedView;
@property (assign) IBOutlet NSTableView *unstagedView;

//callbacks
- (IBAction) stageFiles:(id)sender;
- (IBAction) stageAndCommitFiles:(id)sender;

//modifications
- (NSDictionary *) filesToUnStage;
- (NSDictionary *) filesToStage;

//initialize with project
- (void) setProject:(NSDictionary *)dict stageAll:(BOOL)stage;

//table view selection
- (BOOL) tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex;

//table view hightligth
- (void) tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

//file stager window delegate
- (BOOL) windowShouldClose:(id)sender;

@end
