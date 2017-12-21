//
//  Utilities.swift
//  WorldAloud
//
//  Created by Andre Guerra on 21/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import Foundation

/// Broadcasts a message thru NotificationCenter
///
/// - Parameter name: the unique string value of the notification
public func broadcastNotification(name: String) {
    let notification = Notification.Name(rawValue: name)
    NotificationCenter.default.post(name: notification, object: nil)
}
