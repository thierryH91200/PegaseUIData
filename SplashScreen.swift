//
//  SplashScreen.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 27/03/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"

    var body: some View {
        if isActive {
            ContentView100() // La vue principale après le splash
        } else {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all) // Fond blanc ou personnalisé
                VStack {
                    Image( "pegase" ) // Remplace par ton logo
                        .resizable()
                        .scaledToFit()
                        .frame(width: 800, height: 800)

                    Text("PegaseUIData") // Nom de l’app
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                    
                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.footnote)
                        .foregroundColor(.gray)

                }
            }
            .onAppear {

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
