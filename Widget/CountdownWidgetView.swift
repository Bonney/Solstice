//
//  SolsticeCountdownWidgetView.swift
//  WidgetExtension
//
//  Created by Daniel Eden on 11/04/2021.
//

import SwiftUI
import WidgetKit

enum SunEvent {
  case sunrise(at: Date)
  case sunset(at: Date)
  
  var description: String {
    switch self {
    case .sunrise(_):
      return "sunrise"
    case .sunset(_):
      return "sunset"
    }
  }
}

struct CountdownWidgetView: View {
  @Environment(\.widgetFamily) var family
  @Environment(\.sizeCategory) var sizeCategory
  @EnvironmentObject var calculator: SolarCalculator
  
  var displaySize: Font {
    switch family {
    case .systemSmall:
      return sizeCategory < .extraLarge ? .headline : .footnote
    default:
      return .title2
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: currentEventImageName)
        .font(displaySize)
      
      Spacer(minLength: 0)
      
      Text("\(eventDate, style: .relative) until \(nextSunEvent.description)")
        .font(displaySize.weight(.medium))
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
      
      Label("\(eventDate, style: .time)", systemImage: nextEventImageName)
        .font(.footnote.weight(.semibold))
    }
    .monospacedDigit()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .center))
    .background(LinearGradient(colors: SkyGradient.getCurrentPalette(for: calculator.today), startPoint: .top, endPoint: .bottom))
    .colorScheme(.dark)
    .symbolRenderingMode(.hierarchical)
    .symbolVariant(.fill)
  }
  
  var isDaytime: Bool {
    calculator.today.begins.isInPast && calculator.today.ends.isInFuture
  }
  
  var nextSunEvent: SunEvent {
    if isDaytime {
      return .sunset(at: calculator.today.ends)
    } else if calculator.today.begins.isInFuture {
      return .sunrise(at: calculator.today.begins)
    } else {
      return .sunrise(at: calculator.tomorrow.begins)
    }
  }
  
  var currentEventImageName: String {
    switch nextSunEvent {
    case .sunrise(_):
      return "moon.stars"
    case .sunset(_):
      return "sun.max"
    }
  }
  
  var nextEventImageName: String {
    switch nextSunEvent {
    case .sunrise(_):
      return "sunrise"
    case .sunset(_):
      return "sunset"
    }
  }
  
  var eventDate: Date {
    switch nextSunEvent {
    case .sunrise(let at):
      return at
    case .sunset(let at):
      return at
    }
  }
}

struct SolsticeCountdownWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CountdownWidgetView()
        .previewContext(WidgetPreviewContext(family: .systemMedium))
      CountdownWidgetView()
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    .environmentObject(SolarCalculator())
  }
}
