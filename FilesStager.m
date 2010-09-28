//
//  FilesStager.m
//  GitBuddy
//
//  Created by Stanislav Yudin on 8/9/2010.
//  Copyright 2010 Endless Insomnia Labs. All rights reserved.
//

#import "FilesStager.h"
#import "GitWrapper.h"
#import "Highlight.h"
#import "GitBuddy.h"
#import "ProjectBuddy.h"

@implementation FilesStager

@synthesize stagedSource, unstagedSource, changesSource;
@synthesize stagedView, unstagedView, title, externalBtn;
@synthesize selectedFile;

//	- Initialization

- (void) dealloc
{
	[selectedFile release];
	
	if (project) {
		[project release];
	}
	
	[super dealloc];
}

- (void) setProject:(NSDictionary *)dict stageAll:(BOOL)stage
{
	//copy project
	if (project) {
		[project release];
		project = nil;
	}
	
	project = [[NSDictionary alloc] initWithDictionary:dict	copyItems:YES];
	checkOnClose = YES;
	
	NSLog(@"Loading File Stager with Project Dictionary:");
	NSLog(@"%@", dict);
	NSLog(@" *** ");
	
	[title setStringValue:@"Loading diff preview..."];
	[stagedView setEnabled:NO];
	[unstagedView setEnabled:NO];
	
	[stagedView registerForDraggedTypes:[NSArray arrayWithObject:@"StageItem"]];
	[unstagedView registerForDraggedTypes:[NSArray arrayWithObject:@"StageItem"]];
	
	//load project files to table views
	[stagedSource loadProjectData:[project objectForKey:@"staged"] forPath:[project objectForKey:@"path"]];
	[unstagedSource loadProjectData:[project objectForKey:@"unstaged"] forPath:[project objectForKey:@"path"]];
	
	[title setStringValue:@"No diff found"];
	
	if ([[[project objectForKey:@"unstaged"] objectForKey:@"count"] intValue] > 0) {
		
		//copy unstaged file
		if (stage) {
			[stagedSource copyFilesFrom:unstagedSource];
			
			//select file in staged, since all is copied
			[stagedView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			[self tableView:stagedView shouldSelectRow:0];
		}
		else {
			//select in unstaged
			[unstagedView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			[self tableView:unstagedView shouldSelectRow:0];
		}
	}
	else if ([[[project objectForKey:@"staged"] objectForKey:@"count"] intValue] > 0) {
		
		//no unstaged, select in staged
		[stagedView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[self tableView:stagedView shouldSelectRow:0];
	}
	
	[stagedView setEnabled:YES];
	[unstagedView setEnabled:YES];
	
	[stagedView reloadData];
	[unstagedView reloadData];
}

- (NSDictionary *) filesToStage
{
	NSMutableDictionary *toStage = [NSMutableDictionary dictionary];
	for(NSString * key in [ProjectFilesSource dataKeys]) {
		
		for(NSString *stagedInSource in [[stagedSource data] objectForKey:key]) {
			//check it is in project array
			if ([stagedSource isForeignFile:stagedInSource]) {
				NSLog(@"File to stage: %@", stagedInSource);
				[toStage setObject:key forKey:stagedInSource];
			}
		}
	}
	return toStage;
} 

- (NSDictionary *) filesToUnStage
{
	NSMutableDictionary *toUnStage = [NSMutableDictionary dictionary];
	for(NSString * key in [ProjectFilesSource dataKeys]) {
		
		for(NSString *unstagedInSource in [[unstagedSource data] objectForKey:key]) {
			//check it is in project array
			if ([unstagedSource isForeignFile:unstagedInSource]) {
				NSLog(@"File to unstage: %@", unstagedInSource);
				[toUnStage setObject:key forKey:unstagedInSource];
			}
		}
	}
	return toUnStage;
}

//	- Callbacks

- (IBAction) stageFiles:(id)sender
{
	[self stageAndCommit:NO];
}

- (IBAction) stageAndCommitFiles:(id)sender
{
	[self stageAndCommit:YES];
}

- (void) stageAndCommit:(BOOL)commit
{
	NSDictionary *toStage = [self filesToStage];
	NSDictionary *toUnStage = [self filesToUnStage];
	
	GitWrapper *wrapper = [GitWrapper sharedInstance];
	NSString * repoArg = [NSString stringWithFormat:@"--repo=%@", [project objectForKey:@"path"]];
	if ([toUnStage count]) {
		NSLog(@"There are %d files to unstaged.", [toUnStage count]);
		NSString * unstageArg = [NSString stringWithFormat:@"--unstage=%@", [[toUnStage allKeys] componentsJoinedByString:@","]];
		[wrapper executeGit:[NSArray arrayWithObjects:unstageArg, repoArg, nil] withCompletionBlock:^(NSDictionary *dict) {

		}];
	}
	
	if ([toStage count]) { 
		NSLog(@"There are %d files to stage.", [toStage count]);
		
		NSMutableArray *toStageArray = [NSMutableArray array];
		NSMutableArray *toRemoveArray = [NSMutableArray array];
		
		for (NSString *file in [toStage allKeys]) {
			NSString* grp = [stagedSource fileInGroup:file];
			if ([grp isEqual:[NSString stringWithString:@"removed"]]) {
				[toRemoveArray addObject:file];
			}
			else {
				[toStageArray addObject:file];
			}

		}
		
		//Stage files
		if ([toStageArray count]) {
			NSString * stageArg = [NSString stringWithFormat:@"--stage=%@", [toStageArray componentsJoinedByString:@","]];
			[wrapper executeGit:[NSArray arrayWithObjects:stageArg, repoArg, nil] withCompletionBlock:^(NSDictionary *dict) {
				
				
				if ([[dict objectForKey:@"gitrc"] intValue] == 0) {
					
					//Remove files if any
					if ([toRemoveArray count]) {
						NSString * rmArg = [NSString stringWithFormat:@"--rm=%@", [toRemoveArray componentsJoinedByString:@","]];
						[wrapper executeGit:[NSArray arrayWithObjects:repoArg, rmArg, nil] withCompletionBlock:^(NSDictionary *dict2) {
							if ([[dict2 objectForKey:@"gitrc"] intValue] == 0) {
								
								//Commit if removed & staged ok
								[self showCommitPanel:nil];
							}	
						}];
					}
					else {
						//Show commit panel after staged ok
						[self showCommitPanel:nil];
					}
				}		 
			}];
		}
		else if ([toRemoveArray count]){
			//Only remove files
			NSString * rmArg = [NSString stringWithFormat:@"--rm=%@", [toRemoveArray componentsJoinedByString:@","]];
			[wrapper executeGit:[NSArray arrayWithObjects:repoArg, rmArg, nil] withCompletionBlock:^(NSDictionary *dict2) {
				if ([[dict2 objectForKey:@"gitrc"] intValue] == 0) {
					
					//Commit if removed & staged ok
					[self showCommitPanel:nil];
				}	
			}];
		}

	}
	
	//close window
	checkOnClose = NO;
	[[self window] performClose:nil];
}

- (void) showCommitPanel:(id)sender
{
	NSMenuItem *i = [(GitBuddy*)[NSApp delegate] menuItemForPath:[project objectForKey:@"path"]];
	
	[(ProjectBuddy*)[i representedObject] rescanWithCompletionBlock: ^{			
		
		//make sure Commit window will have 
		//the updated status dict
		[NSApp activateIgnoringOtherApps:YES];
		[[(GitBuddy*)[NSApp delegate] commit] commitProject:[(ProjectBuddy*)[i representedObject] itemDict] atPath:[project objectForKey:@"path"]];
		[[(GitBuddy*)[NSApp delegate] commit] showWindow:nil];
	}];
}

- (IBAction) showInExternalViewer:(id)sender
{
	[DiffViewSource externalDiffViewer:[self selectedFile] withOriginal:@"/dev/nul" project:[project objectForKey:@"path"]];
}

//	- TableView delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	NSString *file = [(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex];
	[self setSelectedFile:file];
	[title setStringValue:[NSString stringWithFormat:@"Preview of %@", file]  ];
	
	//deselect opposite table if it was selected
	if ([aTableView dataSource] == stagedSource) {
		[unstagedView deselectAll:nil];
	}
	else if ([aTableView dataSource] == unstagedSource){
		[stagedView deselectAll:nil];
	}
	
	//sources have their own copy of staged & unstaged
	//dicts to support grag & drop operations
	//need to make sure which one file really belongs
	NSString* grp = [(ProjectFilesSource*)[aTableView dataSource] fileInGroup:file];
	NSLog(@"Loading %@ (%@)", file, grp);
	NSArray * stagedGroup = [[project objectForKey:@"staged"] objectForKey:grp];
	NSArray * unstagedGroup = [[project objectForKey:@"unstaged"] objectForKey:grp];
	NSLog(@"Staged Files:");
	NSLog(@"%@", stagedGroup);
	NSLog(@" *** ");
	NSLog(@"Unstaged Files:");
	NSLog(@"%@", unstagedGroup);
	NSLog(@" *** ");
	
	if ( [aTableView isEqual:stagedView]) {
		//stage list clicked
		
		if ([stagedGroup indexOfObject:file] != NSNotFound && ![(ProjectFilesSource*)[stagedView dataSource] isForeignFile:file]) {
			//belongs to staged
			[changesSource updateWithCachedFileDiff:[(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		}
		else {
			//belongs to unstaged
			[changesSource updateWithFileDiff:[(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		}
		
		//enable external
		[externalBtn setHidden:NO];
	}
	else if ( [aTableView isEqual:unstagedView]) {
		//unstaged list clicked
		if ([unstagedGroup indexOfObject:file] != NSNotFound && ![(ProjectFilesSource*)[unstagedView dataSource] isForeignFile:file]){
			//belongs to unstaged.group.file
			[changesSource updateWithFileDiff:[(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		}
		else {
			[changesSource updateWithCachedFileDiff:[(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex] inPath:[project objectForKey:@"path"]];
		}
		
		//enable external
		[externalBtn setHidden:NO];
	}
	else {
		[externalBtn setHidden:YES];
		return NO;
	}

	return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (![aCell isKindOfClass:[NSTextFieldCell class]]) {
		return;
	}
	
	if (aTableView == stagedView || aTableView == unstagedView) {
		NSString* grp = nil;
		int offset = 0;
		[(ProjectFilesSource*)[aTableView dataSource] fileAtIndex:rowIndex inGroup:&grp groupIndexOffset:&offset];;
		
		if ([grp isEqual:@"modified"]) {
			[aCell setTextColor:[NSColor orangeColor]];
		}
		else if ([grp isEqual:@"added"]) {
			[aCell setTextColor:[NSColor greenColor]];
		}
		else if ([grp isEqual:@"removed"] || [grp isEqual:@"renamed"]) {
			[aCell setTextColor:[NSColor redColor]];
		}
		
	} else {
		NSString *str = [(DiffViewSource*)[aTableView dataSource] stringAtIndex:rowIndex];
		[Highlight highLightCell:aCell forLine:str];
	}
}

//	- Window delegate

- (BOOL) windowShouldClose:(id)sender
{
	
	if (!checkOnClose) {
		return YES;
	}
	
	//check difference with project arrays and
	//copies in sources
	NSDictionary *toStage = [self filesToStage];
	NSDictionary *toUnStage = [self filesToUnStage];
	
	if ([[toStage allKeys] count] > 0 || [[toUnStage allKeys] count] > 0) {
		int rc = NSRunInformationalAlertPanel([NSString stringWithFormat:@"You have %d files to stage and %d files to unstage.", [[toStage allKeys] count], [[toUnStage allKeys] count]] , @"Click on Stage Changes to confirm staging or Close Anyway to dispose all activity. Also you click on Cancel to return to File Stager.", @"Stage Changes", @"Cancel", @"Close Anyway");
		switch (rc) {
			case 0:
			default:
				NSLog(@"Close canceled by user");
				
				return NO;
				break;
				
			case 1:
				//procced changes
				NSLog(@"Stating %d files & unstaging %d files", [[toStage allKeys] count] , [[toUnStage allKeys] count]);
				
				return YES;
				break;
				
			case -1:
				NSLog(@"Disposing %d staged files & %d unstaging files", [[toStage allKeys] count] , [[toUnStage allKeys] count]);
				
				return YES;
				break;
		}
	}
	
	//no changes
	return YES;
}

@end
