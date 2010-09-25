//
//  ChangeSetViewer.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 5/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "ChangeSetViewer.h"


@implementation ChangeSetViewer

@synthesize original, changed, projectPath;

- (void) dealloc
{
	[original release];
	[changed release];
	[projectPath release];
	
	[super dealloc];
}

+ viewModified:(NSString *)original diffTo:(NSString *)changed project:(NSString*)project
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:original];
	[viewer setChanged:changed];
	[viewer setProjectPath:project];
	return viewer;
}

+ viewAdded:(NSString *)added project:(NSString*)project
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:@"/dev/null"];
	[viewer setChanged:added];
	[viewer setProjectPath:project];
	return viewer;
}

+ viewRemoved:(NSString *)removed project:(NSString*)project
{
	ChangeSetViewer * viewer = [[ChangeSetViewer alloc] init];
	[viewer setOriginal:removed];
	[viewer setChanged:@"/dev/null"];
	[viewer setProjectPath:project];
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
	[diffTask setCurrentDirectoryPath:[self projectPath]];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL useDiffTool = [defaults boolForKey:@"useOpenDiff"];
	if (useDiffTool) {
		
		//check opendiff available
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:@"/Developer/Applications/Utilities/FileMerge.app/Contents/MacOS/FileMerge"]) {
			//FIXME: open prefs window
			NSRunAlertPanel(@"X Code FileMerge tool not found.", @"Please specify custom diff & merge viewer in Git preferences, or install XCode from a Developer CD or download it from www.apple.com", @"Continue", nil, nil);
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
	
	NSLog(@"Launch external diff viewer: %@ %@", [diffTask launchPath], [[diffTask arguments] componentsJoinedByString:@" "]);
	
	[diffTask launch];
	[diffTask waitUntilExit];
	
	NSLog(@"External diff viewer quited.");
	
	[diffTask release];
}

@end
