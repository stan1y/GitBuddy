//
//  MGPreferencePanel.h
//  MGPreferencePanel
//
//  Created by Michael on 29.03.10.
//  Copyright 2010 MOApp Software Manufactory. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface MGPreferencePanel : NSObject <NSToolbarDelegate>
{	
	IBOutlet NSView *git;
	IBOutlet NSView *monitoring;
	IBOutlet NSView *updates;
	IBOutlet NSView *keys;	
	IBOutlet NSView *contentView;
	IBOutlet NSWindow *window;
}

@property (readonly, retain) NSWindow *window;

-(void) mapViewsToToolbar;
-(void) firstPane;
-(IBAction) changePanes: (id)sender;

@end
