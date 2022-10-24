//
//  HistoryView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/24/22.
//

import SwiftUI

struct HistoryView: View {
    let displayMode: String
    let history: [HistoryEntry]
    
    @State private var selection: Int?
    
    var body: some View {
        Table(history, selection: $selection) {
            TableColumn("Step") { entry in
                Text("\(entry.id)")
                    .font(.custom("Menlo Regular", size: 12))
            }
            
            TableColumn("Line") { entry in
                Text("\(entry.line)")
                    .font(.custom("Menlo Regular", size: 12))
            }
            
            TableColumn("Value") { entry in
                Text(displayMode == "H" ? "0x\(String(format: "%llX", entry.value))" : "\(entry.value)")
                    .font(.custom("Menlo Regular", size: 12))
                    .foregroundColor(entry.type == .write ? .blue : .purple)
                    .textSelection(.enabled)
            }
        }
    }
}

//struct HistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        HistoryView()
//    }
//}
