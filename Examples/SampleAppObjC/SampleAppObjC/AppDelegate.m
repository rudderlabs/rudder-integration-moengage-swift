//
//  AppDelegate.m
//  SampleAppObjC
//
//  Created by Abhishek Pandey on 18/03/22.
//

#import "AppDelegate.h"

@import Rudder;
@import RudderMoEngage;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    RSConfig *config = [[RSConfig alloc] initWithWriteKey:@"27COeQCO3BS2WMw8CJUqYRC5hL7"];
    [config dataPlaneURL:@"https://rudderstacz.dataplane.rudderstack.com"];
    [config loglevel:RSLogLevelDebug];
    [config trackLifecycleEvents:YES];
    [config recordScreenViews:YES];
    
    RSClient *client = [RSClient sharedInstance];
    [client configureWith:config];
    
    [client addDestination:[[RudderMoEngageDestination alloc] init]];
    [client track:@"Track 1"];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
