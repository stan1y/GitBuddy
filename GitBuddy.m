//
//  GitBuddyAppDelegate.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 3/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitBuddy.h"


//	-- Default menu items settings

// initial number of menu items in status menu
#define MENUITEMS 5

@implementation GitBuddy

@synthesize addPathPanel;
@synthesize addPathField;

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
		NSLog(@"Processing event %d, last %d", eventIds[i], [buddy lastEventId]);
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
	NSArray * excludedPatterns = [[NSUserDefaults standardUserDefaults] arrayForKey:@"excludedPatterns"];
	for(NSString *p in paths) {
		
		//check if path is excluded
		for(int i=0; i< [excludedPatterns count]; i++) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches %@", [excludedPatterns objectAtIndex:i]];
			if ([predicate evaluateWithObject:p]) {
				//path is excluded
				return;
			}
		}
		
		NSMenuItem *folderItem = [self menuItemForPath:p];
		if (folderItem) {			
			ProjectBuddy *pbuddy = [folderItem representedObject];
			[pbuddy scanChanges];
		}
	}
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
		NSDictionary *dict = [i representedObject];
		if ([path rangeOfString:[dict valueForKey:@"title"]].location == 0) {
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
- (IBAction) showGitManual:(id)sender
{}
- (IBAction) showChangeSet:(id)sender
{}
- (IBAction) pushClicked:(id)sender
{}
- (IBAction) stageChangesClicked:(id)sender
{}
- (IBAction) moveToBranchChangesClicked:(id)sender
{}

- (IBAction) browseForPath:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
    if ([op runModal] == NSOKButton){
		[addPathField setStringValue:[op filename]];
    }
}

- (IBAction) addPath:(id)sender
{
	NSString *path = [addPathField stringValue];
	NSLog(@"Adding path: %@", path);
	if ([self addMonitoredPath:path]) {
		[self initializeEventForPaths:[self monitoredPathsArray]];
		[addPathField setStringValue:@""];
		[addPathPanel orderOut:sender];
	}
	else {
		NSRunAlertPanel(@"Oups...", @"Specified path is not valid Git repository to monitor", @"Try again", nil, nil);
	}
}

- (IBAction) removePath:(id)sender
{
	NSString *path = [[sender menu] title];
	NSMenuItem * parentItem = [self menuItemForPath:path];
	int rc = NSRunInformationalAlertPanel(@"Removing path", [NSString stringWithFormat:@"Do you want to remove Git repository %@ from watch list?", path], @"Remove repo", @"Cancel", nil);
	if (rc == 1) {
		[statusMenu removeItem:parentItem];
		[parentItem release];
		[self initializeEventForPaths:[self monitoredPathsArray]];
	}
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
	NSLog(@"Starting GitBuddy");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	unsigned long long eventId = [[defaults objectForKey:@"lastEventId"] intValue];
	[self setLastEventId:eventId];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	[statusItem retain];
	statusImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"StatusIconBlack" ofType:@"png"]];
	statusAltImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"StatusIconGreen" ofType:@"png"]];
	
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];	
	[statusItem setImage: statusImage];
	[statusItem setAlternateImage: statusAltImage];
	[statusItem setMenu: statusMenu];
	[statusItem setToolTip: @"GitBuddy"];
	[statusItem setHighlightMode: YES];
	
	NSLog(@"Last event id: %d", [lastEventId unsignedLongLongValue]);
	[self initMonitoredPaths:[defaults arrayForKey:@"monitoredPaths"]];
}

- (void) dealloc
{
	[statusImage release];
	[statusAltImage release];
	[statusItem release];
	[lastEventId release];
	[addPathField release];
	[addPathPanel release];

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
	
	NSLog(@"Closing GitBuddy");
	NSLog(@"Last processed event = %@", lastEventId);
    return NSTerminateNow;
}

@end
