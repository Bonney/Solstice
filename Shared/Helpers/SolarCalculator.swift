//
//  SolarCalculator.swift
//  Solstice
//
//  Created by Daniel Eden on 05/01/2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI
import Solar

enum SolarEventType {
  case sunrise(at: Date), sunset(at: Date)
  
  func date() -> Date {
    switch self {
    case .sunrise(let at):
      return at
    case .sunset(let at):
      return at
    }
  }
}

typealias DaylightTime = (minutes: Int, seconds: Int)

struct Daylight: Hashable {
  var begins: Date
  var ends: Date
  var nauticalBegins = Date()
  var nauticalEnds = Date()
  
  static var Default = Daylight(begins: Date(), ends: Date())
  
  var duration: TimeInterval {
    begins.distance(to: ends)
  }
  
  func difference(from: Daylight) -> TimeInterval {
    return self.duration - from.duration
  }
  
  var peak: Date? {
    let interval = ends.timeIntervalSince(begins)
    let peak = begins.advanced(by: interval / 2)
    
    return peak
  }
}

class SolarCalculator: NSObject, ObservableObject {
  static var shared = SolarCalculator()
  @AppStorage(UDValues.cachedLatitude) private var latitude
  @AppStorage(UDValues.cachedLongitude) private var longitude
  
  @Published var dateOffset = 0.0 {
    didSet { updateBaseDate() }
  }
  
  @Published var timezone = TimeZone.current {
    didSet { updateBaseDate() }
  }
  
  @Published var baseDate: Date
  
  init(baseDate: Date = .now) {
    self.baseDate = baseDate
    super.init()
    updateBaseDate()
  }
  
  func updateBaseDate() {
    var offset = DateComponents()
    offset.day = Int(dateOffset)
    
    let date = Date.now
    
    let offsetDate = applyTimezoneOffset(to: Calendar.current.date(byAdding: offset, to: date)!)
    
    DispatchQueue.main.async {
      self.baseDate = offsetDate
      self.objectWillChange.send()
    }
  }
  
  private func applyTimezoneOffset(to date: Date) -> Date {
    let currentTimezone = TimeZone.current.secondsFromGMT()
    let offsetTimezone = timezone.secondsFromGMT()
    let offsetAmount = currentTimezone < offsetTimezone
      ? max(currentTimezone, offsetTimezone) - min(currentTimezone, offsetTimezone)
      : min(currentTimezone, offsetTimezone) - max(currentTimezone, offsetTimezone)

    let components = DateComponents(second: offsetAmount)
    return Calendar.current.date(byAdding: components, to: date)!
  }
  
  private func createDaylight(from solar: Solar) -> Daylight {
    if let sunrise = solar.sunrise, let sunset = solar.sunset,
       let bSunrise = solar.nauticalSunrise, let bSunset = solar.nauticalSunset {
      return Daylight(
        begins: applyTimezoneOffset(to: sunrise),
        ends: applyTimezoneOffset(to: sunset),
        nauticalBegins: applyTimezoneOffset(to: bSunrise),
        nauticalEnds: applyTimezoneOffset(to: bSunset)
      )
    }
    
    return .Default
  }
  
  private var baseDateAtNoon: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
  }
  
  private var todaysDate: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate)!
  }
  
  private let locationManager = LocationManager.shared
  private var coords: CLLocationCoordinate2D {
    if let coords =
          locationManager.location?.coordinate,
       CLLocationCoordinate2DIsValid(coords) {
      return coords
    } else {
      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
  }
  
  func getNextSolarEvent() -> SolarEventType {
    if today.begins.isInFuture {
      return .sunrise(at: today.begins)
    } else if today.ends.isInFuture {
      return .sunset(at: today.ends)
    } else {
      return .sunrise(at: tomorrow.begins)
    }
  }
  
  var prevSolstice: Date {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    guard let month = components.month,
          let day = components.day,
          let year = components.year else { return Date() }
    
    if month >= 12 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: year, month: 12, day: 22))!
    } else if (month >= 6 && day >= 22) || month >= 7 {
      return Calendar.current.date(from: DateComponents(year: year, month: 6, day: 22))!
    } else {
      return Calendar.current.date(from: DateComponents(year: year - 1, month: 12, day: 22))!
    }
  }
  
  var nextSolstice: Date {
    let components = Calendar.current.dateComponents([.month, .day, .year], from: todaysDate)
    guard let month = components.month,
          let day = components.day,
          let year = components.year else { return Date() }
    
    if month >= 12 && day >= 22 {
      return Calendar.current.date(from: DateComponents(year: year + 1, month: 6, day: 22))!
    } else if (month >= 6 && day >= 22) || month >= 7 {
      return Calendar.current.date(from: DateComponents(year: year, month: 12, day: 22))!
    } else {
      return Calendar.current.date(from: DateComponents(year: year, month: 6, day: 22))!
    }
  }
  
  var prevSolsticeDaylight: Daylight {
    guard let solar = Solar(for: prevSolstice, coordinate: coords) else { return .Default }
    
    return createDaylight(from: solar)
  }
  
  var today: Daylight {
    guard let solar = Solar(for: baseDateAtNoon, coordinate: coords) else { return .Default }
    
    return createDaylight(from: solar)
  }
  
  var yesterday: Daylight {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: baseDateAtNoon)!
    guard let solar = Solar(for: yesterday, coordinate: coords) else { return .Default }
    
    return createDaylight(from: solar)
  }
  
  var tomorrow: Daylight {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: baseDateAtNoon)!
    guard let solar = Solar(for: tomorrow, coordinate: coords) else { return .Default }
    
    return createDaylight(from: solar)
  }
  
  var differenceString: String {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .medium
    formatter.formattingContext = .middleOfSentence
    
    let yesterday = baseDate.isToday ? yesterday : SolarCalculator(baseDate: .now).today
    var string = today.difference(from: yesterday).colloquialTimeString
    
    if today.difference(from: yesterday) >= 0 {
      string += " more"
    } else {
      string += " less"
    }
    
    string += " daylight \(baseDate.isToday ? "" : "on ")\(formatter.string(from: baseDate)) than \(formatter.string(from: yesterday.begins))."
    
    return string
  }
}
