//
//  MemoryView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/30/22.
//

import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    @State private var selection: Set<Memory.ID> = Set()
    @State private var presentInspector: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Memory")
                    .font(.title)
                    .padding(.leading)
                    .padding(.top)
                Spacer()
            }
            
            // table seems to improperly receive propagated animations
            // manually invoking .animation resolves it
            Table(interpreter.cpu.memory.values.sorted(), selection: $selection) {
                TableColumn("Address") { memory in
                    HStack {
                        if interpreter.cpu.registers["sp"]! == memory.id {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            
                        }
                        
                        if interpreter.cpu.registers["fp"]! == memory.id {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                            
                        }
                        
                        Text("0x\(String(format: "%llX", memory.id))")
                            .font(.custom("Menlo Regular", size: 12))
                            .textSelection(.enabled)
                    }
                    .animation(.default, value: interpreter.cpu.registers)
                    .animation(.default, value: interpreter.cpu.memory)
                }
                
                TableColumn("Distance from SP") { memory in
                    Text(Int64(memory.id) >= interpreter.cpu.registers["sp"]! && Int64(memory.id) <= interpreter.cpu.registers["fp"]! ? "\(Int64(memory.id) - Int64(interpreter.cpu.registers["sp"]!))" : "-")
                        .font(.custom("Menlo Regular", size: 12))
                        .animation(.default, value: interpreter.cpu.registers)
                }
                
                TableColumn("Value") { memory in
                    MemoryValueColumnView(memory: memory)
                        .environmentObject(interpreter)
                }
            }
            .contextMenu {
                Menu("Display Mode") {
                    Button("Hex") {
                        for memID in selection {
                            interpreter.cpu.memory[memID]?.displayMode = "H"
                        }
                    }
                    
                    Button("Dec") {
                        for memID in selection {
                            interpreter.cpu.memory[memID]?.displayMode = "D"
                        }
                    }
                }
                
                Button("Inspector") {
                    presentInspector.toggle()
                }
            }
            .sheet(isPresented: $presentInspector) {
                InspectorView(memories: selection)
                    .environmentObject(interpreter)
            }
        }
    }
}

//struct MemoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        MemoryView()
//    }
//}
