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
    
    @AppStorage("executionLimit") var executionLimit: Int = 1000
    @AppStorage("buildOnType") var buildOnType: Bool = false
    
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
                                executionLimit = val
                            }
                        }
                }
                
                Toggle("Build on type", isOn: $buildOnType)
                    .toggleStyle(.switch)
            }
            .frame(width: 400, height: 400)
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .onAppear {
                execLimitString = String(executionLimit)
                model.executionLimit = executionLimit
                model.buildOnType = buildOnType
            }
            .onChange(of: executionLimit) { newValue in
                model.executionLimit = executionLimit
            }
            .onChange(of: buildOnType) { newValue in
                model.buildOnType = buildOnType
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
