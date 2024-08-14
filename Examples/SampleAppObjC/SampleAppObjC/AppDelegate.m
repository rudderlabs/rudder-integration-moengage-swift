//
//  AppDelegate.m
//  SampleAppObjC
//
//  Created by Abhishek Pandey on 18/03/22.
//

#import "AppDelegate.h"

@import Rudder;
@import RudderMoEngage;
@import MoEngageSDK;
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    RSConfig *config = [[RSConfig alloc] initWithWriteKey:@"<WRITE_KEY>"];
    [config dataPlaneURL:@"<DATA_PLANE_URL>"];
    [config loglevel:RSLogLevelVerbose];
    [config trackLifecycleEvents:YES];
    [config recordScreenViews:YES];
    
    RSClient *client = [RSClient sharedInstance];
    [client configureWith:config];
    
    [client addDestination:[[RudderMoEngageDestination alloc] init]];
    [client track:@"Track 1"];
    
//    if (@available(iOS 10.0, *)) {
//        UNUserNotificationCenter.currentNotificationCenter.delegate = self;
//    }
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error) {
                                      NSLog(@"Request authorization succeeded!");
                                  }
                              }];
        
        // Register with APNs
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[MoEngageSDKMessaging sharedInstance] registerForRemoteNotificationWithCategories:nil andUserNotificationCenterDelegate:self];
    
 
    
    return YES;
}


#pragma mark - UISceneSession lifecycle

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[RSClient sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    NSString *deviceTokenString = [self deviceTokenToString:deviceToken];
        NSLog(@"Device Token: %@", deviceTokenString);
    //[[MoEngageSDKMessaging sharedInstance] setPushToken:deviceToken];
    
    [[RSClient sharedInstance] setDeviceToken:deviceTokenString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[RSClient sharedInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    [[RSClient sharedInstance] userNotificationCenter:center didReceive:response withCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[RSClient sharedInstance] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}


- (NSString *)deviceTokenToString:(NSData *)deviceToken {
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];
    
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger dataLength = [deviceToken length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    
    return [NSString stringWithString:hexString];
}


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
