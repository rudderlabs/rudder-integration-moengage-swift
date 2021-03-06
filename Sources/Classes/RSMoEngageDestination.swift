//
//  RSMoEngageDestination.swift
//  RudderMoEngage
//
//  Created by Abhishek Pandey on 18/03/22.
//

import Foundation
import Rudder
import MoEngage

class RSMoEngageDestination: NSObject, RSDestinationPlugin, UNUserNotificationCenterDelegate {
    let type = PluginType.destination
    let key = "MoEngage"
    var client: RSClient?
    var controller = RSController()

    func update(serverConfig: RSServerConfig, type: UpdateType) {
        guard type == .initial else { return }
        guard let moEngageConfig: RSMoEngageConfig = serverConfig.getConfig(forPlugin: self) else {
            client?.log(message: "Failed to Initialize MoEngage Factory", logLevel: .warning)
            return
        }
        // Check if debug mode is on or off
#if DEBUG
        MoEngage.sharedInstance().initializeDev(withAppID: moEngageConfig.apiId)
#else
        MoEngage.sharedInstance().initializeProd(withAppID: moEngageConfig.apiId)
#endif
        if moEngageConfig.region == "EU" {
            MoEngage.redirectData(to: MOE_REGION_EU)
        }
        
        if UNUserNotificationCenter.current().delegate == nil {
           UNUserNotificationCenter.current().delegate = self
        }
        
        client?.log(message: "Initializing MoEngage SDK", logLevel: .debug)
    }

    func identify(message: IdentifyMessage) -> IdentifyMessage? {
        reset()
        if let anonymousId = message.anonymousId {
            MoEngage.sharedInstance().setUserAttribute(anonymousId, forKey: "anonymousId")
        }
        if let userId = message.userId {
            MoEngage.sharedInstance().setUserAttribute(userId, forKey: USER_ATTRIBUTE_UNIQUE_ID)
            MoEngage.sharedInstance().setUserUniqueID(userId)
        }
        
        if let traits = message.traits, !traits.isEmpty {
            handle(traits: traits)
        }
        return message
    }

    func track(message: TrackMessage) -> TrackMessage? {
        if !message.event.isEmpty {
            switch message.event {
            case RSEvents.LifeCycle.applicationInstalled: MoEngage.sharedInstance().appStatus(INSTALL)
            case RSEvents.LifeCycle.applicationUpdated: MoEngage.sharedInstance().appStatus(UPDATE)
            default:
                if let properties = message.properties, !properties.isEmpty {
                    let eventProperties: MOProperties = MOProperties()
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
                    MoEngage.sharedInstance().trackEvent(message.event, with: eventProperties)
                } else {
                // If message.properties is empty
                    MoEngage.sharedInstance().trackEvent(message.event, with: nil)
                }
            }
        }
        return message
    }
    
    func alias(message: AliasMessage) -> AliasMessage? {
        if let newId = message.userId {
            MoEngage.sharedInstance().setAlias(newId)
        }
        return message
    }

    func reset() {
        MoEngage.sharedInstance().resetUser()
        client?.log(message: "MoEngage Reset API: 'MoEngage.sharedInstance().resetUser()' is called.", logLevel: .debug)
    }
    
    func flush() {
        MoEngage.sharedInstance().syncNow()
        client?.log(message: "MoEngage Flush API: 'MoEngage.sharedInstance().syncNow()' is called.", logLevel: .debug)
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)

// MARK: - Push Notification methods

extension RSMoEngageDestination: RSPushNotifications {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MoEngage.sharedInstance().setPushToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        MoEngage.sharedInstance().didFailToRegisterForPush()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        MoEngage.sharedInstance().didReceieveNotificationinApplication(application, withInfo: userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        MoEngage.sharedInstance().userNotificationCenter(center, didReceive: response)
    }
}

#endif

// MARK: - Support methods

extension RSMoEngageDestination {
    func handle(traits: [String: Any]) {
        for (key, value) in traits {
            if value is String || value is NSNumber || value is Date {
                switch key {
                case RSKeys.Identify.Traits.email: MoEngage.sharedInstance().setUserEmailID(value as? String)
                case RSKeys.Identify.Traits.name: MoEngage.sharedInstance().setUserName(value as? String)
                case RSKeys.Identify.Traits.phone: MoEngage.sharedInstance().setUserMobileNo(value)
                case RSKeys.Identify.Traits.firstName: MoEngage.sharedInstance().setUserAttribute(value, forKey: USER_ATTRIBUTE_USER_FIRST_NAME)
                case RSKeys.Identify.Traits.lastName: MoEngage.sharedInstance().setUserLastName(value as? String)
                case RSKeys.Identify.Traits.gender: MoEngage.sharedInstance().setUserAttribute(value, forKey: USER_ATTRIBUTE_USER_GENDER)
                case RSKeys.Identify.Traits.birthday: identifyDateUserAttribute(value: value, key: USER_ATTRIBUTE_USER_BDAY)
                case RSKeys.Identify.Traits.address: MoEngage.sharedInstance().setUserAttribute(value, forKey: RSKeys.Identify.Traits.address)
                case RSKeys.Identify.Traits.age: MoEngage.sharedInstance().setUserAttribute(value, forKey: RSKeys.Identify.Traits.age)
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
                MoEngage.sharedInstance().setUserAttributeTimestamp(convertedDate.timeIntervalSince1970, forKey: key)
            } else if let value = value as? Date {
                MoEngage.sharedInstance().setUserAttributeDate(value, forKey: key)
            } else {
                MoEngage.sharedInstance().setUserAttribute(value, forKey: key)
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
