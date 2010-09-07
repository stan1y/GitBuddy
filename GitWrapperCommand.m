//
//  GitWrapperCommand.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 6/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GitWrapperCommand.h"

@implementation GitWrapperCommand

@synthesize timeout, jsonResult, gitWrapper;

- (void) dealloc
{
	[stdoutPipe release];
	[stderrPipe release];
	[gitWrapper release];
	if (jsonResult) {
		[jsonResult release];
	}
	
	
	[super dealloc];
}

- (id) init
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	parser = [[SBJsonParser alloc] init];
	stdoutPipe = [[NSPipe alloc] init];
	stderrPipe = [[NSPipe alloc] init];
	gitWrapper = [[NSTask alloc] init];
	[gitWrapper setEnvironment:[NSDictionary dictionary]];
	
	[gitWrapper setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[gitWrapper setStandardError:stderrPipe];
	[gitWrapper setStandardOutput:stdoutPipe];
	[gitWrapper setLaunchPath:@"/usr/bin/python"];
	
	return self;
}

+ (GitWrapperCommand*) gitCommand:(NSString*)wrapperPath withArgs:(NSArray *)args
{
	GitWrapperCommand *cmd = [[GitWrapperCommand alloc] init];
	NSMutableArray * _args = [NSMutableArray arrayWithArray:args];
	[cmd setTimeout:[[NSUserDefaults standardUserDefaults] integerForKey:@"gitTimeout"]];
	[_args insertObject:wrapperPath atIndex:0];
	[_args insertObject:[NSString stringWithFormat:@"--git=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"gitPath"]] atIndex:1];
	[[cmd gitWrapper] setArguments:_args];
	NSLog(@"git operation: /usr/bin/python %@", [_args componentsJoinedByString:@" "]);
	return cmd;
}

- (void) main
{
	int totalSlept = 0;
	[gitWrapper launch];
	jsonResult = nil;
	
	while (YES) {
		if (totalSlept >= timeout) {
			[gitWrapper terminate];
			NSRunAlertPanel(@"Oups...", [NSString stringWithFormat:@"Git command timed out after %d seconds. Try increasing timeout value in preferences.", timeout], @"Continue", nil, nil);
			return;
		}
		sleep(1);
		
		if ( ![gitWrapper isRunning] ) {
			break;
		}
		totalSlept++;
	}
	
	if ( [gitWrapper terminationReason] != NSTaskTerminationReasonExit) {
		NSRunAlertPanel(@"Oups...", @"Git command terminated with unknown status. Something went really wrong.", @"Exit", nil, nil);
		NSLog(@"Aborting...");
		[[NSApplication sharedApplication] terminate:nil];
		[gitWrapper release];
		return;
	}
	else {
		int rc = [gitWrapper terminationStatus];
		NSLog(@"wrapper exit code %d", rc);
		//	wrapper exit codes: -1 is incorrect usage, other - git exit code
		if (rc == -1) {
			NSRunAlertPanel(@"Oups... Git command failed.", @"Git wrapper failed with error saying that usage is wrong. That mostly means unknown git installed here.", @"Exit", nil, nil);
			
			[[NSApplication sharedApplication] terminate:nil];
		}
		else {
			//read output and parse 
			NSString * output = [[[NSString alloc] initWithData:[[stdoutPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
			NSError * err = nil;
			id jsonObj = [parser objectWithString:output error:&err];
			if (err) {
				[[NSApplication sharedApplication] presentError:err];
				return;
			}
			if (jsonObj) {
				[self setJsonResult:jsonObj];
				
				//check json answer
				if ([[jsonObj objectForKey:@"giterr"] length] > 0 ){
					NSRunAlertPanel(@"Oups... Git command failed.", [NSString stringWithFormat:@"Git wrapper failed with code %d. %@", [[jsonObj objectForKey:@"gitrc"] intValue], [jsonObj objectForKey:@"giterr"]], @"Exit", nil, nil);
					
					[[NSApplication sharedApplication] terminate:nil];
					return;
				}
				return;
			}
			else {
				return;
			}
		}
	}
}


@end
