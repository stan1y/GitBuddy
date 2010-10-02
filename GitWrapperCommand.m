//
//  GitWrapperCommand.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 6/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "GitWrapperCommand.h"

@implementation GitWrapperCommand

@synthesize timeout, jsonResult, gitWrapper;

- (void) dealloc
{
	[stdoutPipe release];
	[stderrPipe release];
	[gitWrapper release];
	[parser release];
	
	[super dealloc];
}

- (id) initWith:(NSString*)wrapperPath withArgs:(NSArray *)args andTimeout:(int)tsecs
{
	if ( !(self = [super init]) ) {
		return nil;
	}
	
	parser = [[SBJsonParser alloc] init];
	stdoutPipe = [[NSPipe alloc] init];
	stderrPipe = [[NSPipe alloc] init];
	gitWrapper = [[NSTask alloc] init];
	[self setTimeout:tsecs];
	[gitWrapper setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[gitWrapper setStandardError:stderrPipe];
	[gitWrapper setStandardOutput:stdoutPipe];
	[gitWrapper setLaunchPath:@"/usr/bin/python"];
	
	NSMutableArray * _args = [NSMutableArray arrayWithArray:args];
	[_args insertObject:wrapperPath atIndex:0];
	[_args insertObject:[NSString stringWithFormat:@"--git=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"gitPath"]] atIndex:1];
	[gitWrapper setArguments:_args];
	//NSLog(@"git operation: /usr/bin/python %@", [_args componentsJoinedByString:@" "]);
	
	return self;
}

- (void) main
{
	int totalSlept = 0;
	[gitWrapper launch];
	jsonResult = nil;
	
	NSString * totalOutput = [NSString string];
	while (YES) {
		if (totalSlept >= timeout) {
			[gitWrapper terminate];
			NSRunAlertPanel(@"Oups...", [NSString stringWithFormat:@"Git command timed out after %d seconds. Try increasing timeout value in preferences.", timeout], @"Continue", nil, nil);
			return;
		}
		sleep(1);
		
		//read output and parse 
		NSString * thisOutput = [[[NSString alloc] initWithData:[[stdoutPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
		totalOutput = [totalOutput stringByAppendingString:thisOutput];
		
		if ( ![gitWrapper isRunning] ) {
			break;
		}
		totalSlept++;
	}
	
	if ( [gitWrapper terminationReason] != NSTaskTerminationReasonExit) {
		NSRunAlertPanel(@"Oups...", @"Git command terminated with unknown status. Something went really wrong.", @"Exit", nil, nil);
		NSLog(@"Git failed with unknown reason");
		[[NSApplication sharedApplication] terminate:nil];
		[gitWrapper release];

		return;
	}
	else {
		int rc = [gitWrapper terminationStatus];
		//	wrapper exit codes: -1 is incorrect usage, other - git exit code
		if (rc == -1) {
			
			//FATALITY!
			
			NSLog(@"Git usage error code %d", rc);
			NSRunAlertPanel(@"Oups... Git command failed.", @"Git wrapper failed with error saying that usage is wrong. That mostly means unknown git installed here.", @"Exit", nil, nil);
			[[NSApplication sharedApplication] terminate:nil];
		}
		
		
		NSError * err = nil;
		jsonResult = [parser objectWithString:totalOutput error:&err];
		
		if (err) {
			NSLog(@"Git error: %@", err);
			[[NSApplication sharedApplication] presentError:err];

			return;
		}
		if (!jsonResult) {
			NSLog(@"OMG no object from json library!");

			return;
		}

		//check json answer
		if ([[[self jsonResult] objectForKey:@"giterr"] count] > 0 && [[[self jsonResult] objectForKey:@"gitrc"] intValue] != 0 ){
			NSLog(@"Git exit: %d", rc);
			NSLog(@"Git error: %@", [[self jsonResult] objectForKey:@"giterr"]);
			int rc = NSRunAlertPanel(@"Oups... Git command failed.", [NSString stringWithFormat:@"Git wrapper failed with code %d. %@", [[[self jsonResult] objectForKey:@"gitrc"] intValue], [[[self jsonResult] objectForKey:@"giterr"] componentsJoinedByString:@" "]], @"Terminate", @"Continue", nil);
			
			//terminate
			if (rc == 1) {
				//FINISH HIM!
				[[NSApplication sharedApplication] terminate:nil];
			}
		}
		
		//All done

		return;
	}
}


@end
