//
//  PermissionDeniedView.swift
//  Solstice
//
//  Created by Daniel Eden on 07/01/2021.
//

import SwiftUI

struct PermissionDeniedView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Image(systemName: "location.slash.fill")
        .font(Font.system(.largeTitle, design: .rounded).bold())
        .foregroundColor(.red)
        .padding(.bottom)
      
      Text("Solstice needs access to your location to work properly.")
        .font(Font.system(.largeTitle, design: .rounded).bold())
        .padding(.bottom)
      Text("Location access has been denied or revoked. To use Solstice, go to the Settings app and grant Solstice permission to access your location.")
        .padding(.bottom)
      
      #if os(iOS)
      Button(action: { openSettings() }) {
        Label("Open Settings", systemImage: "gear")
          .frame(maxWidth: .infinity)
          .font(Font.subheadline.bold())
          .foregroundColor(.primary)
          .colorInvert()
          .padding()
      }.background(
        Capsule().fill(Color.primary)
      )
      #endif
    }.padding()
  }
  
  func openSettings() {
    #if os(iOS)
    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    #endif
  }
}

struct PermissionDeniedView_Previews: PreviewProvider {
  static var previews: some View {
    PermissionDeniedView()
  }
}
