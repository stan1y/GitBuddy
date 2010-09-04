//
//  GitWrapper.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 4/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitWrapper.h"

@implementation GitWrapper

- (id) init
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	gitLock = [[NSLock alloc] init];
	parser = [[SBJsonParser alloc] init];
	wrapperPath = [[NSBundle mainBundle] pathForResource:@"wrapper" ofType:@"py"];
	[wrapperPath retain];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	gitPath = [defaults stringForKey:@"gitPath"];
	timeout = [defaults integerForKey:@"gitTimeout"];
	
	NSLog(@"Git at %@", gitPath);
	NSLog(@"Git wrapper at %@", wrapperPath);
	
	return self;
}

- (id) getCommandJson:(NSArray *)args
{
	NSMutableArray * _args = [NSMutableArray arrayWithArray:args];
	[_args insertObject:wrapperPath atIndex:0];
	[_args insertObject:[NSString stringWithFormat:@"--git=%@", gitPath] atIndex:1];
	
	NSPipe *stdoutPipe = [[[NSPipe alloc] init] autorelease];
	NSPipe *stderrPipe = [[[NSPipe alloc] init] autorelease];
	NSTask *gitWrapper = [[[NSTask alloc] init] autorelease];
	
	[gitWrapper setLaunchPath:@"/usr/bin/python"];
	[gitWrapper setArguments:_args];
	
	[gitWrapper setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[gitWrapper setStandardError:stderrPipe];
	[gitWrapper setStandardOutput:stdoutPipe];
	
	NSLog(@"GitWrapper: /usr/bin/python %@", [_args componentsJoinedByString:@" "]);
	int totalSlept = 0;
	[gitWrapper launch];
	
	while (YES) {
		if (totalSlept >= timeout) {
			[gitWrapper terminate];
			NSRunAlertPanel(@"Oups...", [NSString stringWithFormat:@"Git command timed out after %d seconds. Try increasing timeout value in preferences.", timeout], @"Continue", nil, nil);
			return nil;
		}
		sleep(1);
		
		if ( ![gitWrapper isRunning] ) {
			break;
		}
		totalSlept++;
	}
	
	if ( [gitWrapper terminationReason] != NSTaskTerminationReasonExit) {
		NSRunAlertPanel(@"Oups...", @"Git command terminated with unknown status. Something went really wrong.", @"Continue", nil, nil);
		[gitWrapper release];
		return nil;
	}
	else {
		int rc = [gitWrapper terminationStatus];
		NSLog(@"GitWrapper: exit code %d", rc);
		//	0 - there are staged changed ready to commit
		//	1 - there are unstaged changes
		if (rc == 0 || rc == 1) {
			//read output and parse 
			NSString * output = [[[NSString alloc] initWithData:[[stdoutPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
			NSError * err = nil;
			id jsonObj = [parser objectWithString:output error:&err];
			if (err) {
				[[NSApplication sharedApplication] presentError:err];
				return nil;
			}
			if (jsonObj) {
				NSLog(@"getCommandJson -> [%@] %@", [jsonObj class], jsonObj);
				return jsonObj;
			}
			else {
				NSLog(@"getCommandJson -> nil");
				return nil;
			}
		}
		else {
			NSString * errorMessage = [[NSString alloc] initWithData:[[stderrPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
			NSRunAlertPanel(@"Oups...", [NSString stringWithFormat:@"Git wrapper failed with code %d. %@", rc, errorMessage], @"Continue", nil, nil);
			
			return nil;
		}
	}
}

//	--- Wrapper API	---

- (NSArray *) getBranches:(NSString *)path
{
	//FIXME
	return [NSArray arrayWithObject:@"master"];
}

- (NSArray *) getRemote:(NSString *)path
{
	//FIXME 
	return [NSArray arrayWithObject:@"origin"];
}

- (NSDictionary *) getChanges:(NSString *)path
{
	// /usr/bin/python wrapper.py --status <path>
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"--status"];
	[args addObject:path];
	
	id jsonObj = [self getCommandJson:args];
	if (jsonObj ) {
		if ([jsonObj isKindOfClass:[NSDictionary class]])
			return jsonObj;
		else {
			NSLog(@"getChanges error: unexpected json received [%@]: %@", [jsonObj class], jsonObj);
			return nil;
		}
	}
	else {
		NSLog(@"getChanges error: no json received.");
		return nil;
	}
}

@end
