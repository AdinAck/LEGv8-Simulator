//
//  AboutView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/27/22.
//

import SwiftUI

struct AboutView: View {
    let version: String = "1.0 (Release)"
    
    var body: some View {
        HStack {
            Image("LEGv8-Simulator-Icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack(alignment: .leading) {
                Text("LEGv8 Simulator")
                    .font(.title)
                Text("Created by Adin Ackerman")
                    .font(.caption)
                
                Divider()
                
                Text("A SwiftUI application for writing, executing, and debugging LEGv8 assembly code with a series of visual tools.")
                    .padding(.bottom)
                
                Text("Version: \(version)")
                
                Spacer()
                
                // disclaimer
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("This software is community made and may have errors. Use at your own risk.")
                        .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // license
                Text("AdinAck/LEGv8-Simulator is licensed under the GNU General Public License v3.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(width: 600, height: 300)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
