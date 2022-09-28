//
//  ConsoleRowView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/26/22.
//

import SwiftUI

struct ConsoleRowView: View {
    let entry: LogEntry
    let color: Color
    
    var body: some View {
        let id = String(format: "%04d", entry.id)
        let line = String(format: "%04d", entry.line)
        
        HStack {
            if entry.message != "" {
                Text("\(id) | \(line): ")
                    .font(.custom("Menlo Regular", size: 12))
                    .textSelection(.enabled)
            }
            
            Text(entry.message)
                .font(.custom("Menlo Regular", size: 12))
                .foregroundColor(color)
                .textSelection(.enabled)
        }
    }
}

struct ConsoleRowView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleRowView(entry: LogEntry(id: 1, line: 1, message: "Test", type: .normal), color: .red)
    }
}
