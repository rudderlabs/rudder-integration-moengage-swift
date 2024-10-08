<p align="center">
  <a href="https://rudderstack.com/">
    <img src="https://user-images.githubusercontent.com/59817155/121357083-1c571300-c94f-11eb-8cc7-ce6df13855c9.png">
  </a>
</p>

<p align="center"><b>The Customer Data Platform for Developers</b></p>

<p align="center">
  <a href="https://cocoapods.org/pods/RudderMoEngage">
    <img src="https://img.shields.io/cocoapods/v/RudderMoEngage.svg?style=flat">
    </a>
</p>

<p align="center">
  <b>
    <a href="https://rudderstack.com">Website</a>
    ·
    <a href="https://www.rudderstack.com/docs/destinations/marketing/moengage/">Documentation</a>
    ·
    <a href="https://rudderstack.com/join-rudderstack-slack-community">Community Slack</a>
  </b>
</p>

---
# Integrating RudderStack iOS SDK with MoEngage

This repository contains the resources and assets required to integrate the [RudderStack iOS SDK](https://www.rudderstack.com/docs/stream-sources/rudderstack-sdk-integration-guides/rudderstack-ios-sdk/ios-v2/) with [MoEngage](https://www.moengage.com/).

| For more information on configuring MoEngage as a destination in RudderStack and the supported events and their mappings, refer to the [MoEngage documentation](https://www.rudderstack.com/docs/destinations/marketing/moengage/).   |
| :--|


## Step 1: Integrate the SDK with MoEngage

1. Add [MoEngage](https://www.moengage.com/) as a destination in the [RudderStack dashboard](https://app.rudderstack.com/).
2. `RudderMoEngage` is available through [CocoaPods](https://cocoapods.org). To install it, add the following line to your Podfile and followed by `pod install`, as shown:

```ruby
pod 'RudderMoEngage', '~> 2.0.0'
```

## Step 2: Initialize the RudderStack client (`RSClient`)

Place the following code in your ```AppDelegate``` under the ```didFinishLaunchingWithOptions``` method:

### Objective C

```objective-c
RSConfig *config = [[RSConfig alloc] initWithWriteKey:WRITE_KEY];
[config dataPlaneURL:DATA_PLANE_URL];
[[RSClient sharedInstance] configureWith:config];
[[RSClient sharedInstance] addDestination:[[RudderMoEngageDestination alloc] init]];
```
### Swift

```swift
let config: RSConfig = RSConfig(writeKey: WRITE_KEY)
            .dataPlaneURL(DATA_PLANE_URL)
RSClient.sharedInstance().configure(with: config)
RSClient.sharedInstance().addDestination(RudderMoEngageDestination())
```
## Step 3: Send events

Follow the steps listed in the [RudderStack iOS SDK](https://github.com/rudderlabs/rudder-sdk-ios/tree/master-v2#sending-events) repo to start sending events to MoEngage.

## Making push notifications event

Place the following code in your ```AppDelegate``` under the ```didFinishLaunchingWithOptions``` method:

### Objective C

```objective-c
if (@available(iOS 10.0, *)) {
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
}
```

### Swift

```swift
if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self
}
```

In you `plist` file add `MoEngageAppDelegateProxyEnabled` key and set it `false` to disable swizzling.

Generate `.pem` file and upload it to the MoEngage and then implement following method:

### Objective C
```objective-c
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[RSClient sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
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
```

### Swift

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    RSClient.sharedInstance().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    RSClient.sharedInstance().application(application, didFailToRegisterForRemoteNotificationsWithError: error)
}

func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    RSClient.sharedInstance().userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
}

func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    RSClient.sharedInstance().application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
}
```

## About RudderStack

RudderStack is the **customer data platform** for developers. With RudderStack, you can build and deploy efficient pipelines that collect customer data from every app, website, and SaaS platform, then activate your data in your warehouse, business, and marketing tools.

| Start building a better, warehouse-first CDP that delivers complete, unified data to every part of your customer data stack. Sign up for [RudderStack Cloud](https://app.rudderstack.com/signup?type=freetrial) today. |
| :---|

## Contact us

For queries on configuring or using this integration, start a conversation in our [Slack](https://rudderstack.com/join-rudderstack-slack-community) community.
