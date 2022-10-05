//
//  MemoryValueColumnView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/4/22.
//

import SwiftUI

struct MemoryValueColumnView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    let memory: Memory
    
    @State private var displayMode: String = "H"
    
    var body: some View {
        HStack {
            
            Picker("", selection: $displayMode) {
                Text("H").tag("H")
                Text("D").tag("D")
            }
            .pickerStyle(.segmented)
            .frame(width: 50)
            
            if interpreter.lastTouchedMemory == memory.id {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
            
            Text(displayMode == "H" ? "0x\(String(format: "%llX", memory.value))" : "\(memory.value)")
                .font(.custom("Menlo Regular", size: 12))
                .textSelection(.enabled)
                .help("\(memory.value)")
        }
        .animation(.default, value: interpreter.lastTouchedMemory)
        .animation(.default, value: interpreter.cpu.memory)
    }
}

//struct MemoryValueColumnView_Previews: PreviewProvider {
//    static var previews: some View {
//        MemoryValueColumnView()
//    }
//}
