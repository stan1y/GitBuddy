//
//  ChangeSetViewer.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 5/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ChangeSetViewer.h"


@implementation ChangeSetViewer

@synthesize original, changed;

+ viewModified:(NSString *)original diffTo:(NSString *)changed
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:original];
	[viewer setChanged:changed];
	return viewer;
}

+ viewAdded:(NSString *)added
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:@"/dev/null"];
	[viewer setChanged:added];
	return viewer;
}

+ viewRemoved:(NSString *)removed
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:removed];
	[viewer setChanged:removed];
	return viewer;
}

- (void) main
{
	NSTask * diffTask = [[NSTask alloc] init];
	NSPipe *stdoutPipe = [[[NSPipe alloc] init] autorelease];
	NSPipe *stderrPipe = [[[NSPipe alloc] init] autorelease];
	[diffTask setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[diffTask setStandardError:stderrPipe];
	[diffTask setStandardOutput:stdoutPipe];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL useDiffTool = [defaults boolForKey:@"useOpenDiff"];
	if (useDiffTool) {
		
		//check opendiff available
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:@"/Developer/Applications/Utilities/FileMerge.app/Contents/MacOS/FileMerge"]) {
			//FIXME: open prefs window
			NSRunAlertPanel(@"X Code FileMerge tool not found.", @"Please specify custom diff & merge viewer in Git preferences, or install X Code from a Developer CD or developer.apple.com", @"Open Preferences", @"Continue", nil);
			return;
		}
		
		NSString * gitPath = [defaults stringForKey:@"gitPath"];
		NSArray * args = [NSArray arrayWithObjects:@"difftool", @"-y", @"-t", @"opendiff", [self changed], nil];

		[diffTask setLaunchPath:gitPath];
		[diffTask setArguments:args];
	}
	else {
		//FIXME: custom viewer
		NSString *customDiffViewer = [defaults stringForKey:@"customDiffViewer"];
		NSMutableArray * args = [NSMutableArray arrayWithArray:[customDiffViewer componentsSeparatedByString:@" "]];
		// change $(original) and $(modified) with actual fd
		for(int i=0; i < [args count]; i++) {
			if ([[args objectAtIndex:i] isEqual:@"$(original)"]) {

			}
			if ([[args objectAtIndex:i] isEqual:@"$(modified)"]) {
				
			}
		}
	}
	
	NSLog(@"view changeset: %@ %@", [diffTask launchPath], [[diffTask arguments] componentsJoinedByString:@" "]);
	
	[diffTask launch];
	[diffTask waitUntilExit];
	[diffTask release];
}

@end
