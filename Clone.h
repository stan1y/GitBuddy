//
//  Clone.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 10/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum RepoProtocolType {
	SshType,
	HttpType
};

@interface Clone : NSWindowController<NSControlTextEditingDelegate> {
	NSTextField *repoUrl;
	NSTextField *repoLocalPath;
	NSButton *sshBtn;
	NSButton *httpBtn;
	NSButton *cloneBtn;
	
	int repoType;
}

//assigned from nib
@property (assign) IBOutlet NSButton *cloneBtn;
@property (assign) IBOutlet NSButton *sshBtn;
@property (assign) IBOutlet NSButton *httpBtn;
@property (assign) IBOutlet NSTextField *repoUrl;
@property (assign) IBOutlet NSTextField *repoLocalPath;

- (IBAction) toggleRepoType:(id)sender;
- (IBAction) browseForLocalPath:(id)sender;
- (IBAction) cloneRepo:(id)sender;


@end
