//
//  SettingsView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/27/22.
//

import SwiftUI

struct SettingsView: View {
    @State var execLimit: String = "1000"
    
    var body: some View {
        TabView {
            List {
                HStack {
                    Text("Execution limit:")
                    
                    TextField("", text: $execLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            
            List {
                Text("Test")
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 400, height: 400)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
