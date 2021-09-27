//
//  SolsticeOverview.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct SolsticeOverview: View {
  @ObservedObject var calculator = SolarCalculator.shared
  @ObservedObject var location = LocationManager.shared
  @Binding var activeSheet: SheetPresentationState?
  
  @State var showingRemaining = false
  
  var body: some View {
    Group {
      if !isWatch, let placeName = getPlaceName() {
        Button(action: {
          self.activeSheet = .location
        }) {
          Label(placeName, systemImage: "location.fill")
        }.buttonStyle(BorderlessButtonStyle())
      }
      
      // MARK: Duration
      if let duration = calculator.today.duration {
        AdaptiveStack {
          if showingRemaining && calculator.today.ends.isInFuture && calculator.today.begins.isInPast {
            Label("Remaining", systemImage: "hourglass")
              .symbolRenderingMode(.monochrome)
            Spacer()
            Text("\(Date().distance(to: calculator.today.ends).colloquialTimeString)")
          } else {
            Label("Total Daylight", systemImage: "sun.max")
            Spacer()
            Text("\(duration.colloquialTimeString)")
          }
        }.onTapGesture {
          withAnimation(.interactiveSpring()) {
            showingRemaining.toggle()
          }
        }
      }
      
      // MARK: Sunrise
      if let begins = calculator.today.begins {
        AdaptiveStack {
          Label("Sunrise", systemImage: "sunrise.fill")
          Spacer()
          Text("\(begins, style: .time)")
        }
      }
      
      if let peak = calculator.today.peak {
        AdaptiveStack {
          Label("Culmination", systemImage: "sun.max.fill")
          Spacer()
          Text("\(peak, style: .time)")
        }
      }
      
      // MARK: Sunset
      if let ends = calculator.today.ends {
        AdaptiveStack {
          Label("Sunset", systemImage: "sunset.fill")
          Spacer()
          Text("\(ends, style: .time)")
        }
      }
    }
  }
  
  func getPlaceName() -> String {
    let sublocality = location.placemark?.subLocality
    let locality = location.placemark?.locality
    
    let builtString = [sublocality, locality]
      .compactMap { $0 }
      .joined(separator: ", ")
    
    return builtString.count == 0 ? "Current Location" : builtString
  }
}

struct AdaptiveStack<Content: View>: View {
  var content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    if isWatch {
      VStack(alignment: .leading) {
        content()
      }
    } else {
      HStack {
        content()
      }
    }
  }
}

struct SolsticeOverview_Previews: PreviewProvider {
  static var previews: some View {
    SolsticeOverview(activeSheet: .constant(nil))
  }
}
