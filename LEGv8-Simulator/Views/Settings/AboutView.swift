//
//  AboutView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/27/22.
//

import SwiftUI

struct AboutView: View {
    let version: String = "1.0"
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Legv8 Simulator")
                .font(.title)
            Text("Created by Adin Ackerman")
                .font(.caption)
            
            Divider()
            
            Text("A SwiftUI application for writing, executing, and debugging LEGv8 assembly code with a series of visual tools.")
                .padding(.bottom)
            
            Text("Version: \(version)")
            
            Spacer()
            // license
            Text("AdinAck/LEGv8-Simulator is licensed under the GNU General Public License v3.0")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
