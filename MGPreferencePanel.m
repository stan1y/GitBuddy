//
//  MGPreferencePanel.m
//  MGPreferencePanel
//
//  Created by Michael on 29.03.10.
//  Copyright 2010 MOApp Software Manufactory. All rights reserved.
//


#define WINDOW_TOOLBAR_HEIGHT 78

#import "MGPreferencePanel.h"

// Default panes

NSString * const gitSettingsIdentifier = @"Git Settings";
NSString * const gitSettingsIcon = @"GitSettingsIcon";

NSString * const monitoringIdentifier = @"Monitoring";
NSString * const monitoringIcon = @"MonitoringIcon";

NSString * const updatesIdentifier = @"Updates";
NSString * const updatesIcon = @"UpdatesIcon";

NSString * const keysIdentifier = @"Global Keys";
NSString * const keysIcon = @"GlobalKeysIcon";



@implementation MGPreferencePanel

-(id) init
{
	if( self = [super init] )
	{
		//
	}	
	return self;
}


-(void)	dealloc
{
	[super dealloc];
}



-(void)	awakeFromNib
{
	[self mapViewsToToolbar];
	[self firstPane];
	[window center];
}


-(void) mapViewsToToolbar
{
	// Application title
	NSString *app = @"GitBuddy";
	
    NSToolbar *toolbar = [window toolbar];
	if(toolbar == nil)  
	{
		toolbar = [[[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.mgpreferencepanel.toolbar", app]] autorelease];
	}
	
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
    [toolbar setDelegate: self]; // 10.4 - otherwise use <NSToolbarDelegate>
    [window setToolbar: toolbar];	
	[window setTitle: NSLocalizedString(@"Git Settings", @"")];
	
	if([toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)])
	{
		[toolbar setSelectedItemIdentifier: gitSettingsIdentifier];
	}
}

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
			gitSettingsIdentifier,
			monitoringIdentifier,
			updatesIdentifier,
			keysIdentifier,	
			nil];
}


-(IBAction) changePanes: (id)sender
{
	NSView *view = nil;
	
	switch ([sender tag]) 
	{
		case 0:
			[window setTitle: NSLocalizedString(@"Git Settings", @"")];
			view = git;
			break;
		case 1:
			[window setTitle: NSLocalizedString(@"Monitoring", @"")];
			view = monitoring;
			break;
		case 2:
			[window setTitle: NSLocalizedString(@"Updates", @"")];
			view = updates;
			break;
		case 3:
			[window setTitle: NSLocalizedString(@"Global Keys", @"")];
			view = keys;
			break;
		default:
			break;
	}
	
	NSRect windowFrame = [window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	[window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}


-(void) firstPane
{
	NSView *view = nil;
	view = git;
	
	NSRect windowFrame = [window frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([window frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0)
	{
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	[window setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
			gitSettingsIdentifier,
			monitoringIdentifier,
			updatesIdentifier,
			keysIdentifier,	
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
			gitSettingsIdentifier,
			monitoringIdentifier,
			updatesIdentifier,
			keysIdentifier,		
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			nil];
}





- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar;
{
	NSToolbarItem *item = nil;
	
    if ([itemIdentifier isEqualToString:gitSettingsIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:NSLocalizedString(@"Git Settings", @"")];
        [item setLabel:NSLocalizedString(@"Git Settings", @"")];
        [item setImage:[NSImage imageNamed:gitSettingsIcon]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:0];
    }
	else if ([itemIdentifier isEqualToString:monitoringIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:NSLocalizedString(@"Monitoring", @"")];
        [item setLabel:NSLocalizedString(@"Monitoring", @"")];
        [item setImage:[NSImage imageNamed:monitoringIcon]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:1];
    }
	else if ([itemIdentifier isEqualToString:updatesIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:NSLocalizedString(@"Updates", @"")];
        [item setLabel:NSLocalizedString(@"Updates", @"")];
        [item setImage:[NSImage imageNamed:updatesIcon]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:2];
    }
	else if ([itemIdentifier isEqualToString:keysIdentifier]) {
		
        item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [item setPaletteLabel:NSLocalizedString(@"Global Keys", @"")];
        [item setLabel:NSLocalizedString(@"Global Keys", @"")];
        [item setImage:[NSImage imageNamed:keysIcon]];
		[item setAction:@selector(changePanes:)];
        [item setToolTip:NSLocalizedString(@"", @"")];
		[item setTag:3];
    }
	return [item autorelease];
}



@end
