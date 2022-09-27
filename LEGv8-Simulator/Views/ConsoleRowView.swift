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
        let prefix = String(format: "%04d", entry.line)
        
        HStack {
            if entry.message != "" {
                Text("\(prefix): ")
                    .font(.custom("Menlo Regular", size: 12))
            }
            
            Text(entry.message)
                .font(.custom("Menlo Regular", size: 12))
                .foregroundColor(color)
        }
    }
}

struct ConsoleRowView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleRowView(entry: LogEntry(id: 1, line: 1, message: "Test", type: .normal), color: .red)
    }
}
