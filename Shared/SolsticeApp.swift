//
//  SolsticeApp.swift
//  Shared
//
//  Created by Daniel Eden on 05/01/2021.
//

import SwiftUI
import StoreKit

@main
struct SolsticeApp: App {
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif
  @ObservedObject var locationManager = LocationManager.shared
  @AppStorage("sessionCount") var sessionCount = 0
  
  var body: some Scene {
    WindowGroup {
      Group {
        if locationManager.status == .authorizedAlways || locationManager.status == .authorizedWhenInUse {
          TimelineView(.everyMinute) { context in
            ContentView()
              .environmentObject(locationManager)
              .onAppear {
                locationManager.start()
              }
          }
        } else if locationManager.status == .notDetermined {
          VStack {
            LandingView()
              .frame(maxWidth: 500)
          }
        } else {
          VStack {
            PermissionDeniedView()
              .frame(maxWidth: 500)
          }
        }
      }
      #if os(iOS)
      .onDisappear {
        (UIApplication.shared.delegate as! AppDelegate).submitBackgroundTask()
      }
      #endif
      .navigationViewStyle(StackNavigationViewStyle())
      .symbolRenderingMode(.hierarchical)
      .onAppear {
        sessionCount += 1
        
        #if os(iOS)
        if sessionCount >= 3,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            SKStoreReviewController.requestReview(in: windowScene)
          }
        }
        #endif
      }
    }
  }
}
