//
//  ProjectSubMenu.h
//  GitBuddy
//
//  Created by Stanislav Yudin on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProjectSubMenu : NSObject<NSMenuDelegate> {
	NSDictionary *data;
	NSMenu *menu;
	NSString *project;
	int itemsInitially;
	
	SEL itemSelector;
	id itemTarget;
	
	BOOL pending;
}

@property (assign) BOOL pending;

- (id) initProject:(NSString*)project withDict:(NSDictionary*)dict forMenu:(NSMenu *)aMenu;
- (void) setData:(NSDictionary*)dict;
- (void) setInitialItems:(NSArray*)items;
- (void) setItemSelector:(SEL)sel target:(id)aTarget;
- (int) totalNumberOfFiles;
- (NSArray*) selectedFiles;

//	Menu delegate
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel;
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu;

@end
