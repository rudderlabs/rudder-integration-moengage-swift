//
//  RSMoEngageDestination.swift
//  RudderMoEngage
//
//  Created by Abhishek Pandey on 18/03/22.
//

import Foundation

import Rudder
import MoEngageSDK

class RSMoEngageDestination: NSObject, RSDestinationPlugin, UNUserNotificationCenterDelegate {
    let type = PluginType.destination
    let key = "MoEngage"
    var client: RSClient?
    var controller = RSController()
    var moEngageDataCenter: MoEngageDataCenter?

    func update(serverConfig: RSServerConfig, type: UpdateType)  {
        guard type == .initial else { return }
        guard let moEngageConfig: RSMoEngageConfig = serverConfig.getConfig(forPlugin: self) else {
            client?.log(message: "Failed to Initialize MoEngage Factory", logLevel: .warning)
            return
        }
        
        // Redirect data according to region
        if moEngageConfig.region == "EU" {
            moEngageDataCenter = .data_center_02
        } else if moEngageConfig.region == "US" {
            moEngageDataCenter = .data_center_01
        } else if moEngageConfig.region == "IND" {
            moEngageDataCenter = .data_center_03
        }
        else{
            client?.log(message:"MoEngage SDK initialization terminated due to an invalid region.", logLevel: .warning)
        }
        
        let sdkConfig = MoEngageSDKConfig(appId: moEngageConfig.apiId, dataCenter: moEngageDataCenter!)
        // Check if debug mode is on or off
#if DEBUG
      
        MoEngage.sharedInstance.initializeDefaultTestInstance(sdkConfig)
#else
        
        MoEngage.sharedInstance.initializeDefaultLiveInstance(sdkConfig)
#endif
       
        if UNUserNotificationCenter.current().delegate == nil {
           UNUserNotificationCenter.current().delegate = self
        }
        
        client?.log(message: "Initializing MoEngage SDK", logLevel: .debug)
    }
    
    func identify(message: IdentifyMessage) -> IdentifyMessage? {
        reset()
        if let anonymousId = message.anonymousId {
          
            MoEngageSDKAnalytics.sharedInstance.setUserAttribute(anonymousId, withAttributeName: "anonymousId")
        }
        
        if let userId = message.userId {
          
            MoEngageSDKAnalytics.sharedInstance.setUniqueID(userId)
        }
        
        if let traits = message.traits, !traits.isEmpty {
            handle(traits: traits)
            
        }
        return message
    }
    
    


    func track(message: TrackMessage) -> TrackMessage? {
        if !message.event.isEmpty {
            switch message.event {
            case RSEvents.LifeCycle.applicationInstalled: MoEngageAppStatus(rawValue: 0)
            case RSEvents.LifeCycle.applicationUpdated: MoEngageAppStatus.update
            default:
                if let properties = message.properties, !properties.isEmpty {
                    let eventProperties: MoEngageProperties = MoEngageProperties()
                    for (key, value) in properties {
                        switch value {
                        case let val as String:
                            // Try to convert the value from String to Date
                            if let date: Date = dateFrom(isoDateString: val) {
                                eventProperties.addDateAttribute(date, withName: key)
                                break
                            }
                            eventProperties.addAttribute(val, withName: key)
                        case let date as Date:
                            eventProperties.addDateAttribute(date, withName: key)
                        case let val as NSNumber:
                            eventProperties.addAttribute(val, withName: key)
                        default: break
                        }
                    }
                   
                 
                    MoEngageSDKAnalytics.sharedInstance.trackEvent(message.event, withProperties: eventProperties)
                
                } else {
                // If message.properties is empty
                  
                    MoEngageSDKAnalytics.sharedInstance.trackEvent(message.event, withProperties: nil)
                    
                }
            }
        }
        return message
    }
    
    func alias(message: AliasMessage) -> AliasMessage? {
        if let newId = message.userId {
           MoEngageSDKAnalytics.sharedInstance.setAlias(newId)
        }
        return message
    }

    func reset() {
      
        MoEngageSDKAnalytics.sharedInstance.resetUser()
        client?.log(message: "MoEngage Reset API: 'MoEngage.sharedInstance().resetUser]()' is called.", logLevel: .debug)
    }
    
    func flush() {
      
       MoEngageSDKAnalytics.sharedInstance.flush()
       client?.log(message: "MoEngage Flush API: 'MoEngage.sharedInstance().flush()' is called.", logLevel: .debug)
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)

// MARK: - Push Notification methods

extension RSMoEngageDestination: RSPushNotifications {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MoEngageSDKMessaging.sharedInstance.setPushToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        MoEngageSDKMessaging.sharedInstance.didFailToRegisterForPush()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
       MoEngageSDKMessaging.sharedInstance.didReceieveNotification(inApplication: application, withInfo: userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        MoEngageSDKMessaging.sharedInstance.userNotificationCenter(center, didReceive: response)
    }
}

#endif

// MARK: - Support methods

extension RSMoEngageDestination {
    func handle(traits: [String: Any]) {
        for (key, value) in traits {
            if value is String || value is NSNumber || value is Date {
                switch key {
                case RSKeys.Identify.Traits.email: MoEngageSDKAnalytics.sharedInstance.setEmailID((value as? String)!)
                case RSKeys.Identify.Traits.name: MoEngageSDKAnalytics.sharedInstance.setName((value as? String)!)
                case RSKeys.Identify.Traits.phone: MoEngageSDKAnalytics.sharedInstance.setMobileNumber(value as! String)
                case RSKeys.Identify.Traits.firstName: MoEngageSDKAnalytics.sharedInstance.setUserAttribute(value, withAttributeName: "USER_ATTRIBUTE_USER_FIRST_NAME") 
                case RSKeys.Identify.Traits.lastName: MoEngageSDKAnalytics.sharedInstance.setLastName((value as? String)!)
                case RSKeys.Identify.Traits.gender: MoEngageSDKAnalytics.sharedInstance.setUserAttribute(value, withAttributeName: "USER_ATTRIBUTE_USER_GENDER")
                case RSKeys.Identify.Traits.birthday: identifyDateUserAttribute(value: value, key: "USER_ATTRIBUTE_USER_BDAY")
                case RSKeys.Identify.Traits.address: MoEngageSDKAnalytics.sharedInstance.setUserAttribute(value, withAttributeName: RSKeys.Identify.Traits.address)
                case RSKeys.Identify.Traits.age: MoEngageSDKAnalytics.sharedInstance.setUserAttribute(value, withAttributeName: RSKeys.Identify.Traits.age)
                default: identifyDateUserAttribute(value: value, key: key)
                }
            }
        }
    }
    
    func identifyDateUserAttribute(value: Any?, key: String?) {
        if let key = key {
            // Verify if the value is of type Date or not
            // Track UserAttribute using Epoch value. Refer here: https://developers.moengage.com/hc/en-us/articles/4403905883796-Tracking-User-Attributes
            if let value = value as? String, let convertedDate = dateFrom(isoDateString: value) {
                MoEngageSDKAnalytics.sharedInstance.setUserAttribute(convertedDate.timeIntervalSince1970, withAttributeName: key)
            } else if let value = value as? Date {
                MoEngageSDKAnalytics.sharedInstance.setUserAttributeDate(value, withAttributeName: key)
            } else {
                MoEngageSDKAnalytics.sharedInstance.setUserAttribute(value, withAttributeName: key)
            }
        }
    }
    
    func dateFrom(isoDateString: String?) -> Date? {
        if let date = isoDateString, !date.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter.date(from: date)
        }
        return nil
    }
}

struct RSMoEngageConfig: Codable {
    private let _apiId: String?
    var apiId: String {
        return _apiId ?? ""
    }
    
    private let _region: String?
    var region: String {
        return _region ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case _apiId = "apiId"
        case _region = "region"
    }
}

@objc
public class RudderMoEngageDestination: RudderDestination {

    @objc
    public override init() {
        super.init()
        plugin = RSMoEngageDestination()
    }
}
