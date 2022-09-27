//
//  FileIO.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/26/22.
//

import Foundation
import SwiftUI

class FileIO: ObservableObject {
    @Published var text: String = ""
    
    @Published var url: URL?
    
    func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.assemblyLanguageSource]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        switch response {
        case .OK:
            text = try! String(contentsOf: openPanel.url!, encoding: .utf8)
            url = openPanel.url
        default:
            print("Failed to load image.")
        }
    }
}
