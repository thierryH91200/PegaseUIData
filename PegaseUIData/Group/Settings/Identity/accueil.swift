//
//  exemple2.swift
//  test2
//
//  Created by Thierry hentic on 26/10/2024.
//


import SwiftUI



import SwiftUI

struct ContentView300: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Paramètres", systemImage: "gearshape")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Bienvenue sur la page d'accueil")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Page de profil")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Paramètres")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}



