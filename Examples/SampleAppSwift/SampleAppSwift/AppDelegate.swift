//
//  AppDelegate.swift
//  ExampleSwift
//
//  Created by Abhishek Pandey on 18/03/22.
//  Copyright © 2020 RudderStack. All rights reserved.
//

import UIKit
import Rudder
import RudderMoEngage
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var client: RSClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let config: RSConfig = RSConfig(writeKey: "<WRITE_KEY>")
            .dataPlaneURL("<DATA_PLANE_URL>")
            .loglevel(.debug)
            .trackLifecycleEvents(false)
            .recordScreenViews(false)

        client = RSClient.sharedInstance()
        client?.configure(with: config)

        client?.addDestination(RudderMoEngageDestination())

       // sendEvents()
      

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        registerForPushNotifications()
        return true
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
          }

    }
    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
          guard settings.authorizationStatus == .authorized else { return }
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }

      }
    }
    
    // MARK: Push Notification call
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
      print("Device Token: \(token)")
        RSClient.sharedInstance().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Failed to register: \(error)")
        RSClient.sharedInstance().application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        RSClient.sharedInstance().userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RSClient.sharedInstance().application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    // MARK: Track User Events
    func sendEvents() {
        sendIdentifyEvents()
        sendTrackEvents()
        sendAlias()
    }
    
    func sendAlias() {
        client?.identify("iOS User before Alias")
        client?.track("Empty track events")
        client?.alias("New iOS user id")
        client?.track("Empty track events")
    }

    func sendTrackEvents() {
        client?.track("Empty track events")
        client?.track("Checkout Started", properties: [
            "Key": "Value",
            "order_id": "12345",
            "date": Date(),
            "dateInStringFormat": "2016-04-14T10:44:00.000",
            "key-2": 1234,
            "key-3": true
        ])
    }

    func sendIdentifyEvents() {
        client?.identify("New User 2", traits: [
            "key": "Value",
            "date": Date(),
            "email": "User1@gmail.com",
            "name": "Full Name",
            "phone": "1234567890",
            "firstName": "FName",
            "lastName": "LName",
            "gender": "Male",
            "birthday": "2016-04-14T10:44:00.000",  // In EPOCH time format
            "address": "Random address",
            "age": 40
        ])
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension UIApplicationDelegate {
    var client: RSClient? {
        if let appDelegate = self as? AppDelegate {
            return appDelegate.client
        }
        return nil
    }
}
