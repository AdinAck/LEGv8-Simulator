//
//  RegisterView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/30/22.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    @State private var selection1: String?
    @State private var selection2: String?
    
    var body: some View {
        VStack {
            HStack {
                Text("Registers")
                    .font(.title)
                    .padding(.leading)
                    .padding(.top)
                Spacer()
            }
            
            FlagView()
                .environmentObject(interpreter)
            
            HStack {
                let registers: [String] = interpreter.cpu.registers.keys.sorted(by: { lhs, rhs in
                    CPUModel.registerSort(lhs: lhs, rhs: rhs)
                } )
                List(registers[..<16], id: \.self, selection: $selection1) { name in
                    RegisterRowView(name: name)
                        .tag(name)
                        .environmentObject(interpreter)
                }
                
                List(registers[16...], id: \.self, selection: $selection2) { name in
                    RegisterRowView(name: name)
                        .tag(name)
                        .environmentObject(interpreter)
                }
            }
        }
    }
}

//struct RegisterView_Previews: PreviewProvider {
//    static var previews: some View {
//        RegisterView()
//    }
//}
