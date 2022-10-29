//
//  FlagView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/30/22.
//

import SwiftUI

struct FlagView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(0..<4, id: \.self) { flag in
                    HStack {
                        Text(flag == 0 ? "N" : flag == 1 ? "Z" : flag == 2 ? "C" : "V")
                            .font(.custom("Menlo Regular", size: 12))

                        let value = interpreter.cpu.flags[flag]

                        Text(value ? "1" : "0")
                            .font(.custom("Menlo Regular", size: 12))
                            .textSelection(.enabled)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 8).fill(interpreter.cpu.touchedFlags ? Color.blue : Color.black.opacity(0.2)))
        }
    }
}

//struct FlagView_Previews: PreviewProvider {
//    static var previews: some View {
//        FlagView()
//    }
//}
