//
//  SettingsView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/27/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: SettingsModel
    @State var execLimitString: String = ""
    
    var body: some View {
        TabView() {
            List {
                HStack {
                    Text("Execution limit:")
                    
                    TextField("", text: $execLimitString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: execLimitString) { newValue in
                            if let val = Int(newValue) {
                                model.executionLimit = val
                            }
                        }
                }
                
                Toggle("Build on type", isOn: $model.buildOnType)
                    .toggleStyle(.switch)
            }
            .frame(width: 400, height: 400)
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .onAppear {
                execLimitString = String(model.executionLimit)
            }
            
            AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
