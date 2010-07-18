//
//  main.m
//  IphoneSdk
//
//  Created by Felix Geisendörfer on 15.07.10.
//  Copyright Debuggable Limited 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
