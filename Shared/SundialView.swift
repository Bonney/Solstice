//
//  SundialView.swift
//  Solstice
//
//  Created by Daniel Eden on 06/01/2021.
//

import SwiftUI

struct SundialView: View {
  private var calculator = SolarCalculator()
  @ObservedObject private var location = LocationManager.shared
  
  private var circleSize: CGFloat = 24.0
  
  private var offset: Double {
    let daylightBegins = calculator.today?.begins ?? dayBegins
    let daylightEnds = calculator.today?.ends ?? dayEnds
    let daylightLength = daylightBegins.distance(to: daylightEnds)
    let dayLength = dayBegins.distance(to: dayEnds)
    
    return daylightLength / dayLength
  }
  
  private var sunColor = Color.primary
  private var duration: DateComponents? {
    return calculator.today?.duration
  }
  
  private var waveSize = 80.0
  private let dayBegins = Date().startOfDay
  private let dayEnds = Date().endOfDay
  private var currentPosition: Double {
    let dayLength = dayBegins.distance(to: dayEnds)
    return dayBegins.distance(to: Date()) / dayLength
  }
  
  
  var quarterOffset: Double {
    offset / 4
  }
  
  var wave: some View {
    Wave(amplitude: waveSize, frequency: .pi * 2, phase: .pi / 2)
      .stroke(Color.opaqueSeparator, lineWidth: 3)
      .offset(y: -1.5)
  }
  
  var body: some View {
    ZStack {
      GeometryReader { geometry in
        ZStack {
          wave
          
          Circle()
            .fill(sunColor)
            .frame(width: circleSize)
            .position(x: -circleSize / 2, y: geometry.size.height / 2)
            .offset(
              x: geometry.size.width * CGFloat(currentPosition),
              y: CGFloat(sin((currentPosition - .pi / 4) * .pi * 2) * waveSize))
            .shadow(color: sunColor.opacity(0.6), radius: 10, x: 0.0, y: 0.0)
          
          Rectangle()
            .fill(Color.systemBackground.opacity(0.5))
            .frame(height: CGFloat(waveSize * 2) - CGFloat(waveSize * offset))
            .overlay(
              Rectangle()
                .frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color.opaqueSeparator),
              alignment: .top
            )
            .offset(y: CGFloat(offset * waveSize))
          
          if let duration = duration {
            Text("\(duration.hour ?? 0)hrs, \(duration.minute ?? 0)min")
              .font(.footnote)
              .foregroundColor(.secondary)
              .padding(4)
              .padding(.horizontal, 4)
              .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
              .cornerRadius(8)
          }
        }.offset(y: CGFloat(offset * waveSize))
      }
    }
  }
}

struct SundialView_Previews: PreviewProvider {
    static var previews: some View {
      SundialView()
    }
}
