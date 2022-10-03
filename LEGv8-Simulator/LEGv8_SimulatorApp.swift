//
//  LEGv8_SimulatorApp.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import SwiftUI

@main
struct LEGv8_SimulatorApp: App {
    @StateObject var settings: SettingsModel = SettingsModel()
    
    var body: some Scene {
        DocumentGroup(newDocument: Document()) { file in
            ContentView(document: file.$document)
                .environmentObject(settings)
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
        #endif
    }
}
