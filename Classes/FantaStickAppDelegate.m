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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register the preference defaults early.   
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"art.local", @"6661", @"6662", nil] forKeys:[NSArray arrayWithObjects:@"hostname", @"outport", @"inport", nil]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    // Other initialization...
    application.idleTimerDisabled = YES;
    application.statusBarHidden = YES;
    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
    [viewController release];
    [window release];

    [super dealloc];
}


@end
