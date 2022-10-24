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
    @State private var isPresented: Bool = false
    
    var body: some View {
        HStack {
            
            Picker("", selection: $displayMode) {
                Text("H").tag("H")
                Text("D").tag("D")
            }
            .pickerStyle(.segmented)
            .frame(width: 50)
            
            Button {
                isPresented.toggle()
            } label: {
                Image(systemName: "chart.xyaxis.line")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isPresented) {
                if let history = interpreter.history.memory[memory.id]?.values.sorted() {
                    HistoryView(displayMode: displayMode, history: history)
                        .frame(width: 500, height: 300)
                        .animation(.default, value: history)
                } else {
                    Image(systemName: "nosign")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(width: 500, height: 300)
                }
            }
            
            if interpreter.lastTouchedMemory == memory.id {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
            
            if interpreter.lastUsedMemory == memory.id {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.purple)
            }
            
            Text(displayMode == "H" ? "0x\(String(format: "%llX", memory.value))" : "\(memory.value)")
                .font(.custom("Menlo Regular", size: 12))
                .textSelection(.enabled)
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
