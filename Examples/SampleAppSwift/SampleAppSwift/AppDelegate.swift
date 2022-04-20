//
//  AppDelegate.swift
//  ExampleSwift
//
//  Created by Abhishek Pandey on 18/03/22.
//  Copyright © 2020 RudderStack. All rights reserved.
//

import UIKit
import RudderStack
import RudderMoEngage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var client: RSClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let config: RSConfig = RSConfig(writeKey: "27COeQCO3BS2WMw8CJUqYRC5hL7")
            .dataPlaneURL("https://rudderstacbumvdrexzj.dataplane.rudderstack.com")
            .loglevel(.none)
            .trackLifecycleEvents(true)
            .recordScreenViews(false)

        client = RSClient(config: config)

        client?.addDestination(RudderMoEngageDestination())

        sendEvents()

        return true
    }

    func sendEvents() {
        sendIdentifyEvents()
        sendTrackEvents()
//        sendAlias()
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
//        client?.identify("iOS Empty User")
//        client?.identify("iOS User with Empty Traits", traits: [:])
        client?.identify("iOS User with traits 2", traits: [
            "key": "Value",
            "date": Date(),
            "email": "random@example.com",
            "name": "Full Name",
            "phone": 1234567890,
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
