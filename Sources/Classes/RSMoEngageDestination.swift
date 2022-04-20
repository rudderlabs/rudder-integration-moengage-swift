//
//  RSMoEngageDestination.swift
//  RudderMoEngage
//
//  Created by Abhishek Pandey on 18/03/22.
//

import Foundation
import RudderStack
import MoEngage

class RSMoEngageDestination: NSObject, RSDestinationPlugin, UNUserNotificationCenterDelegate {
    let type = PluginType.destination
    let key = "MoEngage"
    var client: RSClient?
    var controller = RSController()

    func update(serverConfig: RSServerConfig, type: UpdateType) {
        guard type == .initial else { return }
        guard let moEngageConfig: RudderMoEngageConfig = serverConfig.getConfig(forPlugin: self) else {
            client?.log(message: "Failed to Initialize MoEngage Factory", logLevel: .warning)
            return
        }
        
        //check if debug mode is on or off
#if DEBUG
        MoEngage.sharedInstance().initializeDev(withAppID: moEngageConfig.apiId)
#else
        MoEngage.sharedInstance().initializeProd(withAppID: moEngageConfig.apiId)
#endif
        if moEngageConfig.region == "EU" {
            MoEngage.redirectData(to: MOE_REGION_EU)
        }
        
        if #available(iOS 10.0, *) {
            if UNUserNotificationCenter.current().delegate == nil {
               UNUserNotificationCenter.current().delegate = self
            }
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
        
        if let traits = filterProperties(properties: message.traits) {
            handleTraits(traits: traits)
        }
        return message
    }

    func track(message: TrackMessage) -> TrackMessage? {
        if !message.event.isEmpty {
            switch (message.event) {
            case "Application Installed": MoEngage.sharedInstance().appStatus(INSTALL)
            case "Application Updated": MoEngage.sharedInstance().appStatus(UPDATE)
            default:
                if let properties = message.properties, !properties.isEmpty {
                    let eventProperties: MOProperties = MOProperties.init()
                    for (key, value) in properties {
                        switch value {
                        case let val as String:
                            if let date: Date = dateFromISOdateStr(isoDateStr: val) {
                                eventProperties.addDateAttribute(date, withName: key)
                                break;
                            }
                            eventProperties.addAttribute(val, withName: key)
                        case let val as NSNumber:
                            eventProperties.addAttribute(val, withName: key)
                        default: break
                        }
                    }
                    MoEngage.sharedInstance().trackEvent(message.event, with: eventProperties)
                    break
                }
                MoEngage.sharedInstance().trackEvent(message.event, with: nil)
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
    
    // MARK: - User Notification Center delegate methods

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .alert])
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        MoEngage.sharedInstance().userNotificationCenter(center, didReceive: response)
        completionHandler()
    }
}

// MARK: - Application Life cycle methods

func applicationDidFinishLaunching(_ notification: Notification) {
    DispatchQueue.main.async(execute: {
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            UIApplication.shared.registerForRemoteNotifications()
        }
    })
}

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

// MARK: - Push Notification methods

extension RSMoEngageDestination: RSPushNotifications {
    func registeredForRemoteNotifications(deviceToken: Data) {
        MoEngage.sharedInstance().setPushToken(deviceToken)
    }
    
    func failedToRegisterForRemoteNotification(error: Error?) {
        MoEngage.sharedInstance().didFailToRegisterForPush()
    }
    
    func receivedRemoteNotification(userInfo: [AnyHashable: Any]) {
        MoEngage.sharedInstance().didReceieveNotificationinApplication(UIApplication.shared, withInfo: userInfo)
    }
    
    func handleAction(withIdentifier identifier: String, forRemoteNotification userInfo: [AnyHashable: Any]) {
        MoEngage.sharedInstance().handleAction(withIdentifier: identifier, forRemoteNotification: userInfo)
    }
}

#endif

// MARK: - Support methods

extension RSMoEngageDestination {
    func filterProperties(properties: [String: Any]?) -> [String: Any]? {
        var filteredProperties: [String: Any]?
        if let properties = properties {
            filteredProperties = [String: Any]()
            for (key, value) in properties {
                switch value {
                case let val as String:
                    filteredProperties?[key] = val
                case let val as NSNumber:
                    filteredProperties?[key] = val
                default: break
                }
            }
        }
        return filteredProperties
    }
    
    func handleTraits(traits: [String: Any]) {
        if traits.isEmpty {
            return
        }
        for (key, value) in traits {
            switch key {
            case "email": MoEngage.sharedInstance().setUserEmailID(value as? String)
            case "name": MoEngage.sharedInstance().setUserName(value as? String)
            case "phone": MoEngage.sharedInstance().setUserMobileNo(value)
            case "firstName": MoEngage.sharedInstance().setUserAttribute(value, forKey: USER_ATTRIBUTE_USER_FIRST_NAME)
            case "lastName": MoEngage.sharedInstance().setUserLastName(value as? String)
            case "gender": MoEngage.sharedInstance().setUserAttribute(value, forKey: USER_ATTRIBUTE_USER_GENDER)
            case "birthday": identifyDateUserAttribute(value, attr_name: USER_ATTRIBUTE_USER_BDAY)
            case "address": MoEngage.sharedInstance().setUserAttribute(value, forKey: "address")
            case "age": MoEngage.sharedInstance().setUserAttribute(value, forKey: "age")
            default: identifyDateUserAttribute(value, attr_name: key)
            }
        }
    }
    
    func identifyDateUserAttribute(_ value: Any?, attr_name: String?) {
        if let attr_name = attr_name {
            // Verify if the value is of type Date or not
            if let value = value as? String {
                if let convertedDate = dateFromISOdateStr(isoDateStr: value) {
                    MoEngage.sharedInstance().setUserAttributeTimestamp(convertedDate.timeIntervalSince1970, forKey: attr_name)
                    return
                }
            }
            MoEngage.sharedInstance().setUserAttribute(value, forKey: attr_name)
        }
    }
    
    func dateFromISOdateStr(isoDateStr: Any?) -> Date? {
        if let date: String = isoDateStr as? String, !date.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter.date(from: date) ?? nil
        }
        return nil
    }
}

struct RudderMoEngageConfig: Codable {
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

    public override init() {
        super.init()
        plugin = RSMoEngageDestination()
    }
}
