//
//  MemoryView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/30/22.
//

import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    var body: some View {
        VStack {
            HStack {
                Text("Memory")
                    .font(.title)
                    .padding(.leading)
                    .padding(.top)
                Spacer()
            }
            
            Table(interpreter.cpu.memory.values.sorted()) {
                TableColumn("Address") { memory in
                    HStack {
                        if interpreter.cpu.registers["sp"]! == memory.id {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            
                        }
                        
                        Text("0x\(String(format: "%llX", memory.id))")
                            .font(.custom("Menlo Regular", size: 12))
                    }
                }
                
                TableColumn("Distance from SP") { memory in
                    Text("\(Int64(memory.id) - Int64(interpreter.cpu.registers["sp"]!))")
                        .font(.custom("Menlo Regular", size: 12))
                }
                
                TableColumn("Value") { memory in
                    HStack {
                        if interpreter.lastTouchedMemory == memory.id {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.blue)
                        }
                        
                        Text("0x\(String(format: "%llX", memory.value))")
                            .font(.custom("Menlo Regular", size: 12))
                            .textSelection(.enabled)
                            .help("\(memory.value)")
                    }
                }
            }
        }
    }
}

//struct MemoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        MemoryView()
//    }
//}
