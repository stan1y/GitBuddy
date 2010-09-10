//
//  GitBuddyAppDelegate.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitBuddy.h"
#import <Carbon/Carbon.h>
#include <time.h>


#define STAGE_FILES_CMD 1
#define COMMIT_LOG_CMD 2


// initial number of menu items in status menu
#define MENUITEMS 5

@implementation GitBuddy

@synthesize addRepoPanel, addRepoField;
@synthesize queue;
@synthesize filesStager, preview, commit;

//	---	Keyboard Events processing

- (void) processKbdEvent:(NSEvent*)event
{
	ProjectBuddy *pbuddy = [self getActiveProjectBuddy];
	if ( !pbuddy ) {
		NSRunAlertPanel(@"GitBuddy cannot process key binding", @"There is no Active Project now, so there is no target Repo for your action. Please select Activate in project's menu or create a new Repo.", @"Continue", nil, nil);
		return;
	}
	/*
	 enum {
	 NSAlphaShiftKeyMask = 1 << 16,
	 NSShiftKeyMask      = 1 << 17,
	 NSControlKeyMask    = 1 << 18,
	 NSAlternateKeyMask  = 1 << 19,
	 NSCommandKeyMask    = 1 << 20,
	 NSNumericPadKeyMask = 1 << 21,
	 NSHelpKeyMask       = 1 << 22,
	 NSFunctionKeyMask   = 1 << 23,
	 NSDeviceIndependentModifierFlagsMask = 0xffff0000U
	 };
	 */
	int stageFilesKeyCode = 83; // s
	int commitLogKeyCode = 76; //l
	if ( [event modifierFlags] & NSCommandKeyMask & NSAlternateKeyMask) {
		if ([event keyCode] == stageFilesKeyCode) {
			[pbuddy stageSelectedFiles:nil];
		}
		else if ([event keyCode] == commitLogKeyCode) {
			[pbuddy	commitLog:nil];
		}
	}
}

//	--- File System Events processing

-(unsigned long long)lastEventId
{
	@synchronized (self) {
		return [lastEventId unsignedLongLongValue];
	}
}

- (void)setLastEventId:(unsigned long long)eventId
{
	@synchronized(self){
		lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
		[lastEventId retain];
	}
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
		if (eventIds[i] > [buddy lastEventId]) {
			NSObject * paths = [(NSArray *)eventPaths objectAtIndex:i];
			if ([paths isKindOfClass:[NSArray class]]) {
				[buddy scanUpdatesAtPaths:(NSArray *)paths];
			}
			else {
				[buddy scanUpdatesAtPaths:[NSArray arrayWithObject:paths]];
			}
		}
		[buddy setLastEventId:eventIds[i]];
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
                                 [lastEventId unsignedLongLongValue],
                                 (CFAbsoluteTime) latency,
                                 kFSEventStreamCreateFlagUseCFTypes
								 );
	
    FSEventStreamScheduleWithRunLoop(stream,
                                     CFRunLoopGetCurrent(),
                                     kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

//	--- Changes scanning

- (void) scanUpdatesAtPaths:(NSArray *)paths
{
	//processing events
	[eventsLock lock];
	
	//FIXME: icon animation start
	
	//merge events
	if (queuedEvents) {
		//append new events
		queuedEvents = [queuedEvents arrayByAddingObjectsFromArray:paths];
	}
	else {
		queuedEvents = paths;
	}
	[queuedEvents retain];
	
	//check minimal period
	double delta = now_seconds() - lastUpdatedSec;
	if (lastUpdatedSec && delta < minimalUpdateTimeSec) {
		[eventsLock unlock];
		return;
	}
	
	NSLog(@"Processing %d events in queue.", [queuedEvents count]);
	NSMutableSet * foldersToRescan = [NSMutableSet set];
	NSArray * excludedPatterns = [[NSUserDefaults standardUserDefaults] arrayForKey:@"excludedPatterns"];
	for(NSString *p in queuedEvents) {
		//check if path is excluded
		for(int i=0; i< [excludedPatterns count]; i++) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches %@", [excludedPatterns objectAtIndex:i]];
			if ([predicate evaluateWithObject:p]) {
				//path is excluded
				continue;
			}
		}
		NSMenuItem *folderItem = [self menuItemForPath:p];
		if (folderItem) {
			[foldersToRescan addObject:folderItem];
		}
	}
	
	//clear array
	[queuedEvents release];
	queuedEvents = nil;
	
	NSLog(@"Total %d Git repos were changed.", [foldersToRescan count]);
	for(NSMenuItem *mi in foldersToRescan) {
		[[mi representedObject] rescanWithCompletionBlock: ^{
			//FIXME: icon animation stop
		}];
	}

	
	lastUpdatedSec = now_seconds();
	NSLog(@"Update done on: %f", lastUpdatedSec);
	[eventsLock unlock];
}

//	--- Monitored paths api

- (void)initMonitoredPaths:(NSArray*)paths
{
	for (NSString *p in paths) {
		NSLog(@"Initializing path %@", p);
		[self addMonitoredPath:p];
	}
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
	[pathItem setRepresentedObject:pbuddy];
	[statusMenu insertItem:pathItem atIndex:insertIndex];
	
	return pathItem;
}

- (NSArray *) monitoredPathsArray
{
	if ([statusMenu numberOfItems] > MENUITEMS) {
		NSArray * items = [[statusMenu itemArray] subarrayWithRange:NSMakeRange(MENUITEMS - 1, [statusMenu numberOfItems] - MENUITEMS)];
		NSMutableArray * paths = [[NSMutableArray alloc] initWithCapacity:[items count]];
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
		[self scanUpdatesAtPaths:[self monitoredPathsArray]];
		//restart events with new repo
		[self initializeEventForPaths:[self monitoredPathsArray]];
	}
	return validPath;
}

//	--- UI Callbacks

- (IBAction) checkUpdates:(id)sender
{
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
	NSLog(@"Adding path: %@", path);
	if ([self addMonitoredPath:path]) {
		[self initializeEventForPaths:[self monitoredPathsArray]];
		[addRepoField setStringValue:@""];
		[addRepoPanel orderOut:sender];
	}
	else {
		NSRunAlertPanel(@"Oups...", @"Specified path is not valid Git repository to monitor", @"Try again", nil, nil);
	}
}

- (IBAction) rescanRepos:(id)sender
{
	lastUpdatedSec = 0;
	NSLog(@"Rescaning repos...");
	[self scanUpdatesAtPaths:[self monitoredPathsArray]];
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
												  
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSLog(@"Starting GitBuddy!");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	unsigned long long eventId = [[defaults objectForKey:@"lastEventId"] intValue];
	[self setLastEventId:eventId];
	NSLog(@"Last event id: %d", [lastEventId unsignedLongLongValue]);
	minimalUpdateTimeSec = [defaults doubleForKey:@"minimalUpdateTimeSec"];
	NSLog(@"Minimal update period in seconds: %.2f", minimalUpdateTimeSec);
	lastUpdatedSec = 0;
	
	//active project is none
	activeProject = nil;
	
	//events queue
	eventsLock = [[NSLock alloc] init];
	projCounters = [[NSMutableDictionary alloc] init];
	
	//calls to other programs as operations
	queue = [[NSOperationQueue alloc] init];
	
	//status item
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem retain];
	
	//load images
	statusImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"StatusIconBlack" ofType:@"png"]];
	statusAltImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"StatusIconGreen" ofType:@"png"]];
	
	//set no changes image by default
	[statusItem setImage: statusImage];
	[statusItem setAlternateImage: statusImage];
	
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];	
	[statusItem setMenu: statusMenu];
	
	//setup kbd events	
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler: ^(NSEvent *event){
		[self processKbdEvent:event];
	}];
	
	//setup fs events
	[self initMonitoredPaths:[defaults arrayForKey:@"monitoredPaths"]];
}

- (void) dealloc
{
	[projCounters release];
	[statusImage release];
	[statusAltImage release];
	[statusItem release];
	[lastEventId release];
	[addRepoField release];
	[addRepoPanel release];
	[queue release];
	[queuedEvents release];

	[super dealloc];
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)app
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastEventId forKey:@"lastEventId"];
	[defaults setObject:[self monitoredPathsArray] forKey:@"monitoredPaths"];
    [defaults synchronize];
	
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
	
	NSLog(@"Last processed event = %@", lastEventId);
	NSLog(@"Bye...");
    return NSTerminateNow;
}

//	-- Counters

- (void) setCounter:(int)changed forProject:(NSString*)path
{
	[projCounters setObject:[NSNumber numberWithInt:changed] forKey:path];
	
	//update status icon
	
	int totalItems = 0;
	for (NSNumber *num in [projCounters allValues]) {
		totalItems += [num intValue];
	}
	if (totalItems) {
		//update with number of items
		[statusItem setTitle:[NSString stringWithFormat:@" %d", totalItems]];
		//set alternate icon
		[statusItem setImage: statusAltImage];
		[statusItem setAlternateImage: statusAltImage];
		[statusItem setToolTip:[NSString stringWithFormat:@"GitBuddy found %d unstaved changes.", totalItems]];
	}
	else {
		//set normal icon & no title
		[statusItem setTitle:@""];
		[statusItem setImage: statusImage];
		[statusItem setAlternateImage: statusImage];
		[statusItem setToolTip:@"GitBuddy running."];
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
	if (activeProject) {
		[activeProject setState:NO];
	}
	
	NSMenuItem *i = [self menuItemForPath:path];
	if (i) {
		activeProject = i;
		NSLog(@"Project %@ is active now.", [activeProject title]);
	}
}

@end

double now_seconds()
{
	return (double)clock() / CLOCKS_PER_SEC;
}
