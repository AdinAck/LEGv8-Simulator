//
//  RegisterRowView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/4/22.
//

import SwiftUI

struct RegisterRowView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    let name: String
    
    @State private var displayMode: String = "H"
    @State private var isPresented: Bool = false
    
    var body: some View {
        HStack {
            Text(name)
                .font(.custom("Menlo Regular", size: 12))
            
            Spacer()
            
            HStack {
                if interpreter.lastTouchedRegister == name {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                }
                
                if interpreter.lastUsedRegisters.contains(name) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.purple)
                }
                
                let value = interpreter.cpu.registers[name]!
                
                Text(displayMode == "H" ? "0x\(String(format: "%llX", value))" : "\(value)")
                    .font(.custom("Menlo Regular", size: 12))
                    .textSelection(.enabled)
                
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $isPresented) {
                    if let history = interpreter.history.registers[name]?.values.sorted() {
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
            }
            
            Picker("", selection: $displayMode) {
                Text("H").tag("H")
                Text("D").tag("D")
            }
            .pickerStyle(.segmented)
            .frame(width: 50)
            .padding(.trailing)
        }
    }
}

//struct RegisterRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        RegisterRowView()
//    }
//}
