//
//  FantaStickAppDelegate.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright Pink Twins 2009. All rights reserved.
//

#import "FantaStickAppDelegate.h"
#import "FantaStickViewController.h"

@implementation FantaStickAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

	application.idleTimerDisabled = YES;

    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];

    [super dealloc];
}


@end
