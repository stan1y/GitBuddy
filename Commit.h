//
//  Commit.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 9/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectFilesSource.h"

@interface Commit : NSWindowController {
	
	NSTableView *filesView;
	ProjectFilesSource *stagedSource;
	NSTextField *commitMessage;
	NSString *projectPath;
	NSButton *previewBtn;
	
	NSString *selectedFile;
}

- (void) commitProject:(NSDictionary*)proj atPath:(NSString*)path;

@property (retain) NSString *projectPath;
@property (retain) NSString *selectedFile;

//assigned from nib
@property (assign) IBOutlet NSButton *previewBtn;
@property (assign) IBOutlet NSTableView *filesView;
@property (assign) IBOutlet NSTextField *commitMessage;
@property (assign) IBOutlet ProjectFilesSource *stagedSource;

- (IBAction) fileSelected:(id)sender;
- (IBAction) showPreview:(id)sender;
- (IBAction) commit:(id)sender;

@end
