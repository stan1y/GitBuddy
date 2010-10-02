//
//  GitBuddyAppDelegate.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "GitBuddy.h"
#import "GitWrapper.h"
#import <Carbon/Carbon.h>
#include <time.h>

// initial number of menu items in status menu
#define MENUITEMS 5

@implementation GitBuddy

@synthesize addRepoPanel, addRepoField, newBranch;
@synthesize filesStager, preview, commit, clone;
@synthesize operationPanel, operationDescription, operationIndicator;
@synthesize newRemotePanel, newRemoteName, newRemoteURL;
@synthesize newBranchPanel, newBranchName;
@synthesize commitsLog, commitsLogPanel;
@synthesize lastUpdatedOn, appVersion, updater, preferences, aboutWnd;

- (void) restartAllTrackers
{
	if ([statusMenu numberOfItems] > MENUITEMS) {
		NSArray * items = [[statusMenu itemArray] subarrayWithRange:NSMakeRange(MENUITEMS - 1, [statusMenu numberOfItems] - MENUITEMS)];
		for (NSMenuItem * i in items) {
			ProjectBuddy *pbuddy = [i representedObject];
			[pbuddy restartTracker];
		}
	}
}

//	---	Keyboard Events processing

- (void) processKbdEvent:(NSEvent*)event
{
	ProjectBuddy *pbuddy = [self getActiveProjectBuddy];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* stageFilesKey = [defaults dictionaryForKey:@"stageFilesShortcut"];
	NSDictionary* commitLogKey = [defaults dictionaryForKey:@"commitLogShortcut"]; 
	NSDictionary* rescanKey = [defaults dictionaryForKey:@"rescanShortcut"];
	NSDictionary* addRepoKey = [defaults dictionaryForKey:@"addRepoShortcut"];
	NSDictionary* cloneRepoKey = [defaults dictionaryForKey:@"cloneRepoShortcut"];
	
	NSUInteger flags = [event modifierFlags];
	unsigned short keyCode = [event keyCode];
	
	if ( ([[stageFilesKey valueForKey:@"modifierFlags"] unsignedIntegerValue] == (flags & [[stageFilesKey valueForKey:@"modifierFlags"] unsignedIntegerValue])) && (keyCode == [[stageFilesKey valueForKey:@"keyCode"] unsignedShortValue]) ) {
		if ( !pbuddy ) {
			NSRunAlertPanel(@"GitBuddy cannot Stage Changed Files.", @"There is no Active Project now, so there is no target Repo for your action. Please select Activate in project's menu or create a new Repo.", @"Continue", nil, nil);
			return;
		}
		[pbuddy stageSelectedFiles:nil];
	}
	
	if ( ([[commitLogKey valueForKey:@"modifierFlags"] unsignedIntegerValue] == (flags & [[commitLogKey valueForKey:@"modifierFlags"] unsignedIntegerValue])) && (keyCode == [[commitLogKey valueForKey:@"keyCode"] unsignedShortValue]) ) {
		if ( !pbuddy ) {
			NSRunAlertPanel(@"GitBuddy cannot display Commit Log.", @"There is no Active Project now, so there is no target Repo for your action. Please select Activate in project's menu or create a new Repo.", @"Continue", nil, nil);
			return;
		}
		[pbuddy commitsLog:nil];
	}
	
	if ( ([[rescanKey valueForKey:@"modifierFlags"] unsignedIntegerValue] == (flags & [[rescanKey valueForKey:@"modifierFlags"] unsignedIntegerValue])) && (keyCode == [[rescanKey valueForKey:@"keyCode"] unsignedShortValue]) ) {
		if ( !pbuddy ) {
			NSRunAlertPanel(@"GitBuddy cannot Rescan Project.", @"There is no Active Project now, so there is no target Repo for your action. Please select Activate in project's menu or create a new Repo.", @"Continue", nil, nil);
			return;
		}
		[pbuddy rescan:nil];
	}
	
	if ( ([[addRepoKey valueForKey:@"modifierFlags"] unsignedIntegerValue] == (flags & [[addRepoKey valueForKey:@"modifierFlags"] unsignedIntegerValue])) && (keyCode == [[addRepoKey valueForKey:@"keyCode"] unsignedShortValue]) ) {
		[addRepoPanel orderFront:self];
	}
	
	if ( ([[cloneRepoKey valueForKey:@"modifierFlags"] unsignedIntegerValue] == (flags & [[cloneRepoKey valueForKey:@"modifierFlags"] unsignedIntegerValue])) && (keyCode == [[cloneRepoKey valueForKey:@"keyCode"] unsignedShortValue]) ) {
		[[self clone] showWindow:self];
	}
}

//	--- File System Events processing

-(unsigned long long)lastEventId
{
	return lastEventId;
}

- (void)setLastEventId:(unsigned long long)eventId
{
	lastEventId = eventId;
}

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    GitBuddy *buddy = (GitBuddy *)userData;
	size_t i;
    for(i=0; i < numEvents; i++){
		
		[buddy setLastEventId:eventIds[i]];
		NSObject * paths = [(NSArray *)eventPaths objectAtIndex:i];
		if ([paths isKindOfClass:[NSArray class]]) {
			[buddy appendEventPaths:(NSArray *)paths];
		}
		else {
			[buddy appendEventPaths:[NSArray arrayWithObject:paths]];
		}
    }
}

- (void) initializeEventForPaths:(NSArray *)pathsToWatch
{
	if ( ![pathsToWatch count] ) {
		return;
	}
	
	if (stream) {
		FSEventStreamRelease(stream);
		stream = nil;
	}
	NSLog(@"Initializing events for paths: %@", pathsToWatch);
    void *appPointer = (void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval latency = 3.0;
    stream = FSEventStreamCreate(NULL,
                                 &fsevents_callback,
                                 &context,
                                 (CFArrayRef) pathsToWatch,
                                 lastEventId,
                                 (CFAbsoluteTime) latency,
                                 kFSEventStreamCreateFlagUseCFTypes
								 );
	
    FSEventStreamScheduleWithRunLoop(stream,
                                     CFRunLoopGetCurrent(),
                                     kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

//	--- Changes scanning

- (void) processEventsNow
{
	//processing events
	[eventsLock lock];
	
	if ([queuedEvents count]) {
		[animStatus startAnimation];
		NSLog(@"Processing %d events in queue.", [queuedEvents count]);
		NSMutableSet * foldersToRescan = [NSMutableSet set];
		NSArray * excludedPatterns = [[NSUserDefaults standardUserDefaults] arrayForKey:@"excludedPatterns"];
		for(NSString *p in queuedEvents) {
			//check if path is excluded
			for(int i=0; i< [excludedPatterns count]; i++) {
				NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches %@", [excludedPatterns objectAtIndex:i]];
				if ([predicate evaluateWithObject:p]) {
					//path is excluded
					NSLog(@"Path %@ is excuted with predicte %@", p, predicate);
					continue;
				}
			}
			NSMenuItem *folderItem = [self menuItemForPath:p];
			NSString *folderPath = [[[folderItem representedObject] path] stringByAppendingPathComponent:@"/.git/"];
			
			if ([folderPath isEqual:[p substringToIndex:([p length] - 1)]]) {
				//repo query flashback. should ignore
				continue;
			}
			
			if (folderItem) {
				[foldersToRescan addObject:folderItem];
			}
		}
		
		//clear array
		[queuedEvents release];
		queuedEvents = nil;
		
		NSLog(@"Total %d Git repos were changed.", [foldersToRescan count]);
		if ( ![foldersToRescan count] ) {
			[animStatus stopAnimation];
		}
		
		for(NSMenuItem *mi in foldersToRescan) {
			[[mi representedObject] rescanWithCompletionBlock: ^{
				[animStatus stopAnimation];
			}];
		}
		
	}
	
	lastUpdatedSec = now_seconds();
	
	//unlock events
	[eventsLock unlock];
}

- (void) processEvents
{
	while(YES) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[self processEventsNow];
		[pool release];
		
		//sleep thread
		sleep(eventsRescanDelay);
	}
}

- (void) appendEventPaths:(NSArray *)paths
{
	//processing events
	[eventsLock lock];
	//merge events
	if (queuedEvents) {
		//append new events
		NSArray *merged = [queuedEvents arrayByAddingObjectsFromArray:paths];
		[queuedEvents release];
		queuedEvents = merged;
	}
	else {
		queuedEvents = paths;
	}
	[queuedEvents retain];
	[eventsLock unlock];
}

//	--- Monitored paths api

- (void)initMonitoredPaths:(NSArray*)paths
{
	for (NSString *p in paths) {
		NSLog(@"Initializing path %@", p);
		[self addMonitoredPath:p];
	}
	
	if ([paths count] == 1) {
		//there is only one project, so make it active
		[self setActiveProjectByPath:[paths objectAtIndex:0]];
	}
	
	[self processEventsNow];
}

- (NSMenuItem *) menuItemForPath:(NSString *)path
{
	for (int index = MENUITEMS - 1; index < [statusMenu numberOfItems] - 1; index++) {
		NSMenuItem *i = [statusMenu itemAtIndex:index];
		ProjectBuddy * pbuddy = [i representedObject];
		if ([path rangeOfString:[pbuddy path]].location == 0) {
			return i;
		}
	}
	return nil;
}

- (NSMenuItem *) newMenuItem:(NSString *)title withPath:(NSString *)path
{
	//insert new
	int insertIndex = [statusMenu numberOfItems] - 1;
	NSMenuItem *pathItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:[NSString string]];
	ProjectBuddy * pbuddy = [[ProjectBuddy alloc] initBuddy:pathItem forPath:path withTitle:title];
	[pbuddy setStatusTarget:self];
	[pbuddy setStatusSelector:@selector(receiveNotificationData:)];
	[pathItem setRepresentedObject:pbuddy];
	[statusMenu insertItem:pathItem atIndex:insertIndex];
	
	return pathItem;
}

- (NSArray *) monitoredPathsArray
{
	if ([statusMenu numberOfItems] > MENUITEMS) {
		NSArray * items = [[statusMenu itemArray] subarrayWithRange:NSMakeRange(MENUITEMS - 1, [statusMenu numberOfItems] - MENUITEMS)];
		NSMutableArray * paths = [NSMutableArray arrayWithCapacity:[items count]];
		for (NSMenuItem * i in items) {
			ProjectBuddy *pbuddy = [i representedObject];
			[paths addObject:[pbuddy path]];
		}
		return paths;
	}
	
	//empty array
	return [NSArray array];
}

- (BOOL) addMonitoredPath:(NSString *)path
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDirectory, isDotGitDirectory = NO;
	BOOL exists = [mgr fileExistsAtPath:[path stringByExpandingTildeInPath] isDirectory:&isDirectory];
	NSString * gitPath = [[path stringByExpandingTildeInPath] stringByAppendingPathComponent:@".git"];
	NSLog(@"Checking git repo at %@", gitPath);
	BOOL dotGit = [mgr fileExistsAtPath:gitPath isDirectory:&isDotGitDirectory];
	BOOL validPath = (exists && dotGit && isDirectory && isDotGitDirectory);
	if (validPath) {
		//add new monitored path
		[self newMenuItem:path withPath:[path stringByExpandingTildeInPath]];
		//scan for changes after repo was added
		[self appendEventPaths:[self monitoredPathsArray]];
		//restart events with new repo
		[self initializeEventForPaths:[self monitoredPathsArray]];
	}
	return validPath;
}

//	--- Branches & Remotes

- (void) createBranchFor:(ProjectBuddy*)buddy
{
	newBranchProject = buddy;
	[newBranchPanel orderFront:self];
}

- (void) createRemoteFor:(ProjectBuddy*)buddy
{
	newRemoteProject = buddy;
	[newRemotePanel orderFront:self];
}

//	--- UI Callbacks

- (IBAction) createBranch:(id)sender
{
	if (newBranchProject && [[newBranchName stringValue] length]) {
		
		[newBranchPanel orderOut:sender];
		
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", [newBranchProject path]];
		NSString *branchArg = [NSString stringWithFormat:@"--branch-add=%@", [newBranchName stringValue]];
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, branchArg, nil] withCompletionBlock:^(NSDictionary *dict) {
			
			if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
				NSRunInformationalAlertPanel(@"New Branch Created.", [NSString stringWithFormat:@"A New branch %@ was created as set as current branch for project %@", [newBranchName stringValue], [newBranchProject path]], @"All Right", nil, nil);
			}

			//done with project
			newBranchProject = nil;
		}];
	}
}

- (IBAction) createRemote:(id)sender
{
	if (newRemoteProject && [[newRemoteName stringValue] length] && [[newRemoteURL stringValue] length]) {
		
		[newRemotePanel orderOut:sender];
		
		GitWrapper *wrapper = [GitWrapper sharedInstance];
		NSString *repoArg = [NSString stringWithFormat:@"--repo=%@", [newRemoteProject path]];
		NSString *remoteArg = [NSString stringWithFormat:@"--remote-add=%@", [newRemoteName stringValue]];
		NSString *urlArg = [NSString stringWithFormat:@"--url=%@", [newRemoteURL stringValue]];
		[wrapper executeGit:[NSArray arrayWithObjects:repoArg, remoteArg, urlArg, nil] withCompletionBlock:^(NSDictionary *dict) {
			
			if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
				NSRunInformationalAlertPanel(@"New Remote Source Configured.", [NSString stringWithFormat:@"A New remote source %@ was added with name %@ to project %@", [newRemoteURL stringValue], [newRemoteName stringValue], [newBranchProject path]], @"All Right", nil, nil);
			}
			
			//done with project
			newRemoteProject = nil;
		}];
	}
}

- (IBAction) showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[preferences window] orderFront:sender];
}

- (IBAction) showAbout:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[aboutWnd orderFront:sender];
}

- (IBAction) showGitManual:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[defaults stringForKey:@"gitManualUrl"]]]) {
		NSLog(@"Failed to open url: %@", [defaults stringForKey:@"gitManualUrl"]);
	}
}

- (IBAction) browseForRepo:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
    if ([op runModal] == NSOKButton){
		[addRepoField setStringValue:[op filename]];
    }
}

- (IBAction) addRepo:(id)sender
{
	NSString *path = [addRepoField stringValue];
	if ( !path || ![path length]) {
		return;
	}
	
	NSLog(@"Adding path: %@", path);
	if ([self addMonitoredPath:path]) {
		[self initializeEventForPaths:[self monitoredPathsArray]];
		//set new repo as active
		[self setActiveProjectByPath:path];
		
		//close dialog
		[addRepoField setStringValue:@""];
		[addRepoPanel orderOut:sender];
		
		//scan new repo
		[self appendEventPaths:[NSArray arrayWithObject:path]];
		[self processEventsNow];
	}
	else {
		NSRunAlertPanel(@"Oups...", @"Specified path is not valid Git repository to monitor", @"Try again", nil, nil);
	}
}

- (void) rescanAll
{
	lastUpdatedSec = 0;
	NSLog(@"Rescaning all repos");
	
	for (NSString *prj in [self monitoredPathsArray]) {
		[self appendEventPaths:[NSArray arrayWithObject:prj]];
	}
	[self processEventsNow];
}

- (void) rescanRepoAtPath:(NSString*)path
{
	lastUpdatedSec = 0;
	NSLog(@"Rescaning repo %@", path);
	[self appendEventPaths:[NSArray arrayWithObject:path]];
	[self processEventsNow];
}

//	-- Initialization

+ (void) initialize
{
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	
    // load the default values for the user defaults
    userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
	
    // Set the initial values in the shared user defaults controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:userDefaultsValuesDict];
}

- (void) setCurrentImage
{
	if (currentImage) {
		[self setStatusImage:currentImage];
	}
}

- (void) setStatusImage:(NSImage*)image
{
	//set no changes image by default
	[statusItem setImage: image];
	[statusItem setAlternateImage:image];
}
												  
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSLog(@"Starting GitBuddy!");
	
	//set updates info
	NSDate *date = [updater lastUpdateCheckDate];
	if (date) {
		[[self lastUpdatedOn] setStringValue:[NSString stringWithFormat:@"Last updated on %@", [date description] ]];
	}
	else {
		[[self lastUpdatedOn] setStringValue:@"Never updated."];
	}
	
	//set version
	[[self appVersion] setStringValue:[NSString stringWithFormat:@"Your version is %@ (%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self setLastEventId:[[defaults objectForKey:@"lastEventId"] unsignedLongLongValue]];
	NSLog(@"Last event id: %d", lastEventId);
	
	//check git binary
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL exists, dir = NO;
	NSString *gitPath = [defaults valueForKey:@"gitPath"];
	exists = [mgr fileExistsAtPath:gitPath isDirectory:&dir];
	if (!exists || dir) {
		gitPath = @"/usr/local/bin/git";
		exists = [mgr fileExistsAtPath:gitPath isDirectory:&dir];
	}
	if (!exists || dir ) {
		gitPath = @"/usr/local/bin/git";
		exists = [mgr fileExistsAtPath:gitPath isDirectory:&dir];
	}
	
	if (exists && !dir && [gitPath length]) {
		[defaults setObject:gitPath forKey:@"gitPath"];
	}
	else {	
		int rc = NSRunAlertPanel(@"Git not found", @"GitBuddy failed to find git binary at %@. Please specify correct path in preferences.", @"Open preferences", @"Terminate", nil);
		if (rc == 1 ) {
			[[[self preferences] window] orderFront:self];
		}
	}
	
	//counters
	statusCounters = [[NSMutableDictionary alloc] init];
	
	//setup fs events
	eventsRescanDelay = [defaults doubleForKey:@"eventsRescanDelay"];
	NSLog(@"Events rescan delay: %.2f", eventsRescanDelay);
	lastUpdatedSec = 0;
	eventsThread = [[NSThread alloc] initWithTarget:self selector:@selector(processEvents) object:nil];
	[eventsThread start];
	
	//active project is none
	activeProject = nil;
	
	//events queue
	eventsLock = [[NSLock alloc] init];
	
	//status item
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem retain];
	
	//load images
	statusImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy16" ofType:@"png"]];
	statusAltImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitBuddy16Red" ofType:@"png"]];
	
	//no changed by default
	[self setStatusImage:statusImage];
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
	
	//setup animation
	animStatus = [[AnimatedStatus alloc] initWithPeriod:0.5];
	
	//Growl setup
	NSBundle *b = [NSBundle bundleForClass:[GitBuddy class]]; 
	NSString *growlPath = [[b privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
	
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath]; 
	if (growlBundle && [growlBundle load]) { 
		[GrowlApplicationBridge setGrowlDelegate:self]; 
		[GrowlApplicationBridge reregisterGrowlNotifications];
	}
	else { 
		NSLog(@"Could not load Growl.framework"); 
	}
	
	//subscribe on kbd events
	//works only if "Enable Access for Assistive Devices" enabled in
	//"Universal Access" of System Preferences
	// or need to implement AXMakeProcessTrusted and stuff
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler: ^(NSEvent *event){
		[self processKbdEvent:event];
	}];
	
	//subscribe on fs events
	[self initMonitoredPaths:[defaults arrayForKey:@"monitoredPaths"]];
	[self setActiveProjectByPath:[defaults stringForKey:@"activeProjectPath"]];
}

- (void) dealloc
{
	[statusImage release];
	[statusAltImage release];
	[statusItem release];
	[addRepoField release];
	[addRepoPanel release];
	[queuedEvents release];
	
	[operationPanel release];
	[operationDescription release];
	[operationIndicator release];
	
	[newBranchPanel release];
	[newBranchName release];

	[super dealloc];
}

//
// - Growl Delegate methods
//

- (NSDictionary*) registrationDictionaryForGrowl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"TicketVersion", [NSArray arrayWithObjects:@"REMOTE_BRANCH_CHANGED", @"LOCAL_BRANCH_CHANGED", nil], @"AllNotifications", [NSArray arrayWithObjects:@"REMOTE_BRANCH_CHANGED", @"LOCAL_BRANCH_CHANGED", nil], @"DefaultNotifications", nil];
}

- (NSString *) applicationNameForGrowl
{
	return @"Git Buddy";
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)app
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithUnsignedLongLong:lastEventId] forKey:@"lastEventId"];
	[defaults setObject:[self monitoredPathsArray] forKey:@"monitoredPaths"];
	ProjectBuddy *pbuddy = [self getActiveProjectBuddy];
	if (pbuddy) {
		[defaults setObject:[pbuddy path] forKey:@"activeProjectPath"];
	}
	
    [defaults synchronize];
	
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
	
	NSLog(@"Last processed event = %d", lastEventId);
	NSLog(@"Bye...");
    return NSTerminateNow;
}

//	-- Counters


- (void) receiveNotificationData:(NSDictionary*)data
{
	/*
	 * Data for update is the project status dict plus
	 *		these keys:
	 *	- not_pushed - list of sha256
	 *	- not_pulled - list of sha256
	 *	- remote_commits - dict with [sha256:commit array]
	 *	- local_commits - dict with [sha256:commit array]
	 *  - path ... + other from itemDict
	 
	 
	 Notification settings
	 <key>localNumberOfChanges</key>
	 <true/>
	 <key>localNumberOfChangesActiveOnly</key>
	 <false/>
	 <key>remoteNumberOfNotPulled</key>
	 <true/>
	 <key>remoteNumberOfNotPushed</key>
	 <true/>
	 <key>monitorRemoteBranches</key>
	 <true/>
	 <key>monitorRemoteNotifyGrowl</key>
	 <false/>
	 <key>monitorRemotePeriod</key>
	 
	 */

	NSString *projectPath = [data objectForKey:@"path"];
	ProjectBuddy *pbuddy = [[self menuItemForPath:projectPath] representedObject];
	NSMutableDictionary *projectCounters = [statusCounters objectForKey:projectPath];
	if (!projectCounters) {
		projectCounters = [NSMutableDictionary dictionary];
		[statusCounters setObject:projectCounters forKey:projectPath];
	}
	NSMutableDictionary *branchCounters = [projectCounters objectForKey:[data objectForKey:@"branch"]];
	if (!branchCounters) {
		branchCounters = [NSMutableDictionary dictionary];
		[projectCounters setObject:branchCounters forKey:[data objectForKey:@"branch"]];
	}
	
	//
	// Process received data
	//
	if (data && [[data allKeys] count]) {
		
		//merge with repo repos status data
		if ([data objectForKey:@"not_pushed"] || [data objectForKey:@"not_pulled"]) {
			[pbuddy mergeData:data];
		}
		
		NSLog(@"Processing notification from %@", projectPath);
		//Set remote data
		id notPushed = [data objectForKey:@"not_pushed"];
		if (notPushed) {
			NSLog(@"%d commits to push in %@.%@", [notPushed count], projectPath, [data objectForKey:@"branch"]);
			[branchCounters setObject:[NSNumber numberWithInt:[notPushed count]] forKey:@"not_pushed"];
			
		}
		id notPulled = [data objectForKey:@"not_pulled"];
		if (notPulled) {
			NSLog(@"%d commits to pull in %@.%@", [notPulled count], projectPath, [data objectForKey:@"branch"]);
			[branchCounters setObject:[NSNumber numberWithInt:[notPulled count]] forKey:@"not_pulled"];
		}
		
		//Set Staged count
		[branchCounters setObject:[NSNumber numberWithInt:[pbuddy stagedFilesCount]] forKey:@"staged"];
		NSLog(@"%d staged in %@", [pbuddy stagedFilesCount], projectPath);
		
		//Set Unstaged counters
		if ([data objectForKey:@"unstaged"]) {
			id changed = [[data objectForKey:@"unstaged"] objectForKey:@"modified"];
			id removed = [[data objectForKey:@"unstaged"] objectForKey:@"removed"];
			id added = [[data objectForKey:@"unstaged"] objectForKey:@"added"];
			id renamed = [[data objectForKey:@"unstaged"] objectForKey:@"renamed"];

			if (changed) {
				[branchCounters setObject:[NSNumber numberWithInt:[changed count]] forKey:@"modified"];
			}
			
			if (added) {
				[branchCounters setObject:[NSNumber numberWithInt:[added count]] forKey:@"added"];
			}
			
			if (removed) {
				[branchCounters setObject:[NSNumber numberWithInt:[removed count]] forKey:@"removed"];
			}
			
			if (renamed) {
				[branchCounters setObject:[NSNumber numberWithInt:[renamed count]] forKey:@"renamed"];
			}
		}
	}
	
	[self updateCounters];
	//Update menus of project on notification
	[pbuddy performSelectorOnMainThread:@selector(updateMenuItems) withObject:nil waitUntilDone:YES];
}

- (void) updateCounters
{	
	//
	// Build total, check each project status 
	//
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSLog(@"Project counters dictionary:\n%@\n***", statusCounters);
	int totalChanged = 0, totalStaged = 0, totalNotPushed = 0, totalNotPulled = 0;
	if (![defaults boolForKey:@"remoteNotificationsOnlyActive"] && ![defaults boolForKey:@"localNotificationsOnlyActive"] ) {
		
		//Calculate total
		for(NSString *prj in [statusCounters allKeys]) {
			for (NSString *brn in [statusCounters objectForKey:prj]) {
				for (NSString *category in [[statusCounters objectForKey:prj] objectForKey:brn]) {
					NSNumber *value = [[[statusCounters objectForKey:prj] objectForKey:brn] objectForKey:category];
					
					if ([category isEqual:[NSString stringWithString:@"not_pushed"]]) {
						totalNotPushed += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"not_pulled"]]) {
						totalNotPulled += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"added"]]) {
						totalChanged += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"removed"]]) {
						totalChanged += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"modified"]]) {
						totalChanged += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"renamed"]]) {
						totalChanged += [value intValue];
					}
					else if ([category isEqual:[NSString stringWithString:@"staged"]]) {
						totalStaged += [value intValue];
					}
				}
			}
		}
	}
	
	NSString *total = [NSString string];
		
	if ([defaults boolForKey:@"localNumberOfChanged"]) {
		
		if ([defaults boolForKey:@"localNotificationsOnlyActive"]) {
			NSLog(@"localNotificationsOnlyActive = YES. Skipping total local info build. Active project is %@", [[self getActiveProjectBuddy] path] );
			
			//set total = current count local
			total = [total stringByAppendingFormat:[defaults objectForKey:@"localModifiedFormat"], [[self getActiveProjectBuddy] changedFilesCount]];
		}
		else if (totalChanged) {
			total = [total stringByAppendingFormat:[defaults objectForKey:@"localModifiedFormat"], totalChanged];
		}
	}
	
	if ([defaults boolForKey:@"remoteNumberOfNotPulled"]) {
		
		if ([defaults boolForKey:@"remoteNotificationsOnlyActive"]) {
			NSLog(@"remoteNotificationsOnlyActive = YES. Skipping total pull info build. Active project is %@", [[self getActiveProjectBuddy] path] );
			
			//set total = current count remote
			total = [total stringByAppendingFormat:[defaults objectForKey:@"remoteNotPulledFormat"], [[[[self getActiveProjectBuddy] itemDict] objectForKey:@"not_pushed"] count]];
		}
		else if (totalNotPulled){
			total = [total stringByAppendingFormat:[defaults objectForKey:@"remoteNotPulledFormat"], totalNotPulled];
		}
	}
	
	if ([defaults boolForKey:@"remoteNumberOfNotPushed"]) {
		
		if ([defaults boolForKey:@"remoteNotificationsOnlyActive"]) {
			NSLog(@"remoteNotificationsOnlyActive = YES. Skipping total push info build. Active project is %@", [[self getActiveProjectBuddy] path] );
			
			//set total = current count remote
			total = [total stringByAppendingFormat:[defaults objectForKey:@"remoteNotPushedFormat"], [[[[self getActiveProjectBuddy] itemDict] objectForKey:@"not_pushed"] count]];
		}
		else if (totalNotPushed) {
			total = [total stringByAppendingFormat:[defaults objectForKey:@"remoteNotPushedFormat"], totalNotPushed];
		}
	}
		
	if ([total length]) {
		NSLog(@"Setting title: %@", total);
		//update with number of items
		[statusItem setTitle:total];
		//set alternate icon
		currentImage = statusAltImage;
		[self setCurrentImage];
		[statusItem setToolTip:[NSString stringWithFormat:@"Found %d unstaged changes, %d commits to pull & %d to push", totalChanged, totalNotPulled, totalNotPushed ]];
		
	}
	else if (totalStaged && [defaults boolForKey:@"localNumberOfStaged"]) {
		//set normal icon & number of staged
		currentImage = statusImage;
		[statusItem setTitle:[NSString stringWithFormat:[defaults objectForKey:@"localStagedFormat"], totalStaged]];
		[statusItem setToolTip:[NSString stringWithFormat:@"Found %d files staged for commit", totalStaged]];
	}
	
	else if (![defaults boolForKey:@"remoteNotificationsOnlyActive"] || ![defaults boolForKey:@"localNotificationsOnlyActive"]) {
		//set normal icon & no title or staged count
		currentImage = statusImage;
		[statusItem setTitle:total];
		[statusItem setToolTip:@"No changes detected."];
	}
}

//	---	Active Project

- (ProjectBuddy*) getActiveProjectBuddy
{
	if (activeProject) {
		return [activeProject representedObject];
	}
	
	return nil;
}

- (void) setActiveProjectByPath:(NSString*)path
{
	if ( ![path length] ) {
		return;
	}
	
	//reset current active if any
	if (activeProject) {
		[activeProject setState:NO];
	}
	
	//set new active
	NSMenuItem *i = [self menuItemForPath:path];
	if (i) {
		activeProject = i;
		[activeProject setState:YES];
		NSLog(@"Project %@ is active now.", [activeProject title]);
	}
}

//	-- Operation Panel, Clonning, Pushing & Pulling progress

- (void) startOperation:(NSString*)description
{
	[operationDescription setStringValue:description];
	[operationIndicator startAnimation:nil];
	[operationPanel orderFront:nil];
}

- (void) finishOperation
{
	[operationDescription setStringValue:@""];
	[operationIndicator stopAnimation:nil];
	[operationPanel orderOut:nil];
}

@end

double now_seconds()
{
	return (double)clock() / CLOCKS_PER_SEC;
}
