//
//  IphoneSdkAppDelegate.m
//  IphoneSdk
//
//  Created by Felix Geisendörfer on 15.07.10.
//  Copyright Debuggable Limited 2010. All rights reserved.
//

#import "IphoneSdkAppDelegate.h"
#import "IphoneSdkViewController.h"

@implementation IphoneSdkAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
