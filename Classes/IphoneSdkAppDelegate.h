//
//  IphoneSdkAppDelegate.h
//  IphoneSdk
//
//  Created by Felix Geisendörfer on 15.07.10.
//  Copyright Debuggable Limited 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IphoneSdkViewController;

@interface IphoneSdkAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IphoneSdkViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IphoneSdkViewController *viewController;

@end

