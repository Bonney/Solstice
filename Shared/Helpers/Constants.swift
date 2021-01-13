//
//  Constants.swift
//  Solstice
//
//  Created by Daniel Eden on 09/01/2021.
//

import Foundation
import SwiftUI

typealias UDValuePair<T> = (key: String, value: T)

let defaultNotificationDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
let solsticeSuiteName = "group.me.daneden.Solstice"
let solsticeUDStore = UserDefaults(suiteName: solsticeSuiteName)

struct UDValues {
  static let cachedLatitude: UDValuePair = ("cachedLatitude", 51.5074)
  static let cachedLongitude: UDValuePair = ("cachedLongitude", 0.1278)
  static let notificationTime: UDValuePair<TimeInterval> = ("notifTime", defaultNotificationDate.timeIntervalSince1970)
  static let notificationsEnabled: UDValuePair = ("notifsEnabled", false)
}

let stiffSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)
let easingSpringAnimation = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 1)
